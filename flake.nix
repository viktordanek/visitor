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
                                                                filtered-visitors =
                                                                    let
                                                                        all-visitors =
                                                                            let
                                                                                list-visitor =
                                                                                    if builtins.typeOf list == "lambda" then path : value : list ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) value ) ( builtins.length value ) )
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
                                                                                                in builtins.mapAttrs mapper ( builtins.trace "1d32d2aa-47c0-4590-b72e-47c86fefe204:  ${ builtins.toString ( builtins.length ( builtins.attrNames ( identity simple ) ) ) } ${ builtins.concatStringsSep "," ( builtins.attrNames ( identity simple ) ) }" identity ( simple ) ) ;
                                                                                        in builtins.attrValues simple-visitors ;
                                                                                set-visitor =
                                                                                    if builtins.typeOf set == "lambda" then path : value : set ( builtins.mapAttrs ( name : value : elem ( builtins.concatList [ path [ name ] ] ) value ) value )
                                                                                    else builtins.throw "The complex set aggregator is not lambda but ${ builtins.typeOf set }." ;
                                                                                in builtins.concatLists [ ( builtins.trace "206e7104-0358-4cdd-b85a-1698eb30fc48: ${ builtins.toString ( builtins.length simple-visitors ) }" simple-visitors ) [ list-visitor set-visitor ] ] ;
                                                                        predicate = v : builtins.typeOf value == v ;
                                                                        #
                                                                        in builtins.filter predicate ( builtins.trace "431eec35-9011-4bb6-abd5-ef0bccc32433:  ${ ( builtins.toString ( builtins.length all-visitors ) ) }" all-visitors ) ;
                                                                in builtins.head filtered-visitors ;
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
                                                                            observed = builtins.tryEval ( lib simple complex visited ) ;
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