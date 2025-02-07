#import "@preview/slydst:0.1.0": *

#show: slides.with(
  title: "Miniscript",
  subtitle: "An introduction to BIP 379",
  date: none,
  authors: ("qlrd", ),
  layout: "medium",
  ratio: 4/3,
  title-color: orange,
)


== Miniscript

#align(horizon + center)[
    #definition(title: "BIP 379")[
        (...) a language for writing (a subset of) *Bitcoin Scripts* in a structured way, enabling analysis, composition, generic signing and more. @bip379 
    ]
]

= Back to the basics

== Bitcoin script

#align(horizon + center)[
    #definition(title: "")[
        (...) an unusual stack-based language with many edge cases designed for implementing spending conditions consisting of various combinations of signatures, hash locks, and time locks." @bip379
    ]
]

== Bitcoin script

Common transactions from @wiki_script and @mastering_bitcoin

#align(horizon + center)[
    #table(
        columns: (auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Comment*], [*Unlock*],[*Lock*]
        ),
        `P2PK`, `<sig> <pk>`, `OP_CHECKSIG`,
        `P2PKH`, `<sig> <pk>`, `OP_DUP OP_HASH160 <pkh> OP_EQUALVERIFY OP_CHECKSIG`,
        `Multisig 2-of-3`, `OP_0 <sigA> <sigB>`, `2 <pkA> <pkB> <pkC> 3 OP_CHECKMULTISIG`,
    )
]

== Bitcoin script

Freezing funds until a time in the future from @wiki_script

#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Unlock*],[*Lock*]
        ),
        `<sig> <pk>`, `<expiry time> OP_CHECKLOCKTIMEVERIFY OP_DROP OP_DUP OP_HASH160 <pkh> OP_EQUALVERIFY OP_CHECKSIG`
    )
]

== Bitcoin script

Timelock variable multisignature from  @mastering_bitcoin: Mohammed/Saeed/Zaira 2-of-3 multisig. After 30 days 1-of-3 plus a lawyers's singlesig. After 90 days the lawyer's singlesig.

#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Unlock*],[*Lock*]
        ),
        `OP_0 <sigA> <sigB> OP_TRUE OP_TRUE`, `OP_IF OP_IF 2 OP_ELSE <30 days> OP_CHECKSEQUENCEVERIFY OP_DROP <sigD> OP_CHECKSIGVERIFY 1 OP_ENDIF <sigA> <sigB> <sigC> 3 OP_CHECKMULTISIG OP_ELSE <90 days> OP_CHECKSEQUENCEVERIFY OP_DROP <sigD> OP_CHECKSIG OP_ENDIF`
    )
]


= The issue

= 

@bip379 states that, given a combination of spending conditions, it is still highly nontrivial to:

- find the most economical script to implement it;

- implement a composition of their spending conditions;

- find out what spending conditions it permits.

...

= The motivation

=

*Miniscript* has a structure that allows composition: a representation for *scripts* that makes these type of operations possible.

== Miniscript @sipa_miniscript

#align(horizon + center)[
    Policy for a singlesig
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `pk(<key_1>)`, `<key_1> OP_CHECKSIG`
    )
]

== Miniscript @sipa_miniscript

#align(horizon)[
    Miniscript for `One of two keys (equally likely)`
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        [
            `or_b(` \
            `  pk(key_1),` \
            `  s:pk(key_2)` \
            `)`
        ],
        `<key_1> OP_CHECKSIG OP_SWAP <key_2> OP_CHECKSIG OP_BOOLOR`
    )
]

== Miniscript @sipa_miniscript

#align(horizon)[
    Miniscript for `One of two keys (one likely, one unlikely)`
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        [
            `or_d(` \
            `  pk(key_1),` \
            `  pkh(key_2)` \
            `)`
        ],
        `<key_1> OP_CHECKSIG OP_IFDUP OP_NOTIF OP_DUP OP_HASH160 <HASH160(key_2)> OP_EQUALVERIFY OP_CHECKSIG OP_ENDIF`
    )
]

== Miniscript @sipa_miniscript

#align(horizon)[
    Miniscript for `3-of-3 that turns into a 2-of-3 after 90 days`
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        [
            `thresh(` \
            `  3,` \
            `  pk(key_1),` \
            `  s:pk(key_2),` \
            `  s:pk(key_3),` \
            `  sln:older(12960)` \
            `)`
        ],
        `<key_1> OP_CHECKSIG OP_SWAP <key_2> OP_CHECKSIG OP_ADD OP_SWAP <key_3> OP_CHECKSIG OP_ADD OP_SWAP OP_IF 0 OP_ELSE <a032> OP_CHECKSEQUENCEVERIFY OP_0NOTEQUAL OP_ENDIF OP_ADD 3 OP_EQUAL`
    )
]


== Miniscript @sipa_miniscript

#align(horizon)[
    Miniscript for `Lightning: BOLT #3 to_local`.
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        [
            `andor(` \
            `  pk(key_local),` \
            `  older(1008),` \
            `  pk(key_revocation)` \
            `)`
        ],
        `<key_local> OP_CHECKSIG OP_NOTIF <key_revocation> OP_CHECKSIG OP_ELSE <f003> OP_CHECKSEQUENCEVERIFY OP_ENDIF`
    )
]

= Specification @bip379

== Specification

#align(horizon + center)[
    Miniscript analyzes scripts to determine properties.
]

== Specification

#align(horizon)[
    *Not expected* to be used with:

    - BIP 16 (p2sh);

    *Expected* to  be used within:

    - BIP 382: `wsh` descriptor;
    - BIP 386: `tr` descriptor.

    And together with:

    - BIP 380: Key expressions:

    `[<fingerprint>/<purpose>/<cointype>/<index>]`
]

== Specification
#align(horizon)[
    From a user's perspective, Miniscript is not a separate language, but rather a significant expansion of the descriptor language. @bip379
]

== Specification
#align(horizon)[
    Liana's simple inheritance wallet @jean_gist_liana_wsh.
    
    `wsh(` \
    `  or_d(` \
    `    pk([07fd816d/48'/1'/0'/2']tpub...wd5/<0;1>/*),` \
    `    and_v(` \
    `      v:pkh([da855a1f/48'/1'/0'/2']tpub...Hg5/<0;1>/*),` \
    `      older(36)` \
    `    )` \
    `  )` \
    `)#lz4jfr7g`
    
]

== Specification
#align(horizon)[
    Liana's simple inheritance wallet @jean_gist_liana_tr. First key expression is a `NUMS` ("nothing-up-my-sleeves") point @jaonoctus_nums.
       
    `tr(` \
    `  [07fd816d/48'/1'/0'/2']tpub...mwd5/<0;1>/*,` \
    `  and_v(` \
    `    v:pk([da855a1f/48'/1'/0'/2']tpub...Hg5/<0;1>/*),` \
    `    older(36)` \
    `  )` \
    `)#506utvsp`
]

== Specification
#align(horizon)[
    Liana's decaying multisig wallet @jean_gist_liana_mwsh.
    
    `wsh(` \
    `  or_d(` \
    `    multi(2,` \
    `      [07fd816d/48'/1'/0'/2']tpub...wd5/<0;1>/*,` \
    `      [da855a1f/48'/1'/0'/2']tpub...Hg5/<0;1>/*` \
    `    ),` \
    `    and_v(` \
    `      v:thresh(2,` \
    `        pkh([07fd816d/48'/1'/0'/2']tpub...mwd5/<2;3>/*),` \
    `        a:pkh([da855a1f/48'/1'/0'/2']tpub...Hg5/<2;3>/*),` \
    `        a:pkh([cdef7cd9/48'/1'/0'/2']tpub...Ak2/<0;1>/*)` \
    `      ),` \
    `      older(36)` \
    `    )` \
    `  )`
    `)#wa74c6se`
]

== Specification
#align(horizon)[
    Liana's expanding multisig TR @jean_gist_liana_mtr. First key expression is a `NUMS` ("nothing-up-my-sleeves") point @jaonoctus_nums.

    `tr(tpub...pMN/<0;1>/*, {` \
    `  and_v(` \
    `    v:multi_a(2,` \
    `      [07fd816d/48'/1'/0'/2']tpub...mwd5/<2;3>/*,` \
    `      [da855a1f/48'/1'/0'/2']tpub...DHg5/<2;3>/*,` \
    `      [cdef7cd9/48'/1'/0'/2']tpub...SAk2/<0;1>/*` \
    `    ),` \
    `    older(36)` \
    `  ),` \
    `  multi_a(2,` \
    `    [07fd816d/48'/1'/0'/2']tpub...mwd5/<0;1>/*,` \
    `    [da855a1f/48'/1'/0'/2']tpub...DHg5/<0;1>/*` \
    `  )` \
    `})#tvh3u2lu`
]

== Specification
#align(horizon)[
    - *Translation* table;
    - *type* system;
    - condition *satisfaction* system;
]

== Translation 
#align(horizon + center)[
    #definition(title: "")[
        *Miniscript* consists of a set of *script* fragments which are designed to be safely and correctly composable (...) targeted by spending policy compilers)
    ]
]

== Translation 
Normal fragments

#align(horizon + center)[
    `fragment(arg1)`
]

#h(3cm)

#align(horizon + center)[
    `fragment(arg1,arg2,...)`
]

== Translation 
Wrappers: fragments that do not change the semantics of their subexpressions, separated by a colon and each one is applied to the next fragment

#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Fragments*], [*Interpretation*]
        ),
        `x:fragment(arg)`, `x -> fragment`,
        `xy:fragment(arg)`, `x -> y -> fragment`,
        `xyz:fragment(arg)`, `x -> y -> z -> fragment`
    )
]
== Translation 

Simple validation semantics
#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `0`, `0`,
        `1`, `1`,
    )
]

== Translation 

Check key semantics
#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `0`, `0`,
        `1`, `1`,
        `pk_k(key)`, `<key>`,
        `pk_h(key)`, `DUP HASH160 <HASH160(key)> EQUALVERIFY`,
    )
]

== Translation 

Wrapped check key semantics
#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `pk(key) = c:pk_k(key)`, `<key> CHECKSIG`,
        `pkh(key) = c:pk_h(key)`, `DUP HASH160 <HASH160(key)> EQUALVERIFY CHECKSIG`,
    )
]

== Translation 

Time semantics
#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `older(n)`, `<n> CHECKSEQUENCEVERIFY`,
        `after(n)`, `<n> CHECKLOCKTIMEVERIFY`,
    )
]

== Translation 

Hash semantics
#align(horizon + center)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `sha256(h)`, `SIZE <20> EQUALVERIFY SHA256 <h> EQUAL`,
        `hash256(h)`, `SIZE <20> EQUALVERIFY HASH256 <h> EQUAL`,
        `ripemd160(h)`, `SIZE <20> EQUALVERIFY RIPEMD160 <h> EQUAL`, 
        `hash160(h)`, `SIZE <20> EQUALVERIFY HASH160 <h> EQUAL`,
    )
]

== Translation 

Boolean semantics 
#align(horizon)[
    #table(
        columns: (auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Script*]
        ),
        `andor(X,Y,Z)`, `[X] NOTIF [Z] ELSE [Y] ENDIF`,
        `and_v(X,Y)`, `[X] [Y]`,
        `and_b(X,Y)`, `[X] [Y] BOOLAND`,
        `and_n(X,Y) = andor(X,Y,0)`, `[X] NOTIF 0 ELSE [Y] ENDIF`,
        `or_b(X,Z)`, `[X] [Z] BOOLOR`,
        `or_c(X,Z)`, `[X] NOTIF [Z] ENDIF`,
        `or_d(X,Z)`, `[X] IFDUP NOTIF [Z] ENDIF`,
        `or_i(X,Z)`, `IF [X] ELSE [Z] ENDIF`,
    )
]

== Translation 

Multisig semantics
#align(horizon)[
    #table(
        columns: (auto, auto, auto),
        inset: 7pt,
        align: horizon,
        table.header(
            [*Only*], [*Miniscript*], [*Script*]
        ),
        ``, `thresh(k,X_1,...,X_n)`, `[X_1] [X_2] ADD ... [X_n] ADD ... <k> EQUAL`,
        `p2wsh`, `multi(m,key_1,...,key_n)`, `<k> <key_1> ... <key_n> <n> CHECKMULTISIG`,
        `tapscript`, `multi_a(k,key_1,...,key_n)`, `<key_1> CHECKSIG <key_2> CHECKSIGADD ... <key_n> CHECKSIGADD <k> NUMEQUAL`
    )
]

== Translation 

Wrappers semantics
#table(
    columns: (auto, auto),
    inset: 10pt,
    align: horizon,
    table.header(
        [*Miniscript*], [*Script*]
    ),
    `a:X`, `TOALTSTACK [X] FROMALTSTACK`,
    `s:X`, `SWAP [X]`,
    `c:X`, `[X] CHECKSIG`,
    `t:X = and_v(X,1)`, `[X] 1`,
    `d:X`, `DUP IF [X] ENDIF`,
    `v:X`, `[X] VERIFY (or VERIFY version of last opcode in [X])`,
    `j:X`, `SIZE 0NOTEQUAL IF [X] ENDIF`,
    `n:X`, `[X] 0NOTEQUAL`,
    `l:X = or_i(0,X)`, `IF 0 ELSE [X] ENDIF`,
    `u:X = or_i(X,0)`, `IF [X] ELSE 0 ENDIF`,
)


= Type system

== Type system

#align(horizon + center)[
    Not every Miniscript expression can be composed with every other.
]

== Type system

#align(horizon)[
    @bip379 defined a correctness type system for Miniscript to model properties and its requirements:

    - Correctness;
    - timelock mixing;
    - malleability.
]

== Type system (correctness)

#align(horizon)[

    - Basic types
        - `B`: Base;
        - `V`: Verify;
        - `K`: Key;
        - `W`: Wrapped;

    - Type modifiers
        - `z`: zero-arg;
        - `o`: one-arg;
        - `n`: non-zero;
        - `d`: dissatisfiable;
        - `u`: unit.
]


== Type system (correctness)

#show link: underline

Keys semantics.
#align(horizon)[
    #table(
        columns: (auto, auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Requires*], [*Type*], [*Properties*]
        ),
        `pk_k(key)`, ``, `K`, `o; n; d; u`,
        `pk_h(key)`, ``, `K`, `n; d; u`
    )
]

== Type system (correctness)

#show link: underline

Time semantics.
#align(horizon)[
    #table(
        columns: (auto, auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Requires*], [*Type*], [*Properties*]
        ),
        `older(n), after(n)`, $1 ≤ n < 2^31$, `B`, `z`
    )
]

== Type system (correctness)

#show link: underline

Hash semantics.
#align(horizon)[
    #table(
        columns: (auto, auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Requires*], [*Type*], [*Properties*]
        ),
        `sha256(h)`, ``, `B`,  `o; n; d; u`,
        `ripemd160(h)`, ``, `B`,  `o; n; d; u`,
        `hash256(h)`, ``, `B`,  `o; n; d; u`,
        `hash160(h)`, ``, `B`,  `o; n; d; u`,
    )
]

== Type system (correctness)

#show link: underline

Boolean semantics.
#align(horizon)[
    #table(
        columns: (auto, auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Requires*], [*Type*], [*Properties*]
        ),
        `andor(X,Y,Z)`, `X is Bdu; Y and Z are both B, K, or V`, `same as Y/Z`, [
            `z=zXzYzZ;` \
            `o=zXoYoZ or oXzYzZ;` \
            `u=uYuZ;` \
            `d=dZ`
        ],
        `and_v(X,Y)`, `X is V; Y is B, K, or V`, `same as Y`, [
            `z=zXzY;` \
            `o=zXoY or zYoX;` \
            `n=nX or zXnY;` \
            `u=uY`
        ]
    )
]

== Type system (correctness)

#show link: underline

Multisig semantics.
#align(horizon)[
    #table(
        columns: (auto, auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Requires*], [*Type*], [*Properties*]
        ),
        [
            `thresh(` \
            `  k,` \
            `  X1,` \
            `  ...,` \
            `  Xn` \
            `)`
        ], `1 ≤ k ≤ n; X1 is Bdu; others are Wdu`, `B`, [
            `z=all are z;` \
            `o=all are z except one is o;` \
            `d; ` \
            `u`
        ]
    )
]

== Type system (timelock mixing)

#align(horizon)[
    Four timelock types:

    - absolute time based;
    - absolute height based;
    - relative time based;
    - relative height based;
]


== Type system (timelock mixing)
#align(horizon + center)[
    must not be mixed in an incompatible way:
]

== Type system (timelock mixing)
#align(horizon)[
    It is illegal height based *and* time based timelocks to appear together in:
    
    - `and` fragment combinations; and
    - `thresh` frament combinations where `k >= 2`,

    For all other combinators, it is legal to mix timelock types.
    
]

== Type system (malleability)

#align(horizon)[
    Ability for a third party to modify an existing satisfaction into another valid satisfaction.
]

== Type system (malleability)

#align(horizon)[
    *Third party*: someone who does not hold a participating private key
]

== Type system (malleability)
#align(horizon)[
    To analyze the malleability guarantees of a script we define three additional type properties:

    - `s`: signed;
    - `f`: forced;
    - `e`: expressive.
]

= Satisfaction

== Satisfaction
#align(horizon)[
    The Miniscript-compliant data (e.g., signatures, preimages) required to authorize a Bitcoin script's execution by meeting its spending conditions.
]


== Satisfaction
#show link: underline

Examples for key semantics. See more at #link("https://github.com/bitcoin/bips/blob/master/bip-0379.md#satisfaction")[BIP 379's satisfaction section]

#align(horizon)[
    #table(
        columns: (auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Dissatisfaction*], [*Satisfaction*]
        ),
        `pk_k(key)`, `0`, `<sig>`,
        `pk_h(key)`, `0`, `<sig> <pubKey>`,
    )
]

== Satisfaction
#show link: underline

Examples for key semantics. See more at #link("https://github.com/bitcoin/bips/blob/master/bip-0379.md#satisfaction")[BIP 379's satisfaction section]

#align(horizon)[
    #table(
        columns: (auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Dissatisfaction*], [*Satisfaction*]
        ),
        `sha256(h)`, `any 32-byte vector except the preimage`, `preimage`,
        `hash160(h)`, `any 32-byte vector except the preimage`, `preimage`
    )
]

== Satisfaction
#show link: underline

Examples for multisig semantics. See more at #link("https://github.com/bitcoin/bips/blob/master/bip-0379.md#satisfaction")[BIP 379's satisfaction section]

#align(horizon)[
    #table(
        columns: (auto, auto, auto),
        inset: 10pt,
        align: horizon,
        table.header(
            [*Miniscript*], [*Dissatisfaction*], [*Satisfaction*]
        ),
        [
            `multi(` \
            `  k` \
            `  key_1,` \
            `  ...,` \
            `  key_n` \
            `)`
        ], `0 0 ... 0`, `0 <sig1> <sig2> ... <sigN>`
    )
]

= Implementations

- #link("https://github.com/sipa/miniscript")[Peter Wuile's reference implementation];

- C++:
    - #link("https://github.com/bitcoin/bitcoin/blob/master/src/script/miniscript.cpp")[Bitcoin-core];
    
- Rust:
    - #link("https://github.com/rust-bitcoin/rust-miniscript")[rust-miniscript];
    - #link("https://github.com/wizardsardine/liana")[Liana];

- Go:
    - #link("https://bitbox.swiss/blog/understanding-bitcoin-miniscript-part-3")[Tutorial: Understanding Bitcoin Miniscript - Part III];

- Python:
    - #link("https://github.com/diybitcoinhardware/embit/blob/master/src/embit/descriptor/miniscript.py")[Embit's miniscript.py]
    - #link("https://github.com/odudex/krux/tree/p2wsh_miniscript")[Krux (branch p2wsh_miniscript)];
    - #link("https://github.com/odudex/krux/tree/tr_miniscript")[Krux (branch tr_miniscript)];

= Thanks!


= Bibliography

#bibliography("main.bib")
