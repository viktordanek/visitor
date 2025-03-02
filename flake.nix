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
                                                                visitor =
                                                                    let
                                                                        filtered-visitors =
                                                                            let
                                                                                all-visitors =
                                                                                    let
                                                                                        list-visitor =
                                                                                            if builtins.typeOf list == "lambda" then
                                                                                                {
                                                                                                    name = "list" ;
                                                                                                    value = path : value : list ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) value ) ( builtins.length value ) ) ;
                                                                                                }
                                                                                            else builtins.throw "The complex list aggregator is not lambda but ${ builtins.typeOf list }." ;
                                                                                        simple-visitors =
                                                                                            let
                                                                                                simple-visitors =
                                                                                                    let
                                                                                                        identity =
                                                                                                            {
                                                                                                                bool ? null ,
                                                                                                                float ? null ,
                                                                                                                int ? null ,
                                                                                                                lambda ? null ,
                                                                                                                null ? null ,
                                                                                                                path ? null ,
                                                                                                                string ? null
                                                                                                            } :
                                                                                                                {
                                                                                                                    bool = bool ;
                                                                                                                    float = float ;
                                                                                                                    int = int ;
                                                                                                                    lambda = lambda ;
                                                                                                                    null = null ;
                                                                                                                    string = string ;
                                                                                                                } ;
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
                                                                                                        in builtins.mapAttrs mapper ( identity ( simple ) ) ;
                                                                                                in builtins.attrValues simple-visitors ;
                                                                                        set-visitor =
                                                                                            if builtins.typeOf set == "lambda" then
                                                                                                {
                                                                                                    name = "set" ;
                                                                                                    value = path : value : set ( builtins.mapAttrs ( name : value : elem ( builtins.concatLists [ path [ name ] ] ) value ) value ) ;
                                                                                                }
                                                                                            else builtins.throw "The complex set aggregator is not lambda but ${ builtins.typeOf set }." ;
                                                                                        in builtins.concatLists [ simple-visitors [ list-visitor set-visitor ] ] ;
                                                                                predicate = visitor : visitor.name == builtins.typeOf value ;
                                                                                in builtins.filter predicate all-visitors ;
                                                                        in builtins.head filtered-visitors ;
                                                                in visitor.value ;
                                                        in visitor path value ;
                                            in elem [ ] value ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            in
                                {
                                    checks =
                                        let
                                            check =
                                                name : simple : complex : visited : observation : expected-success : expected-value :
                                                    {
                                                        name = name ;
                                                        value =
                                                            pkgs.stdenv.mkDerivation
                                                                {
                                                                    installPhase =
                                                                        let
                                                                            expected =
                                                                                {
                                                                                    success = if builtins.typeOf expected-success == "bool" then expected-success else builtins.throw "The expected success of ${ name } should be a boolean."  ;
                                                                                    value = if builtins.any ( t : t == builtins.typeOf expected-value ) [ "bool" "float" "int" "null" "string" "path" ] then expected-value else builtins.throw "The expected value of ${ name } is not stringable but ${ builtins.typeOf expected-value }." ;
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
                                                        ( check "set" { string = path : value : value ; } { } { alpha = "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" ; } ( candidate : candidate.alpha ) true "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" )
                                                        # ( check "list" { string = path : value : value ; } [ ] { alpha = "70c5852246c99b7c36cac790cf1627f3d89e6c6d55214c734e500292ab9007c013b0a2f04382f92791568f328f11fe4bb7bb99718be2b86ca3608148b3da9e06" ; } ( candidate : builtins.elemAt candidate 0 ) true "70c5852246c99b7c36cac790cf1627f3d89e6c6d55214c734e500292ab9007c013b0a2f04382f92791568f328f11fe4bb7bb99718be2b86ca3608148b3da9e06" )
                                                    ] ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}