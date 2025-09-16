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
          
          # CHANGE THIS TO TEST DEPLOYMENTS
          MESSAGE = "v1"
          
          class H(BaseHTTPRequestHandler):
              def log_message(self, format, *args):
                  pass  # Silence logs
                      
              def do_GET(self):
                  body = MESSAGE.encode("utf-8")
                  self.send_response(200)
                  self.send_header("Content-Type", "text/plain")
                  self.send_header("Content-Length", str(len(body)))
                  self.end_headers()
                  self.wfile.write(body)
          
          print(f"Starting hello-http server, message: {MESSAGE}")
          HTTPServer(("0.0.0.0", 9000), H).serve_forever()
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