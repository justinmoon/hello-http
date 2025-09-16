{
  description = "Trivial HTTP server for GitOps demo";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  
  outputs = { self, nixpkgs, ... }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
  in {
    packages = forAllSystems (system: 
      let
        pkgs = nixpkgsFor.${system};
        helloHttp = pkgs.writeScriptBin "hello-http" ''
          #!${pkgs.bash}/bin/bash
          exec ${pkgs.python3}/bin/python - "$@" <<'PY'
          from http.server import BaseHTTPRequestHandler, HTTPServer
          import os
          import signal
          import sys
          
          PORT = int(os.environ.get("PORT", "9000"))
          MSG = os.environ.get("HELLO_MSG", "Hello from GitOps v1")
          
          class H(BaseHTTPRequestHandler):
              def log_message(self, format, *args):
                  # Reduce noise in logs
                  if self.path != '/health':
                      super().log_message(format, *args)
                      
              def do_GET(self):
                  if self.path == '/health':
                      self.send_response(200)
                      self.send_header("Content-Type", "text/plain")
                      self.end_headers()
                      self.wfile.write(b"OK")
                  else:
                      body = MSG.encode("utf-8")
                      self.send_response(200)
                      self.send_header("Content-Type", "text/plain; charset=utf-8")
                      self.send_header("Content-Length", str(len(body)))
                      self.end_headers()
                      self.wfile.write(body)
          
          def signal_handler(sig, frame):
              print('\nShutting down gracefully...')
              sys.exit(0)
          
          signal.signal(signal.SIGINT, signal_handler)
          signal.signal(signal.SIGTERM, signal_handler)
          
          print(f"Starting hello-http server on port {PORT}")
          print(f"Message: {MSG}")
          HTTPServer(("0.0.0.0", PORT), H).serve_forever()
          PY
        '';
      in {
        server = helloHttp;
        default = helloHttp;
      }
    );
    
    # For backward compatibility
    defaultPackage = forAllSystems (system: self.packages.${system}.default);
  };
}