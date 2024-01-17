
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kate the Cursed: Comeback Era
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMmhdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmhhNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMm-`-.`+dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNs.`:-`/MMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMmNMMMmshd/  +ys:`/mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMs..+ys- `odssmMMMdmMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM--/o:`  ` +``-sy+.`yMMMMMMMMMMMMMMMMMMMMMMMMMMMN:`:sy+`-:. `  `//:`sMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM+.` `.``  :-+``+so- sMMMMMMMMMMMMMMMMMMMMMMMMMN-`/so-`+y:   ``-` . dMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMh/`..-`-//+:.`//-`-oo. hMMMMMMMMMMmsyNMMMMMMMMMM/ /s/`-yh+`-/++/-`--.`+mMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM- `:`.shhddsy/ -::.`/- sMMMMMMMNy:.::./hNMMMMMMM- /-`:::..oyydhhy+`.:  sMMMMMMMMMMMMMMM    //
//    MMMMMMMMNy/+:.  ` oddhsyhyy.  ``.-:sNMMMMNy/.:oyhhy+:-+hNMMMMmo::..`  /yhhyyddh.   ../:/hMMMMMMMMMMM    //
//    MMMMMMMM+ :- :+/- :yhddddys`   +NNNMMMNh/-:oyhy+--+yhy+:-/hmMMMNMm.   -yhhdddhy``://``/.`hMMMMMMMMMM    //
//    MMMMMMMMo /y+.-shs`-osyso/``  .yMMMmy/-:oyhyo:.`..`.:oyhyo:-/ymMMN+`  .-+ssss/`-:/-`:ss``mMMMMMMMMMM    //
//    MMMMMMMMN/ /ys/`:h-- ````.  ``+Nds:-:oyhyo:.``......``.:oyhyo:-:sdm.`  `````  :+-`.oyo..hMMMMMMMMMMM    //
//    MMMMMMMMMNs`-oso-..+  `  ..`::`-./shhyo:.``...------...``.-+yhhs/`../`.-.  . ./``/ss/`:dMMMMMMMMMMMM    //
//    MMMMMMMMMMMd/`-+o/``.ydosho...-..sy+-.``...------------....`.-+s/`.-..-sysymo `.oo/.-sNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMd+-.-..ody/:-/oy/.-:.``....-----......-------....``:-..sys/-:/yd/.---:yNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNddh..-/oyhys+:``:-.`..--...```````````...---.``-:.``-+syhyo/-.-ddmMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM.`yho/-.``...``:-.````````.......``````...-:-`.......-/ohh -MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM/ oh- .....---.`.o-```.:oyhhohoy+s+:..` `//``-----:::- :hy /MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMo +h+ ....----.```::`.yddmmdyysdsmmmd:`-:.``.-----:::: /ho oMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMy :ys `...---.``.`.-:/.+/mmmmdmmmmmh--/:.`.``.----:::- od+ yMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMm -yy `...--.````omo./:..hmmm-hmmd+`-:-:ho`.``.---:::. sd: dMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM `yh``...--````+myoh:.:-`+dm`ymy-.:-.+somo`.``--::::. hd.`MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM- sh- ...-. ``.mmdyddo.-o.-y`y+`//.:ddhhmN-`. .-::::`.hh -MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM+ +y/ ..... ``/hds++++/.-:-` `.:-.smmmyhdho`` .-:::: /ho oMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMh :ys `.... ``/ohysmmmmmy.-..-:./dmmmmoshoo`` .::::- sd- mMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM.`sh``.... ``-dmmmmmmmmms .o-`-dmmmmmmmmd:`` .::::`.hh :MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMs /y+ ....` ` sohdo+yyd:`-:``:..smmhysddy`` `-:::- +d/ hMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN``sy.`.... ```yhdhyh+..:--y+.::.:hhhdhh.`` .::::`.hy :MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMy :yo `.... ```odyy-.//.+dmmy--o-.omds.`` .::::.`sd-`dMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM/ +y/ .....` ``-/`-:-:hdydydd+.::.-:`` `.-:::- +d+ sMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN-`oy: ......`  -::`:hddsdshdho`.:-. `.--:::- /hs /MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMm.`oy: `....``-+. ``..-::--..`` `//.`.-:::- /hs`:NMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMm-`oy/``.``.:-`..`````````````..`.:-`.::.`+hs`:NMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMm:`+yo```/:.`.----.........-----.`-::`.`oho`/NMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMN+`:+..:/``..--------------------.-/-`-y/`oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMN/ .::..`....----------------:::-`.-::` sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMN/`-.-`/y+.`.....-----------:::-../y:.:.-.hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMh-``.--:./sy+.``....-------:::-../yho..--.``oNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNo`..`.yNNy-./sy+-``....---:::-..+yho--yNd/`..`-hMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMh-`..`+mMMMMNy-./sys:.`.-:::-..:ohho--sNMMMMy-`..`oNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN+``.`-hMMMMMMMMNh:.:oyyo-....-+yhy+--yNMMMMMMMN+`..`-hMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMh-`...oNMMMMMMMMMMMMd+.-+shy++shho:./hMMMMMMMMMMMMh-`.``oNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMN+`..`:dMMMMMMMMMMMMMMMMNy:.-oyhs/-:smMMMMMMMMMMMMMMMNo...`-hMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMh-`...sNMMMMMMMMMMMMMMMMMMMMms----smMMMMMMMMMMMMMMMMMMMMd:`.``+NMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMN+``..:mMMMMMMMMMMMMMMMMMMMMMMMMMmmMMMMMMMMMMMMMMMMMMMMMMMMMs...`-hMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMh.`...yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm/`..`+NMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMm:````/NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy... .oMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMm`:-`yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN-.:-:MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMmhhmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNhyyNMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ERA is ERC721Creator {
    constructor() ERC721Creator("Kate the Cursed: Comeback Era", "ERA") {}
}
