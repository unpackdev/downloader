
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artistic S.'auro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                      sgIP27                                                                   :5DKRd                      //
//                      BQBQBQBP:                                                             .sBQBQBQB                      //
//                       XQBQBQBQBJ.                                                        iBQBQBQBQZ.                      //
//                         .dQBQBQBQBr                                                   .QQBQBQBQQ:                         //
//                            :QQBQBQBQQ.                                              PQBQBQBQBr                            //
//                               7BQBQBQBQP                                         jQBQBQBQBJ.                              //
//                                 .UBQBQBQBQu                                   rgBQBQBQBq:                                 //
//                                    iPBQBQBQBgr                             :XBQBQBQBR7                                    //
//                                       vQBQBQBQBX:                        LBQBQBQBQU                                       //
//                                          5QBQBQBQBL                   iBQBQBQBQE.                                         //
//                                            .DQBQBQBQBi             .MQBQBQBQQ:                                            //
//                                               iBQBQBQBQM.        qQBQBQBQB7                                               //
//                                                  vBQBQBQBQK   sQBQBQBQBU.                                                 //
//                                                    .IBQBQBQBQBQBQBQBPi                                                    //
//                                                        jBRBQBQBRBd.                                                       //
//                                                        PQBMBQBRBQBi                                                       //
//                                                    .MQBQBQBQBgBQBQBQBv.                                                   //
//                                                  qQBQBQBQQQBQBQEQBQBQBQBi                                                 //
//                                               jQBQBQBQBJ  BQBQB  iBQBQBQBQR:                                              //
//                                            rZBQBQBQBP:    QBQBQ     vBQBQBQBQP                                            //
//                                         :SBQBQBQBQ7       BQBQB       .5BQBQBQBQ1                                         //
//                                      .LBQBQBQBQI          QBQBQ          iEBQBQBQBM7                                      //
//                                    iBQBQBQBQD.            BQBQB             vQBQBQBQBPi                                   //
//                                 .gQBQBQBQB:               QBQBQ                5QBQBQBQB1.                                //
//                               KQBQBQBQBv                  BQBQB                  .EQBQBQBQB7                              //
//                            JQBQBQBQB5.                    QBQBQ                     :BQBQBQBQBi                           //
//                         rEBQBQBQBDi                       BQBQB                        rBQBQBQBQg.                        //
//                      :5BQBQBQBQY                          QBQBQ                          .sBQBQBQBQX                      //
//                    vBQBQBQBQJ                             BQBQB                              YBQBQBQBQJ                   //
//                 iBQBQBQBQD.                               QBQBQ                                :dBQBQBQBZr                //
//              .gQBQBQBQBRBZBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBMBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBEBQBQBQBQBQBK:             //
//           :QQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBRBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBPi          //
//         sQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBRBQBMBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBQBv.       //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                           QBQBQ                                                           //
//                                                           BQBQB                                                           //
//                                                            1QP                                                            //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAURO is ERC721Creator {
    constructor() ERC721Creator("Artistic S.'auro", "SAURO") {}
}
