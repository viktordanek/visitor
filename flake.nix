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
                                                                                ''
                                                                                    ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                    ${ pkgs.coreutils }/bin/echo ${ builtins.toJSON expected } > $out/expected.json &&
                                                                                    ${ pkgs.yq }/bin/yq --yaml-output "." $out/expected.json > $out/expected.yaml &&
                                                                                    ${ pkgs.coreutils }/bin/echo ${ builtins.toJSON observed } > $out/observed.json &&
                                                                                    ${ pkgs.yq }/bin/yq --yaml-output "." $out/observed.json > $out/observed.yaml &&
                                                                                    ${ pkgs.coreutils }/bin/echo CHECK:  ${ name } >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/echo EXPECTED: >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/cat $out/expected.yaml >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/echo >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/echo OBSERVED: >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/cat $out/observed.yaml >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/echo >&2 &&
                                                                                    ${ pkgs.coreutils }/bin/echo DIFFERENCE >&2 &&

                                                                                    # Find first difference using cmp
                                                                                    DIFF_INFO=$(${ pkgs.diffutils }/bin/cmp --verbose $out/expected.yaml $out/observed.yaml || true) &&

                                                                                    if [ -z "${ builtins.concatStringsSep "" [ "$" "{" "DIFF_INFO" "}" ] }" ]
                                                                                    then
                                                                                        exit 0
                                                                                    else
                                                                                        # Extract byte position of the difference
                                                                                        BYTE_POS=$( echo ${ builtins.concatStringsSep "" [ "$" "{" "DIFF_INFO" "}" ] } | ${ pkgs.gawk }/bin/awk '{print $1}' )

                                                                                        # Handle EOF message by ensuring the byte position is captured correctly
                                                                                        if [[ "${ builtins.concatStringsSep "" [ "$" "{" "DIFF_INFO" "}" ] }" == *"EOF"* ]]; then
                                                                                            BYTE_POS=$((BYTE_POS - 1))  # Adjust byte position to handle EOF case
                                                                                        fi

                                                                                        # Print up to but not including the differing character
                                                                                        ${ pkgs.coreutils }/bin/echo "FIRST DIFFERENCE AT BYTE: ${ builtins.concatStringsSep "" [ "$" "{" "BYTE_POS" "}" ] }" >&2
                                                                                        ${ pkgs.coreutils }/bin/echo "EXPECTED (AND OBSERVED) UP TO BUT NOT INCLUDING THE FIRST DIFFERENCE:" >&2
                                                                                        ${ pkgs.coreutils }/bin/head --bytes $((BYTE_POS)) $out/expected.yaml >&2
                                                                                        exit 64
                                                                                    fi


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
                                                                    string =
                                                                        path : value :
                                                                            [
                                                                                "${ pkgs.coreutils }/bin/echo ${ value } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "ROOT" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                            ] ;
                                                                }
                                                                {
                                                                    set =
                                                                        path : set :
                                                                            builtins.concatLists
                                                                                [
                                                                                    [
                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "ROOT" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                    ]
                                                                                    ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                ] ;
                                                                }
                                                                {
                                                                    a91379ffc4880060c62443f8c0e41917a1a0bcdbe76eb24775437fe43318cbec47a04971716e1dbeed255688869732b1d2505cf91aeb9c870e3b6e5eb8313b10 =
                                                                        {
                                                                            f20dd5a056deb7ed89ac758d516628f84bb8bc0c13b261da5a459f9ecffd94b07de91af2e5aff0d3a4559cb7fd13dd216c72caf52b7f8f2b1b3973895073d0ca =
                                                                                {
                                                                                    string = "e0c8f7913af793255957e4ae8c7e4c10b75466e4fa0949bdd837431c3ac16f16ebd2a6682afe0eed701ee3417668aaebea74a4145da31dfa5c6df8eb696b7021" ;
                                                                                } ;
                                                                        } ;
                                                                }
                                                                (
                                                                    candidate :
                                                                        ''
                                                                            ${ builtins.concatStringsSep " &&\n    " candidate }
                                                                        ''
                                                                )
                                                                true
                                                                ''
                                                                    ${ pkgs.coreutils }/bin/mkdir ROOT &&
                                                                        ${ pkgs.coreutils }/bin/mkdir ROOT/"a91379ffc4880060c62443f8c0e41917a1a0bcdbe76eb24775437fe43318cbec47a04971716e1dbeed255688869732b1d2505cf91aeb9c870e3b6e5eb8313b10" &&
                                                                        ${ pkgs.coreutils }/bin/mkdir ROOT/"a91379ffc4880060c62443f8c0e41917a1a0bcdbe76eb24775437fe43318cbec47a04971716e1dbeed255688869732b1d2505cf91aeb9c870e3b6e5eb8313b10"/"f20dd5a056deb7ed89ac758d516628f84bb8bc0c13b261da5a459f9ecffd94b07de91af2e5aff0d3a4559cb7fd13dd216c72caf52b7f8f2b1b3973895073d0ca" &&
                                                                        ${ pkgs.coreutils }/bin/echo e0c8f7913af793255957e4ae8c7e4c10b75466e4fa0949bdd837431c3ac16f16ebd2a6682afe0eed701ee3417668aaebea74a4145da31dfa5c6df8eb696b7021 > ROOT/"a91379ffc4880060c62443f8c0e41917a1a0bcdbe76eb24775437fe43318cbec47a04971716e1dbeed255688869732b1d2505cf91aeb9c870e3b6e5eb8313b10"/"f20dd5a056deb7ed89ac758d516628f84bb8bc0c13b261da5a459f9ecffd94b07de91af2e5aff0d3a4559cb7fd13dd216c72caf52b7f8f2b1b3973895073d0ca"/"string"
                                                                ''
                                                        )
                                                        # ( check "no-visitor" { string = path : value : value ; } { } null ( candidate : candidate ) false false )
                                                        # ( check "set" { string = path : value : value ; } { } { alpha = "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" ; } ( candidate : candidate.alpha ) true "512f3471c79f2cb9f99ec4ebe152158bb114189d2f5882541442fc5d539da43901a29b85d915253ee3d58d636a364804772410af112a6a6c99f54d2a56bfedb2" )
                                                        # ( check "string" { string = path : value : value ; } { } "9a9115b8c7fe5ec423464e181946afaa6639b8f2792afee8f8dd76d07607c476c234918fbdd6f2a254098ec30958bae2414b0a39b72ca69cdbfcbf8c310d830f" ( candidate : candidate ) true "9a9115b8c7fe5ec423464e181946afaa6639b8f2792afee8f8dd76d07607c476c234918fbdd6f2a254098ec30958bae2414b0a39b72ca69cdbfcbf8c310d830f" )
                                                        # ( check "list" { string = path : value : value ; } { } [ "c338cd832d312cc4f76bb1a7f9febf96745a9b19a6e5d7cff378f5f4b79fcb0e98d1e4450fcb1f1a87050c45700654f34f878c0a65f9559ef289f3e10e29b700" ] ( candidate : builtins.elemAt candidate 0 ) true "c338cd832d312cc4f76bb1a7f9febf96745a9b19a6e5d7cff378f5f4b79fcb0e98d1e4450fcb1f1a87050c45700654f34f878c0a65f9559ef289f3e10e29b700" )
                                                    ] ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}