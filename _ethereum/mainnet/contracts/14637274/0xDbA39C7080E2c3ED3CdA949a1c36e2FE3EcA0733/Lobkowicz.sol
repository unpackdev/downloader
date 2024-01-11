
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Patronage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                              BBU                                                                             //
//                                                                            BGS@Y@B                                                                           //
//                                                                            G:uBirk                                                                           //
//                                                                             :B@8.                                                                            //
//                                                            .. J@j JX       @5   MB      ,qr E@i ,.                                                           //
//                                                           :B@ 1BN @Biv@S  :BGB@BMB   M@:1B@ @Bir@B                                                           //
//                                                        .B@::Oq0@8XEj OBZ   FB@B@Br   @BU F0xb1PZE.u@B                                                        //
//                                                         G2uB@J. ,ruM@Mv :BZ:;iiiiiBB  2B@Zji. ,F@ZJFN                                                        //
//                                                       q@B @@  rOB@B@B@B@r.B@BOY@B@B.U@B@B@@@BN:  @B B@7                                                      //
//                                                       :Pv @7 @@@@B@B@B@@@1 B@rOr@G M@B@B@@@B@B@B M@ SS.                                                      //
//                                                        @@v0@i@B@B@@@B@@@B@: B7 ZB F@B@B@B@B@B@B@;@LFBE                                                       //
//                                                        NBi B@@@B@B@B@B@B@B@ @@0B@ @B@B@B@B@B@B@B@q u@u                                                       //
//                                                         .@B.v@B@B@B@B@B@B@B rJLu. @@B@@@@@B@B@@@:iB@                                                         //
//                                                          F5i:j@B@B@B7::i2@i.20OqY vBJii:JB@B@B@L:7ku                                                         //
//                                                            @Bu LvUq rMBOL :@@@B@@@  uBBG, ZJLr @B@                                                           //
//                                                             .  BBj r@B@@@B@B@: r@B@B@B@@@  5@M  ,                                                            //
//                                               7;               :B@B@B0  r@B@Br u@@B@.  B@@B@B                v:                                              //
//                                              X@qBY.               @B@B@B@@@B@B@B@B@@@@@B@B@               ,UBk@7                                             //
//                                             OM   JGOF7:.   ..::riGB@GkuL:,   .B   .:ij10O@B2ii:,.    ,:LPM07   @u                                            //
//                                            BZ       .:iu52jvLv7:.             @             ..:iL2XSSUYi,       @P                                           //
//                                           BS         .7.             7v       B              LSL                 BO                                          //
//                                          BL         2BB  v@@@MGB@B@   @B      @            :@MYM@:                EM                                         //
//                                         BU          .@BMU@B@@@B@B@B@2@@@      B    :B@B@B: kB   Bk ,B@B@@:         @B                                        //
//                                         :Bi        ..:1M@@@B@B@B@@@@@EL..     @    B@B@B@B0 r   r qB@B@B@B.       uM.                                        //
//                                           BY       J@@BNB@BLk@@@7EB@NMB@B.    B   r@B@B@B@7:,.  ,:7@B@B@B@r      GO                                          //
//                                            @L        ;qU5O,J B@r L:B7q5,      @   .BrBrM7 N@@B@@@@q 7MrBrB      ZG                                           //
//                                             B,           @B@F@BqBBBr          B    B87Gr XB@B@B@@@Bq 7Z78@     LB                                            //
//                                       . UL  .B            @@@B@B@BL           @     @LJ 1BMP@B@B@PMB1 uY@      @   Pi .                                      //
//                                       B@E: . @r           ;@Z@B@O@            B      @ JB@. u:.:u .@BJ @      N5   vE@u                                      //
//                                       F5  @@ :@            BU   Ou            @       kB@B :M1u1M: B@BX       @  BP  M7                                      //
//                                     j@v  @ZE  B           8@    ,@.           B      @B J7 @@@B@B@ 7J B@     ,B  BE@  S@i                                    //
//                                   .5MB@BM.    @           .EYu2Y15            @      ::   iB@B@B@Bi   :,     7M    i@@@@8u                                   //
//                                   P@  7@L     M:                              B  . .      M@B@B@B@M          11     M@v .@L                                  //
//                                  0r: LEi      PB@B@@@B@B@B@B@B@B@B@B@B@B@@@B@B@i7rLiuYr7rB@B@B@@@@@B@B@@@B@B@Br      rM: 775                                 //
//                                 .@BM705       F@B@B@@@B@B@B@B@@@B@@@B@B@B@B@B@M  7B. @Ev 8B@B@@@B@BEr5M@B@B@B@i       05L@B@                                 //
//                                 0LMB@L        0B@BSB ;OX@BPOr @5@B@B@B@B@B@B@BM 7:P@:B@q Z@B5:ZB@BM    B@B8B@Bv        q@BZuU                                //
//                              .jFB  Y:         B@B@i    OB@Z    iB@B@B@B@B@B@B@Z,@B.M2vEi OBu   @58:k   @M Y 1@S         7r  BJL                              //
//                               7@  ,B,         @B@Bi.  ,5@BS,  .i@B@j          @ 0@@1M@.7 G@BJ  :ZM@,   Bk.@: B@         vB  :B,                              //
//                               :L  B7i        .B@@@B@7@B@B@@@BvB@@@Bj          B .vO,M@v. ZB@B@: 8:     qB :2.@B         ;2B  5                               //
//                               @B@0X          2@B@B@B@BqB  @P@B@@@B@J          @    :  Z5 k@B@@@B       B:7.B v@i          OZ@@@                              //
//                              Eu@B@E          @@@B@B@B@u    1B@B@B@BG,rri:i,,.;B     .S,v OBX ir        @Ei,i: B@          @@BM1k                             //
//                              Mu iJL         L@@B@B@B@Bv.  .v@B@B@B@q.::vU:M2v:@@@B@B@B@B@B@7   B@B@L:  5@B ,@M@@.         uJ  PZ                             //
//                             Lj: vM          @@B@@@B@B@B@E8B@B@@@B@B8   LB.q@k B@B@B@B@B@B@B@F@Bu.   B   v7 :@@B@B         :M: 7U;                            //
//                             YB@B8G         O@B@B@B@B@B@B@B@B@B@B@B@@  @7r@rBX @B@B@B@B@@@B@B@B@i .LB@  k@  :BB@@@j        ,MOB@B:                            //
//                             ,@B@B7        J@B@B@B@B@@@@U  U@BMD@@@B@O 0@MUOv: B@B@@@BMFM@@B@BBB: :B@B  r8@0@@@B@@@:        EB@M@                             //
//                             .M  M        r@B@B@BY,@B@B1    U@B@B:L@B@0 :S7@q,:B        G@@@Bi   EB@B@@7 :B@B@B@B@B@.       :N  @                             //
//                            JB8  B@r     L@@@B@@,   BB1      5@M   ,@B@B. . EPrB      rB@B@B@E  rB@@@j   B@@@B@@@B@B@:     L@X  @Br                           //
//                             :B  @.     Z@B@B@M      :        ,      BB@@M::   @   .2@B@@@B@B@B@B@B@B7, O@B@B@B@B@B@B@u     rq  B                             //
//                              Oj1BY   j@@B@B@@: :ii:    ,:ii:    .::..@B@@@@@2vBrE@B@B@@@@@@@@@B@B@B@B@@@B@B@B@@@B@@@@@Br   8G1J8                             //
//                             ,B@B@M   k@;  ...:irrii@@B@B:i;:@B@BB:i:.B@B@u.:ir@ir                           ... .    u@7  ,@@B@B                             //
//                             7u; :Oi    Mi          @B@BY    @@B@L    @B@Br    B @0.         :E:.          .E@       jq    JN. rk:                            //
//                              0M  5L     @S         B@@@J    @@@@J    B@B@7    @  B@B@B@B@: v@@@B:  B@B@B@B@B       B0     JS  @u                             //
//                              kYuE8B      @v        @B@Bu    B@B@L    @B@BL    @ ,  ,vMB@B .qrZB@k  .@@B87,  :     OM      BZEY5J                             //
//                               @B@B@       @        B@B@j    @B@Bj    B@B@v    @ iB@@@B@BJ .  M@BB   kB@B@B@Bi    :@      .@B@BB                              //
//                               .k  KN:.    P8       @B@@u    B@B@L    @B@BL    B    :7F@@BkFXq@L@B@B8B@B05u7:     @i    ,,@r .k                               //
//                                @q  B@      B       B@@@j    @B@BJ    B@B@v    @  u@B@BMB@E5O@r iME20@BOB@BBL     @      @O  @0                               //
//                               r8B7 :J      @       @B@@u    @@B@Y    @B@BL    B     ,7G@BB8ui: iiuXOB@8u.       r@      U  SB8:                              //
//                                 :0rN@@.    Bk   .rEB@B@j    @B@BJ    B@B@v    @     7uu:   B@@@B@B:  r:  rOi.   @P    :B@kiM                                 //
//                                  OB@8u8:    vXXq2i,@@@Bu    B@B@L    @B@BL    B         ,MZ@B@B@B@BvF@X  @:75PXSr    LGJB@BL                                 //
//                                  ,Gr  O2:          i@@@J    @B@Bj    @@@@v    @    i2B@N0B@B@B@B.X Lr:P @i          iXS .;M                                  //
//                                    @X ,YB.          7@Bu    B@B@Y    @B@@L    B    7BG:51 u  @B:  r1   @v          7B7  MG                                   //
//                                    iqM@B@N           ,@B    @B@Bj    B@B@v    @     v        L@i@BG  L@:          :O@B@EP.                                   //
//                                      MBr :BBF          NBr  @@@@L    @B@@L    B           .@@FB    rBX          MO@  u@2                                     //
//                                        SL  BS           .kOv@B@BJ    @@B@v    @         @B@Bu   .uMu            @q  EL                                       //
//                                        @BN  i@Z,           :Y@B@P    @B@BL    B         Y    ijG1:           :B@. iq@S                                       //
//                                        . vFE@BMF8              iqXu: @@B@v    @          :uXPv,            :BU@B@5N: .                                       //
//                                            @BL  kLS:              :j2@@@BL    B      :uZPY,              7uSL .YBM                                           //
//                                             vv@, U@Bu. :               7@B.   @   iXG2i             ., ,0B@7 r@rr                                            //
//                                               YNG@Br @q@.                .kMi B LBF:                v@qO kB@XGi                                              //
//                                                 :FFii  77JZ7:               uB@Ov              .:L8ru,  7:0u.                                                //
//                                                    :Bq8  @BEv@P7r    :        :        :    7RM@;@B@ :q@@.                                                   //
//                                                     5.:r@BB:  iv@BrXNBr:   iEB@MF.   :UBS2YB@;:  i@BMr,,u                                                    //
//                                                          rJuBk.@@@ :  X:  B@@k BB@M  7F  . @B@.ZBvU:                                                         //
//                                                              rLkBrU8.7v  YMj@M:B@B@7  Ui:B7uMSvi                                                             //
//                                                                    Y@ru. iBiE@E@B@@7 :YLB,                                                                   //
//                                                                           q5@U B@Xu                                                                          //
//                                                                             2: j:                                                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Lobkowicz is ERC721Creator {
    constructor() ERC721Creator("Proof of Patronage", "Lobkowicz") {}
}
