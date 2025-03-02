{
    inputs =
        {
            flake-utils.url = "github:numtide/flake-utils" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
        } ;
    outputs =
        { flake-utils , nixpkgs , self } :
            let
                fun =
                    system :
                        let
                            lib =
                                {
                                    bool ? null ,
                                    float ? null ,
                                    int ? null ,
                                    lambda ? null ,
                                    path ? null ,
                                    string , null
                                } @simple :
                                    {
                                        default ? path : value : "The definition at ${ builtins.concatStringsSep " / " ( builtins.map builtins.toJSON path ) } is invalid.  It is of type ${ builtins.typeOf value }.  It is ${ if builtins.type.any ( t : t == builtins.typeOf value ) [ "bool" "float" "int" "path" "string" ] then  builtins.toJSON value else "unstringable." }." ,
                                        list ? list : list ,
                                        set ? set : set
                                    } @complex : default :
                                    let
                                        elem =
                                            path : value :
                                                let
                                                    visitor =
                                                        let
                                                            list-visitor = path : value : list ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) value ) ( builtins.length value ) ) ;
                                                            simple-visitors =
                                                                let
                                                                    mapper =
                                                                        name : value :
                                                                            {
                                                                                name = name ;
                                                                                value =
                                                                                    if builtins.typeOf value == "lambda" then value
                                                                                    else if builtins.typeOf value == "null" then default
                                                                                    else builtins.throw "The ${ name } visitor is not lambda, null but ${ builtins.typeOf value }." ;
                                                                            } ;
                                                                    in builtins.mapAttrs mapper simple ;
                                                            set = path : value : set ( builtins.mapAttrs ( name : value : elem ( builtins.concatList [ path [ name ] ] ) value ) value ) ;
                                                            in builtins.listToAttrs ( builtins.concatLists [ simple-visitors [ list-visitor set-visitor ] ] ) ;
                                                    in visitor path value ;
                                        in elem [ ] ;
                            in
                                {
                                    checks.lib =
                                        pkgs.stdenv.mkDerivation
                                            {
                                                installPhase =
                                                    let
                                                        candidate = lib { } { } ;
                                                        expected = { success = false ; value = false ; }
                                                        observed = builtins.tryEval ( candidate { } ) ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out
                                                            '' ;
                                                name = "visitor-checks-lib" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}