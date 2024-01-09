
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gentlemen Pepe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                     :*+#+++i.                                                                                //
//                                                                  ,#nnzzzzzzznn+.         `:*##zz#*,`                                                         //
//                                                                .#nzzzzzzzzzzzzzx#,    `;#xnzzzzzzznn;                                                        //
//                                                               ixzzzzzzzzzzzzzzzzzn#``*nnzzzzzzzzzzzzn#                                                       //
//                                                             `+nzzzzzzzzzzzzzzzzzzzzxxzzzzzzzzzzzzzzzzz#                                                      //
//                                                            `zzzzzzzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzzn;                                                     //
//                                                            #zzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzx`                                                    //
//                                                           *nzzzzzzzzzznxxxxxnxxxzzzzzxzzzzzzzzzzzzzzzzzzi                                                    //
//                                                          :nzzzzzzzznxnzzzzzzzzzznxxzznnzzzzzzzzzzzzzzzzzz                                                    //
//                                                         `nzzzzzzznxzzzzzzzzzzzzzzzzxxzxznxxxnxxxxxxxxxxzx`                                                   //
//                                                         +zzzzzzzznzzzzzzzzzzzzzzzzzzzxMnzzzzzzzzzzzzzzzxxx#;`                                                //
//                                                        .xzzzzzzzzzzzzzzzzzzzzzzzzzzzzznnzzzzzzzzzzzzzzzzzzznn*                                               //
//                                                        #zzzzzzzzzzzzzzzzzzzzzznnxxxxxxnnxzzzzzzzzzzzzzzzzzzzzzn.                                             //
//                                                       .xzzzzzzzzzzzzzzzzzznxxnnzz###zzznxxnzzzzznxxxxxxxxxxxxxnx                                             //
//                                                       *zzzzzzzzzzzzzzzzzxxzzzxxxxxxxxxxnzznnzxxxzznnxxxxxxxnnzzxn:                                           //
//                                                     ;#MzzzzzzzzzzzzzzznxzznxnzzzzzzzzzzznxxMnzxxxxnzzzzzzzzznxxxzn;                                          //
//                                                   ,nn#xzzzzzzzzzzzznxxnznxzzzzzzzzzzzzzzzzzzxxzzzzzzzzzzzzzzzzzznx#                                          //
//                                                  ,xzznnzzzzzzzzzzzxnzznxnzzzzzzzzzzzzznnnnnnzzzzzzzznxxnz#####znnzx+                                         //
//                                                 `nzzzxzzzzzzzzzzxnxxxnzzzzzzzzzznnz#*:.....,#zznnz+i:.:nW#@M#.  .izx`                                        //
//                                                 +zzzzxzzzzzzzzzxzzzzzzzzzzzznn++zxW@@x*`    ;z+:`    ##Mn####W.   `+`                                        //
//                                                ,xzzzzxzzzzzzzzznxxxnznnnnz+;. *@xi@####x`   *`      *###;#####z    ;,                                        //
//                                                nzzzzzzzzzzzzzzzzzzzzM#,`     :##M*@#WW###   *       W######;@#@.  `+.                                        //
//                                               ;nzzzzzzzzzzzzzzzzzzzzznz:     z#####W``@#@``i;      .###z@#+,@##i`;#.                                         //
//                                               nzzzzzzzzzzzzzzzzzzzzzzzzn#;`  x##@#@##z###znzn*;,`  ,###n@####@Wxnz#                                          //
//                                              ;nzzzzzzzzzzzzzzzzzzzzzzxnzznn#iM###x###@WMnzznnzznnnzzWWWWMMxnzzzzx+.                                          //
//                                              nzzzzzzzzzzzzzzzzzzzzzzzzznxnzzznnnnnnnzzzzzzxnzzzzzzzzzzzzzzzzzzzz`                                            //
//                                             :nzzzzzzzzzzzzzzzzzzzzzzzzzzzznnxxxxxnxxxxxxnnzzzzzzzzzzzzzzzzzzzzx,                                             //
//                                             #zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzzzznz.                                              //
//                                             nzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznxnzzzzzzznzzzzzzzzzzznn;`                                               //
//                                            .nzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznxnzzzzzzzzznxxnnnnnxxxxx`                                                 //
//                                            :nzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznxxzzzzzzzzzzzzzzznWnnnzzzzzz`                                                //
//                                            izzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzn`                                               //
//                                            *zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz`                                              //
//                                            +zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzni                                              //
//                                            #zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzn`                                             //
//                                            zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzn;                                             //
//                                            #zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz+                                             //
//                                            #zzzzzzzzzzzzzzzzzzzzzzznnnnnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz                                             //
//                                            #zzzzzzzzzzzzzzzzzzzzzxxnzzznnxxxxnnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznxxz`                                           //
//                                            +zzzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzznxxxxxnzzzzzzzzzzzzzzzzzzzzznxxzzzn:                                           //
//                                            *zzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzzz#znnxxnxxxnnzzzzzznnxxxnzzzzzzn,                                           //
//                                            ;zzzzzzzzzzzzzzzzzzznzzzznnnnnnnnz#zzzzzzzzzzzzzzznnnnnnnnzzzzzzzzz#ni                                            //
//                                            ,nzzzzzzzzzzzzzzzzznzzzzzzzzzzz#znnnnnnzzzzzzzzzzzzzzzzzzzzzzzzzzzn#,                                             //
//                                            .xzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzzznnnnnnnnnnnnzzznnnnnnnnnnnnx`                                              //
//                                            `xzzzzzzzzzzzzzzznzznxxxxxxxnnzz#zzzzzzzzzzzz##zzzzzzzzzzzz##zzzzzzi                                              //
//                                             nzzzzzzzzzzzzzzzxzzzzzzzzzzznnxxxxnz##zzzzzzzzzzzzzzzzzzzzzzzzzzzn,                                              //
//                                             zzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzznxxxxnnzzzzzzzzzzzzzzzzzzzzzzni                                               //
//                                             ,xzzzzzzzzzzzzzzzzxxnzzzzzzzzzzzzzzzzzzzznnnxxxxxxxxxxxxxxxxnn#*.                                                //
//                                              :nzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzn#`                                                    //
//                                               `*nnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzx;                                                      //
//                                                 `izxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzx#.                                                       //
//                                                    .izxnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzx#.                                                         //
//                                                       `:+#nxnzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznnzi`                                                           //
//                                                            `,;*+#znxnnzzzzzzzzzzzzzzzzzzznxxz;.                                                              //
//                                                                     .,;i*++####zzz####++i:.                                                                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GP is ERC721Creator {
    constructor() ERC721Creator("Gentlemen Pepe", "GP") {}
}
