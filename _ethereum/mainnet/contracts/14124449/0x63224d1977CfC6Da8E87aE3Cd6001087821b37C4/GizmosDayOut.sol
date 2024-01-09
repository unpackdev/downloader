// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title GizmosDayOut
/// @author jpegmint.xyz

import "./GremlinsEdition.sol";

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
|  |                     _______                                             |  |
|  |                    / ____(_)___  ____ ___  ____  _____                  |  |
|  |                   / / __/ /_  / / __ `__ \/ __ \/ ___/                  |  |
|  |                  / /_/ / / / /_/ / / / / / /_/ (__  )                   |  |
|  |                  \____/_/ /___/_/ /_/ /_/\____/____/                    |  |
|  |                   ____                 ____        __                   |  |
|  |                  / __ \____ ___  __   / __ \__  __/ /_                  |  |
|  |                 / / / / __ `/ / / /  / / / / / / / __/                  |  |
|  |                / /_/ / /_/ / /_/ /  / /_/ / /_/ / /_                    |  |
|  |               /_____/\__,_/\__, /   \____/\__,_/\__/                    |  |
|  |                           /____/                                        |  |
|  | ________________________________________________________________________|  |
|______________________________________________________________________________*/

contract GizmosDayOut is GremlinsEdition {
    constructor(address logic) GremlinsEdition(logic, "GizmosDayOut", "GIZMO") {}
}
