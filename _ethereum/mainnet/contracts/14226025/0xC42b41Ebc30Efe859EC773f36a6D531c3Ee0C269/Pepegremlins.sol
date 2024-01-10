// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title Pepegremlins
/// @author jpegmint.xyz

import "./GremlinsCollectible.sol";

/**_____________________________________________________________________________
|   _________________________________________________________________________   |
|  |                                                                         |  |
|  |                                   +-+m                                  |  |
|  |                           ho/---:.-o-`:---:oh                           |  |
|  |                         mh.  .oddyNMNyddo.  `yd                         |  |
|  |                       s.`./oyhdNMMMMMMMNdhyo/.`.o                       |  |
|  |         h+:--/ohNMMMMy- -sMMMMMMMMMMMMMMMMMMMs- .yNMMMNho/--:+yN        |  |
|  |       m-.+yhys/../hd:`:hNMMMMMMMMMMMMMMMMMMMMMNd/`-dh/../oyhy+.-d       |  |
|  |       - `..-+ymmh/`` `yMMms--:+ymMMMMMNy+:--omMMh` ``:ymmy+-..` .       |  |
|  |       hhs` ./..-smmo/yMMo.`-/+:`.sMMMy.`-++:`.+MMh/+dms:..:-  shy       |  |
|  |          o .NNh/``:-mMMM..dNdms`  yMh  `/mmNd.`NMMN-:.`/hmN- +          |  |
|  |          N: +MMs.  -mMMN +Md`.`   /Mo    .`hMo dMMN:  .sMMo -N          |  |
|  |           N: /mm/`  hMMM/`hm.    `hMd`    .dh.:MMMm  `:mN+ :m           |  |
|  |            No`.sh/` hMMMNs::-``./yNMNh+.``-::sNMMMd  :hs.`+N            |  |
|  |              d/`.s/ +MMMMMMmdddNMssMssMNmddmNMMMMMo :s-`:d              |  |
|  |                d. + `mMMMMMMMMNyys///syyNMMMMMMMMN. / `h                |  |
|  |                 d.`  -NMMMMMMNNhyshdhsyhNNMMMMMMN:  `.h                 |  |
|  |                  Nyo/ -mMMMMMd/y/hNMMh/y/dMMMMMm: :oyN                  |  |
|  |                      y.`sNMMMMd:`.:o:.`-hMMMMNy.`s                      |  |
|  |                        /`.os/mMMdmo-omdMMN/os-`/m                       |  |
|  |                          o.` .+hmNNNNNmh+.` .+d                         |  |
|  |                           Nhhy/.`.....`.:shhN                           |  |
|  |                                 mdhhhdm                                 |  |
|  |       ____                                            ___               |  |
|  |      / __ \___  ____  ___  ____ _________  ____ ___  / (_)___  _____    |  |
|  |     / /_/ / _ \/ __ \/ _ \/ __ `/ ___/ _ \/ __ `__ \/ / / __ \/ ___/    |  |
|  |    / ____/  __/ /_/ /  __/ /_/ / /  /  __/ / / / / / / / / / (__  )     |  |
|  |   /_/    \___/ .___/\___/\__, /_/   \___/_/ /_/ /_/_/_/_/ /_/____/      |  |
|  |             /_/         /____/                                          |  |
|  |                                                                         |  |
|  | ________________________________________________________________________|  |
|______________________________________________________________________________*/

contract Pepegremlins is GremlinsCollectible {
    constructor(address logic) GremlinsCollectible(logic, "Pepegremlins", "PEPEGREMLINS", 100) {}
}
