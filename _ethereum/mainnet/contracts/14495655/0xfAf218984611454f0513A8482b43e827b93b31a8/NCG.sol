
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NCG-NabiCreaGraph
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                :ri:                                                                                               //
//                                                                   ZBBQBBBQY                                                                                       //
//                                                                  rBBBBBBBBQBI                                                                                     //
//                           iBi                                    .BBBQBBBBBBBBi                                                                                   //
//                           QBQ1                                    PBBBBBQBQBQBBI                                                                                  //
//                          rBQBBQ                                   iBBBBQBQBQBQBQb                                                                                 //
//                          BBBBBBBr                                 :BBBQBQBQBQBBBQD                                                                                //
//                         UBBQBQBBBD                                uBBQBQBQBQBQBBBBP                           .JgBBBE                                             //
//                         BBBBBBBBBBBi                              gBBBQBQBQBBBQBBBQs                      :2QBBBBBBBv                                             //
//                        dBBBBBQBBBBBBP                             gBBQBQBBBQBBBQBBBBi                  igBBBBBBBBBBr                                              //
//                       .BQBBBQBBBQBQBQB:                           bBBBBBQBQBQBBBQBBBB.  ..          .KBBQBBBBBBBBJ                                                //
//                       BBBBBBBBBQBQBBBBBI                        .qBQBBBBBQBBBQBQBQBQBR  vi        rQBQBBBBBBBBBP                                                  //
//                      rBBBBQBQBQBQBQBBBQBB.                      BBj  vMBQBQBQBQBQBBBBB7 i:     JZBBBBBQBQBBBBX                                                    //
//                      QBBBQBQBQBBBQBQBBBBBBS                    vBg  .1BQBQBQBQBQBQBBBBQ  :   iBBBBBBBBBQBBBQY                                                     //
//                     JBBBQBQBQBQBQBBBBBQBQBQB.                 .BBLrBBBQBBBQBQBQBQBQBQBBi  jrXBQBQBBBQBQBBBBv                                                      //
//                     BBBBBBBQBBBQBQBQBQBBBBBBBu                qQK7BQBBBQBBBBBQBQBQBBBBBP UBRBBBBBQBQBBBBBBv                                                       //
//                    BQBQBBBQBQBQBQBQBQBBBBBBBBBB.             :BB:XBBBBQBQBQBQBBBQBQBQBBBQBBBQBQBBBQBBBBBBi                                                        //
//                   rBg PBBQBQBBBQBQBBBQBQBQBBBBBBJ            QBi BBQBQBBBQBQBQBQBQBQBBBBBBBBBQBQBQBBBBBP        .:YXdQBBBPKL:                                     //
//                   BB.  :BBBBBBQBBBQBQBQBQBQBQBBBBB.         iBB .BBBBBQBBBQBQBBBQBQBQBBBQBBBQBQBQBBBRi      .2BBBBBBMQMQgBBBBBBBJ.                                //
//                  PBg     SBBBBBQBQBBBQBQBQBBBBBBBBBu        BBi  dBBBQBQBQBQBBBBBQBBBQQDBQBQBQBQBBBQP     LQBBg7.           .rEBBBB:                              //
//                 .BB       :BBBQBQBBBQBBBQBBBQBBBBBBBB.     jBE   .BBQBQBQBBBQBBBBBBBBRvZBBQBQBBBQBBBI   XBBB                     71.                              //
//                 BQS         5BBQBQBQBQBBBQBQBBBBBQBBBB2   .BB.    SBBBBQBQBQBBBBBBBBB.iBBBBQBBBQBBBB  JBBBBB:                                                     //
//                7BB           .BBBBBBQBQBQBQBBBQBQBQBBBBB  PBY     rBBBBBQBQBQBBBBBBBK JBBBQBBBQBQBBS:QQBBBQBB.                                                    //
//                BBr             UBBBBBBBQBQBQBQBQBQBBBBBBBgBQ      :BBBBQBBBBBBBBQ:    XBBQBQBQBBBBR2BBBQBBBBBB                                                    //
//               EBB               .BBBBBBBQBBBBBQBQBQBBBBBBBB:       KBBBBQBBBBBg:      PBBBQBQBBBBEIBBBBBQBBBBBE                                                   //
//              .BQ:                 KBBBBBBQBQBQBBBQBBBQBBBBK         JBBBBQMdr         KBBQBBBBBBLrBBBBBQBQBBBBB1                          :qv                     //
//              BQB                   .BBBBBBBBQBBBBBQBQBBBBB            vSDBDU7vu7..    :BBBQBBBQ. gQBQBQBQBBBQBBBi                     .2BBBBB                     //
//             bBB.                     UBBBBBBBQBBBBBQBBBBB7        :YEMRgBRdMBBBBBBBBd.:RBBBBBX  YQBBBQBQBBBQBQBBB.                 rQBBBBr 7BE                    //
//             PBI                       :BBBBBQBQBQBBBQBBBg      rgBBBBBQBB:       .iXQBBBQBqi    QBQBQBQBQBQBBBBBBB             :PBQBQu.     BB                    //
//                                         qBBQBBBBBBBBBQBB:    uBBBQBBBBBBBi            iEBB7    :BBBQBQBQBBBBBQBBBBS        .2QBQBP:         ZBr                   //
//                                          iBBQBBBQBQBBBBP   UBBQBBBQBQBQBBr               PBBJ  sBBQBQBQBBBQBQBQBQBQr    :QQBBRr             SBu                   //
//                                            PBBBBBQBQBBB  .BBBQBBBQBQBQBQBr                .QBB 7BBBQBBBBBQBQBBBQBQBB.   7Dj.                qBU                   //
//                                             rBBBBBQBBB7 :BBBBBQBQBQBQBQBBr                  LBBBBBBBQBQBQBQBQBQBQBBBB                       PBY                   //
//                                               RQBBBBBZ :BBBBBQBBBQBQBQBBBr                   .v7BBBQBQBQBBBBBQBQBQBBBM                      BB.                   //
//                                                sBBQBQ: BBBBBBBQBQBQBQBQBBi                      MBBBQBQBQBQBQBQBQBQBBB5                    :BB                    //
//                                                 .QBBX QBBQBQBQBQBQBBBQBQB:                      7BBBBBBQBQBQBQBQBBBQBBBr                   BBi                    //
//                                                   PB:iQBBBQBQBQBQBQBQBQBB:                       PQBQBQBQBQBQBQBQBBBQBQB:                 JBg                     //
//                                                      BBBBQBQBQBQBQBQBQBBB:                        QBBBBQBQBQBBBBBQBQBQBBB                7BQ                      //
//                                                     .BBBQBQBQBQBQBQBQBBBB:                         QQBBBQBBBQBQBQBBBQBBBBR              UBB                       //
//                                                     7BBBBQBQBQBQBQBQBQBBB:                          KBBBBBBQBQBQBBBQBQBQBBq            BBg                        //
//                                                     vBBBQBQBQBQBQBBBQBBBBi                           :BBBBBBQBQBQBQBBBQBBBB7         SBBi                         //
//                                                     iBBBBQBQBQBQBQBQBQBBB:                             vBBBBBBBQBQBQBQBQBQBB:     .PBB5                           //
//                                                     .BBBQBQBQBQBQBQBQBBBQ:                               7BBBBQBBBBBBBBBBBBBB. .2BBBu                             //
//                                                      ZBBBQBQBQBQBQBQBQBBB:                                 .YMBBBBBBBBBBBBBBBBBBBq.                               //
//                                                      :BBBBQBQBQBBBBBQBQBBi                                     .ijKRMBBBQQDdu7:                                   //
//                                                       UBBBBBBBBQBBBBBQBBB:                     SBi                                                                //
//                                                        RBBQBBBBBQBQBQBBBBi                    bBB.                                                                //
//                                                         MBBBBBBQBQBQBQBBBr                   gBB                                                                  //
//                                                          IBBBBQBQBQBBBBBB7                 iBBq                                                                   //
//                                                           :BBBBBBBBQBQBQBr                RBB:                                                                    //
//                                                             rBQBBBBBQBBBBr             :QBQ1                                                                      //
//                                                               :EBBBBBBBBB:          7EBQBv                                                                        //
//                                                                  iqBBBBBBq.::iiIbBBBBBu.                                                                          //
//                                                                      .7JEBBBBQBBgIr.                                                                              //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NCG is ERC721Creator {
    constructor() ERC721Creator("NCG-NabiCreaGraph", "NCG") {}
}
