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
                                    null ? null ,
                                    path ? null ,
                                    string ? null
                                } @simple :
                                    {
                                        default ? path : value : "The definition at ${ builtins.concatStringsSep " / " ( builtins.map builtins.toJSON path ) } is invalid.  It is of type ${ builtins.typeOf value }.  It is ${ if builtins.type.any ( t : t == builtins.typeOf value ) [ "bool" "float" "int" "path" "string" ] then  builtins.toJSON value else "unstringable." }." ,
                                        list ? list : list ,
                                        set ? set : set
                                    } : value :
                                        let
                                            elem =
                                                path : value :
                                                    let
                                                        visitor =
                                                            let
                                                                list-visitor =
                                                                    if builtins.typeOf list == "lambda" then path : value : list ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) value ) ( builtins.length value ) )
                                                                    else builtins.throw "The complex list aggregator is not lambda but ${ builtins.typeOf list }." ;
                                                                simple-visitors =
                                                                    let
                                                                        mapper =
                                                                            name : value :
                                                                                {
                                                                                    name = name ;
                                                                                    value =
                                                                                        if builtins.typeOf value == "lambda" then value
                                                                                        else if builtins.typeOf value == "null" && builtins.typeOf default == "lambda" then default
                                                                                        else if builtins.typeOf value == "null" then builtins.throw "The simple ${ name } visitor is not lambda, null (and the default simple visitor is not lambda) but ${ builtins.typeOf value }."
                                                                                        else builtins.throw "The simple ${ name } visitor is not lambda, null but ${ builtins.typeOf value }." ;
                                                                                } ;
                                                                        in builtins.mapAttrs mapper simple ;
                                                                set-visitor =
                                                                    if builtins.typeOf set == "lambda" then path : value : set ( builtins.mapAttrs ( name : value : elem ( builtins.concatList [ path [ name ] ] ) value ) value )
                                                                    else builtins.throw "The complex set aggregator is not lambda but ${ builtins.typeOf set }." ;
                                                                in builtins.listToAttrs ( builtins.concatLists [ simple-visitors [ list-visitor set-visitor ] ] ) ;
                                                        in visitor path value ;
                                            in elem [ ] value ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            in
                                {
                                    checks =
                                        let
                                            check =
                                                name : simple : complex : visited : observation : success : value :
                                                    {
                                                        name = name ;
                                                        value =
                                                            pkgs.stdenv.mkDerivation
                                                                {
                                                                    installPhase =
                                                                        let
                                                                            expected =
                                                                                {
                                                                                    success = success ;
                                                                                    value = value ;
                                                                                } ;
                                                                            observed = builtins.tryEval ( observation ( lib simple complex visited ) ) ;
                                                                            in
                                                                                if expected == observed then
                                                                                    ''
                                                                                        ${ pkgs.coreutils }/bin/touch $out
                                                                                    ''
                                                                                else
                                                                                    ''
                                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                                            ${ pkgs.coreutils }/bin/echo CHECK:  ${ name } >&2 &&
                                                                                            ${ pkgs.coreutils }/bin/echo EXPECTED did not equal OBSERVED >&2 &&
                                                                                            ${ pkgs.coreutils }/bin/echo EXPECTED:  ${ builtins.toJSON expected } >&2 &&
                                                                                            ${ pkgs.coreutils }/bin/echo OBSERVED:  ${ builtins.toJSON observed } >&2 &&
                                                                                            exit 64
                                                                                    '' ;
                                                                    name = "visitor-check-${ name }" ;
                                                                    src = ./. ;
                                                                } ;
                                                    } ;
                                            in
                                                builtins.listToAttrs
                                                    [
                                                        ( check "easy" { string = value : value ; } { } { alpha = "a" ; } ( candidate : candidate.alpha ) false false )
                                                    ] ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}