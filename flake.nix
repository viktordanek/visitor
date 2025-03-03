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
                                        default ? path : value : builtins.throw "The definition at ${ builtins.concatStringsSep " / " ( builtins.concatLists [ [ "*ROOT*" ] ( builtins.map builtins.toJSON path ) ] ) } is invalid.  It is of type ${ builtins.typeOf value }.  It is ${ if builtins.any ( t : t == builtins.typeOf value ) [ "bool" "float" "int" "null" "path" "string" ] then  builtins.toJSON value else "unstringable." }." ,
                                        list ? path : list : list ,
                                        set ? path : set : set
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
                                                                                                    value = path : value : list path ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) ( builtins.elemAt value index ) ) ( builtins.length value ) ) ;
                                                                                                }
                                                                                            else builtins.throw "The complex list aggregator is not lambda but ${ builtins.typeOf list }." ;
                                                                                        set-visitor =
                                                                                            if builtins.typeOf set == "lambda" then
                                                                                                {
                                                                                                    name = "set" ;
                                                                                                    value = path : value : set path ( builtins.mapAttrs ( name : value : elem ( builtins.concatLists [ path [ name ] ] ) value ) value ) ;
                                                                                                }
                                                                                            else builtins.throw "The complex set aggregator is not lambda but ${ builtins.typeOf set }." ;
                                                                                        simple-visitors =
                                                                                            let
                                                                                                simple-visitors =
                                                                                                    let
                                                                                                        identity =
                                                                                                            {
                                                                                                                bool ? builtins.null ,
                                                                                                                float ? builtins.null ,
                                                                                                                int ? builtins.null ,
                                                                                                                lambda ? builtins.null ,
                                                                                                                null ? builtins.null ,
                                                                                                                path ? builtins.null ,
                                                                                                                string ? builtins.null
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
                                                                            observed = builtins.tryEval ( observation ( lib simple complex  visited ) ) ;
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
                                                        (
                                                            check
                                                                "complex-set"
                                                                {
                                                                    string = path : value : value ;
                                                                }
                                                                { }
                                                                {
                                                                    alpha = "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" ;
                                                                }
                                                                ( candidate : candidate.alpha )
                                                                true
                                                                "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2"
                                                        )
                                                        ( check "no-visitor" { string = path : value : value ; } { } null ( candidate : candidate ) false false )
                                                        ( check "set" { string = path : value : value ; } { } { alpha = "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" ; } ( candidate : candidate.alpha ) true "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" )
                                                        ( check "string" { string = path : value : value ; } { } "9a9115b8c7fe5ec423464e181946afaa6639b8f2792afee8f8dd76d07607c476c234918fbdd6f2a254098ec30958bae2414b0a39b72ca69cdbfcbf8c310d830f" ( candidate : candidate ) true "9a9115b8c7fe5ec423464e181946afaa6639b8f2792afee8f8dd76d07607c476c234918fbdd6f2a254098ec30958bae2414b0a39b72ca69cdbfcbf8c310d830f" )
                                                        ( check "list" { string = path : value : value ; } { } [ "c338cd832d312cc4f76bb1a7f9febf96745a9b19a6e5d7cff378f5f4b79fcb0e98d1e4450fcb1f1a87050c45700654f34f878c0a65f9559ef289f3e10e29b700" ] ( candidate : builtins.elemAt candidate 0 ) true "c338cd832d312cc4f76bb1a7f9febf96745a9b19a6e5d7cff378f5f4b79fcb0e98d1e4450fcb1f1a87050c45700654f34f878c0a65f9559ef289f3e10e29b700" )
                                                    ] ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}