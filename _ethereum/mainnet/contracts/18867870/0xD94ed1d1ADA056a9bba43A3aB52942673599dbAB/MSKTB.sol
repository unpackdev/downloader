// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moshuka’s Toy box
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//        `   `   `   `   ``..dZUUUWMKUUUyyn..    `   `   `   `      //
//              ...WJ...mJ9UuzzzzwWHXzzdWkXmwwkWn.a.p,..             //
//             JOwXSXXWM9SvvvzzwmQWHKzzzzzvzUWMHpwzupHzzM:           //
//      `  `   (wXWHWHSvvvvvvzW8SzzzzzzzzzzzzXHHUpkwWWkXW:   `       //
//             ;NWkX0vvzzzzZSzzzzzzzzzzzzzzzzzWHHwWWWWWW]      `     //
//              HHHRtrzzzwKzzzzzzzzzzzzzzzzzzzzHHNkXWpHH(`           //
//             .MMURrtrvdHzzzzzzzzzzzzzzzzzzzzvZWMHHWkHH.            //
//        `  .+HMS>(=<wwHSvzzzzzzzvzdSzzzzvvrrrtOdMMMMMMNm,          //
//         ..HHMHSO-(+0dHrtrOtttttrtrWOrtrrtrtrrrrtwWHHMMHHL         //
//       .dH@@@H8dkwkwwHHO(XkttvyttrtXKtttttUytttrdHgg@HMMNMI-       //
//      .4MMHHM#XHZQHZWWHkwXNllzzywHOwWsttrOdKwdkwWMHHHHMMHNWm/.     //
//      qMD_JMNXHHZdWHY"THRwWmzllHX@9mKMQmkXXHZZWZWHMHHHMMMM?WW(_    //
//      WP`dMH@MHWuM9>(.dUWkXHkwrWH$ .(J_WHkXWuuWXZWM@g@@@HWM>Hb+    //
//      (MJHM@M#XSXhMMMMMWMNYT9TAZS_jgMMMNMNM@ZuWWXMH@@@gHHNHldNv    //
//       4XHHUMuWRXM#TMMN-HHP```.?"TjHMx.dMBMH8XWHkWMMMHM#"(WHQ`     //
//        MNkHHWHHX@3.H4VTTW\`` ````,MHMBWM_dWvXHNHHHHkyXMMHXK^      //
//        WMMkHM<WRdI<(<<!! ` ``` ` `?C((?1(jdwWNzTMNMHHkMHHMN       //
//         TN@@H5(HWs<~_ ``` `` `` ````` _~<jHXH4!.WN#=?#HHNH'       //
//         .HMMXh,JHN/ ```.vVj0W]`` ` ` `  _dWWmWWHM3  .MMMh.        //
//             Gkdm4HMi..(V+odXb]``` `` ` .(dWMMY"`  .dHW=           //
//              NW9 ?Wh,?!~_1XWHJ(((..-J?7(H@H?^     gHM'            //
//            ?""!          ?7!          ?""`         7Hh.           //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract MSKTB is ERC721Creator {
    constructor() ERC721Creator(unicode"Moshuka’s Toy box", "MSKTB") {}
}
