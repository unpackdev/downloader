
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Parin Heidari
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                            (y' ,,,,,,`   .                                                                  //
//                                                                                                     :GGS##################m, `                                                              //
//                                                                                                 .;GQs##########################m, ~                                                         //
//                                                                                               :jS#######@###########################m#p                                                     //
//                                                                                             ;s############@#Nm############################m,                                                //
//                                                                                           /;#############@###@###############################b                                              //
//                                                                                           D############@######################Q##@#############                                             //
//                                                                                          ]####@#####################################Q###########p                                           //
//                                                                                         #######@########################################Q#########                                          //
//                                                                                         #@##@########@################################@Q@##Q#@######                                        //
//                                                                                        ~@####@#@#####################################@###############b                                      //
//                                                                                      ^ ############################Q@##########@@###########@#########b                                     //
//                                                                                       @######################################@########################@b                                    //
//                                                                                      `-"7@#############Q################################################N                                   //
//                                                                                        ,-%#bbGQ#W"777coGo|799bWWWWWWWWWWWW###############@@####Q38#@####@#N,                                //
//                                                                                       ,^  ~|aGGS**********^                   7J5#####WW##@@######7>wJ29Qb##Q                               //
//                                                                                       0"""""bGGC***                       ^     \@##@#@sQ*4=eJ,4"(**I%`^^` |   -                            //
//                                                                                       j  .  pC**ooGGG                       ^     V7####p    , *%#\   p~  *j|  ~j                           //
//                                                                                      fj^ 'ppMp**C**^                              ^ |@NQ#acj ' 'C@bp '.\;^32b | #                           //
//                                                                                     ] 8   pb0*p*                      ,.s<y<,       !!Q@#bl`[j   G@#  ^.. *.j|*y#p                          //
//                                                                                     ! b   b~b)Qp ..             ,sQ##2M"7||||\       v@##QbGp b  **p`     ' j} S##N                         //
//                                                                                     Mj    b #*@TGWGNwspy       1#kC,,sWWTQQ@`  ^  !|fcQ@##NNbO9GG*9"    ^   j8b@@##b                        //
//                                                                                     T[    @ b^^@&psW*WW-,v        Cjj,I.<.;#^ ^  ' .c}|##@bQ#*^`?.o         j*C#####b                       //
//                                                                                    !|b   ,  [  |Ck.`..>C>|p    t;.7mmQs##b|      [o**^Lb@@###   *C*        :|Cj@####b[                      //
//                                                                                    [Sp/  .,.b    "###bW4  b    d@p|^.`||        .GGGo:$'8#Qb    ?C@       :^G)@###@##j                      //
//                                                                                    [d    ?CGb9   .        b    @j!G            ,GGCC}b. %@b~    'C@      :**,@####@##D!                     //
//                                                                                    f j    G?bC9   \       |    ^pQGo          ;CGOC/^ ^  !/        c    :**.]###b@####~                     //
//                                                                                   ,  `    'CGCG}   `      @     |**|YG       fCG'Gf` '/ . j        ^,  .** ##@##S@#@NTL                     //
//                                                                                  /  j      **CCG     \    @p       z|      :f*^ .` ! '`/`!/         b  o*j#######%$@b#~                     //
//                                                                                       jV.  '**.   s###QN   `"~-eb          :^  *  // ^[  !~         \ .Go#G#####b ,*^C                      //
//                                                                              ,        ^*G77bp'  ,#######Np      l  ,   ,s^^| *`  /.   b  !p          \'?Q7*^";880@sQQ#                      //
//                                                                             .          :*.s"    @#@#@####@Np'@##s#87NJQ#b       * L  \b   '.-         ^JLb ^[/ /lGbGGG$`~.                  //
//                                                                            /          *^$f  ,,  @##Q##@Q##@#N 75#pNjS>"`      .  ^Cb        \          ?b*^  ;s#G9bGGG# ,,  ,`              //
//                                                                           '         .oyb",S#GGG##QQbsSG5f2@$##b *"`|.^`     ;  (*` b         |          jp^,#GGGSbQ#8GGpG#M  '\             //
//                                                                         /          :*/Z`#GGGGSS#S##QGQbQ#  /f[b\   !.p    ,,~7|    b       sGp         .-^lb8SGGGGGGGGG#GGb   }             //
//                                                                       ,           :*Zb;#G#lG#bGG$Q###@##8@`|j@.:  `"^``J-^,>^    /j .| ( .#G#S    .<hspN#GGGSG8p#GGGGZ#GGGGG# ^             //
//                                                              QQs~`  ,^           :*j\#GGbQ#QQ#GS@8S##Q@#GG~*jbo**  ^ ,,@^|      | |  :;.)Q#bQQ,@N#####pGGGGGGGGGGGGG@bGGGGGGG# }            //
//                                                             #b8Gbp#@###ws,,,,    G;Z#GG#Q#GGG@#Q8#@##Q#@G# *@***    Gjoj.       |-ppb?,.GQs#l###Q#####GGGGGGGGGG8pG9$GGGGGGGGGb!            //
//                                                             #S##G#8#S##NGQ@#$##@###GGGGSGQ#@SGNG$S###@bGbb.*#Go*,,|`?WpG8   ,.,a#bC* ^;#8S######Q####S@GGGGGGGGGSGQG#GbGGGGGGGQ~u           //
//                                                          V ]GGGGGGGGG@###S$########N#@bGSGG@QQb$#QG##@bGbS+jIC*      GSC*GZpsGCGG^  Q;GGG@#@#Q#@G######pGGSGGGGGGGG8pG#GGGGGGZG '           //
//                                                            T8SGGGGGG#SG8@########$#$G@##GSS8GG@@#G#b#@#GbS*{G*C       |GGGGy^GG^  *L{GGGGG@#Q#b########QSSGSGGGGGGGG8QGGGSGG#GGb [          //
//                                                          /,#GSG$GGGGGG##########QG#GQ#bSSQQQGG#G##QG@##G8SjbG*           'fb     j {GGGGGG$@S########Q##GGGGSb$GSG$GGG8NGGG#GGGG !          //
//                                                        /h~^GSGGGGGGGGGWQ#######@#bSQ9NGQGSQQQ######G8#QbGb$GCC           Oj      b!GGGGGGS8@########Q#Q##QSG$p####GGGGGG8##GGGGG j          //
//                                                      ib"I#GQ#GGGGGGS####QQ##$N#bG8GS@$QQ#$S@b#####GG$#8Q#QbGC            `    . b.QGGGGGQbG@##########@#GS############GGGGQGGGGG j          //
//                                                    ,GGGG8XGSQ@SQSGGG########Q@#G$QGN#SQQ#Q$b#####GSGG##8S#G*C                  / #GGGGGGGGG@#######$#b############8TGGGGGGGQSGGG            //
//                                                   #GGGGGGGG#G#9#G88##8##bGQG8@#@GGb@bNQQQ@b##S##bQG9G###GbCo~                 ).{GGGGGG#$GGGQ###S############TGGGSGGGGGGGGGGbGGS            //
//                                                 ,@GGGGGGGS#GN;##Q@S,QG8$G8GG####@G#@@#GQ#G##G###G#GGG$##b@CC                  b #GGGb@#@bGGGb#lQ#########$GGGGGGGGGGGGGGGGG#^GGG |          //
//                                                sXbGGGGGG@GGGN####$,#S# #GGQ#b@######@#G####G####GG9GG$$Gb@GG                  bjGGG$#WG##GGG8G####@##$GQGGGGGSQGGGSSGGGGG#@QbGGGb[          //
//                                               Q#GGGGGGQGS##SQ##b#b#G# #GGG##S##G@#@#@#@@##GS###bGGGGGGGQb@bG                  @'@Z$GGS###GS#GbG@##$##GGQQQQGGSGGGGGGSGQG#SbG#GGGGp          //
//                                             ,@bGGGGGGGG###G@bbG#b#G# $GGN@###NQ8G@###b#b#GGG@##GGSGGlGGGb8bC                  '.,jGGGS@bb#GGG8GG#####GGQQQQGQGGGGGQGGQ#G##bQG@#GGb          //
//                                             4bGGGGGGGG###@Q##GS#$QS {QSb]#####G@G#@@bGGGGGGGGSQbGQG#@GG#G8bCo                    #GGG@@#GbSGGGGG######GSQQ$GQGGGGGSGS#b##G@GGGk@GG          //
//                                             $GGGGGGGG###$QG#GGG#GGb,QQb ##Gb#bG8G@@#bSGQGGGQG#b#GG#N#G9G$@GG|                   {GSGGS##@pGGGGGQ#$G###GSGGQGGQGGGGGG####GGG8GGQ3GGl         //
//                                            ]GGGGGGGG@##$b##GG@GGGb,#Gb ##@bGb#G8b@@SGGSGGGG#G@##QS##S#GGS@GGC                 /.GGGG$Q##@GGGGGGG#@###bGQGGGGGSGGGGGSGGpGGGGSbSGQ@Gp         //
//                                            $GGGG9GG9##$b#bGGQbGQS######QQ$Gb$GG#@@#$GSGGGG9GS@#bS##GbGGGSWGGG                ] #GGGS##@sb#GG#GGG8#N###GGGGGGGQGGGGGQQQb@GGGGG@GGGbpp        //
//                                            bGGGGGG######GS$G$##QS#Q@S#Q#NbG#GGGy#Q$bbSSGGG8Q###G##QbGGSG@dGGG*               [{GGGG$Q#@GGGGGbGGG##@###GGGGSGGQGGGGG$QQS!GGGSSG8pG8b[        //
//                                           !bGGGGS####G#SQ####SS#####@###@#GGGGGGG@b@GGGGGSGG#$b####b@GGG$bGGGo               uSGGGGS#b@GGGGGG@GSQ$G@GGGb@GQSGGGGGGGGQQG'GGGGSGG8GGb|        //
//                                           !GGGGG@###S#G#bQ##S####Q#S####@QGG#T$GG#G$GQGGG$GQ#@S#Q#  @GGG$WGGGC*        .    !@GGQGS@N##GSGGGG@SS8SGGGGGb1GGSGGGGGGGGQQQ,GGGGS$@S#bN#        //
//                                            lGGGG8@#$@9#bSl#G##$#bS$#Qb#S@#b# #GbG$SbGSGGGQS@#b#SbG,,@GQGQ#CGGCG*.      j ^  GGGQSS9@##bGGGGQ##@##bGS8QGb,GGGGGQGQGGGQQQSGGGGQ@##@@G9        //
//                                            bGSGGQbG##b$######S####Q#Q###bGb #G$#SbGbGGGGGG#@@$###SGGGGGGbb*GCCCC* )    o\* ]Q#bQ$QG@S#bGGS#######@##GGGQ#GGSGGGGQGGG$QQQSGGGG#@#$#Qd        //
//                                            GGGGGGG#@G#Q###G@S$#Q@#Q#Q##G#`,#G##GGGGbGGGGS##G#####GGGGGGGbbGGCooC^)b   ^CGk @#GQQ#bG@GQGGS#####bG#@###@GGSSGGSGGGGSSGGQQGGGGGG#GQ#8Sb        //
//                                            'C"@GWGGGGQG$G##8Q#@Q#@#SGG#^ sG$G@Gb#GGbGGGG@##b##@#GGGGGGG8`bGGoCOG;b#,   'C*W#G#GGG$#@##G9#######S@@###SGGGSGGSGGQGGQGGQQQGGGG####S#Qbp       //
//                                              '.!GGGbGGGGQQQ#GQGGGGGGW`;#S#$GG8#]GGGGSGGS###G###@GGGG8GG9.!GGCCjG*jjC     `!b@GGGG#####S#####Sb###@###@@GGGSGGGGGGGGGG$QGGGf@##$Q##GQp       //
//                                                 "<38WGGQ#bGGQGQQGGG#QSGGGGGGQ#L#GG$SGGQ###GSb###bGGS$GGSjGGGC;bCGb$  ^    @G@GGGG####b#####G@####@##bSSQGGGGGSGGQQGGSQQQGSS#Q#G####8b       //
//                                                      Tjj*"%SSSSSGGbGW*8Qk""|`,#GGGGQGQ###GG@G###bGGGGGGb@GGQCCCGfGL      jGG@QGG$#@@######G@G#b#S#@##@##QSSQGGGQQQGG#QQQGb@#G#S#####b       //
//                                                        `    ^^`              @bGG#GGG###GQ@GQ##bbGGGGGGbLGGCGGGjbGb      @bG#GGG8##@#####S@@#b@#$bG@#####QQGGGQQQQGSQQQ#Q#$##b###$#Qb       //
//                                                                              #GG#GQG###GG@G#b##bbGGGGGGb!GGG*  L /       #bGGSGGG #@####S###bQ###GG`@##@b#Q#QQQGGQSQQG$###$#G@##GG#S        //
//                                                                             jGGG$SG$##bG9###Q##G8GGGGGGbSGG~  !  `      .GbGbGGGb #@#######bG@#QbGb @$#b@b#@QSGGGQQQQ#8@###7W##bGGQb        //
//                                                                             f"j.SSG###GG#G#Q####QbGGGG@/!GG   b j       jGb9GGGG  #@#######GG###GG~ SG9GG###S#QSSGGG@GG##bb   GS#$@~        //
//                                                                               b$SQ$##GG@G##@###SQSSSGWb ?GC   b |       @Q@@GGGG !8@######$Q@#GGGG #GS@Qb$######Q#QS!SGGGGGb  @8#G@         //
//                                                                            { / SSQ@##G@G###$###$@SSGG@b **o   b |        j8$G$GG #G$GS###SbS##bGGb#GSG$Q@GG8####Q#N##QSS$###NS#S##8         //
//                                                                            | ~{SQQ$##@b###QQ###b$SQSSSb *C    L b         8$#@GGjQGGG###S9G##@GGG#GGGG$QQGNSG@###@##@#8#@Q###Q#####p        //
//                                                                            ~! #GQQQG@b###bS###@GQQQGGb|:*C    | .         @$Q8G8@QGb#####$9##bQGS###GG$QSG G$G8@##N$@##N###########b        //
//                                                                           . ~!GQQQG@b####GS##b@GbQQGGb!**C    j/         j@$b@Q2@GQQ####9G### GG####GGbQQ# $G8pG$@#################b        //
//                                                                           [! #GGQQ@G#####S@##G$#SGQGQbj***     `         !@QbG888#bQ###Gb@#@b{G####GG@GQQ~ QGQ8pGQGG$$$bbGGQ####N###        //
//                                                                           `b$GQQQ####Q##bQ#b#G$bSGQGQ~ b*                !##SGGQGG9S##G9G###b@####bGG$QQS  GGQS8GGGG$GGGQGS#####j###        //
//                                                                          {].QSGG########G$@#bG@GQGGGG :b*                !bGGGGGGG8b!GG$@#@Gb#####GQGbQQb  GGQQG8GGG$GGQ8#8#S###j###b       //
//                                                                          L~#GQQ@########G@@#GG@QQGGG# (b*           ^    {GGGGSGGG8 @GGb###G#####bGS@GGGb  GGQGGG@GG$GGSQGQG'##b####|       //
//                                                                          b$GGQQ#####S###S#@#GG#QGGGGb @**                @GGGGQGGG8.GGGN##b@#####GGG$GGGp  GGQGGGGbGSGGlQQGN #######j       //
//                                                                         /pQGQQGGS##b@##b@#@Gb@bQGGGGb b*                 GGGGGGGGGS#GG@###S#####GGGGbGGGb jGGSGGGGG8pGGGQQGGbQ###G$#@       //
//                                                                         bGGGSbQQ@##G@##G##8# @bSG$GGbj.*                ] GGGGGGGG$SGG$#S#######QGQ@GGGGb jGGGGGGGGGG@pGQQQG#8@QGQ$#@G      //
//                                                                         #GGQbQQG##b#@##$##b` @GQG$GGb|**               .` GGGGGGGGGQGS#Q####@##GQG@bGGGGb @GGGGGGGGGGGGNQQQGGGGG8QG$@G;}    //
//                                                                        @GGQ#%QQ@##NG###@##^  $QGGGGGb8**          ^    b  GGGGGGG@GGG@S###b####GGb@GG^GGb GGQGGGGGGGGQQG8pQGGGbGGGN#8bLC    //
//                                                                       !8GbO ]QQ@##@G#####b  !QQGGGGG~b*^              .   GGGQGGS8pG#####b {@#SGG |   SGb!GGQGGGGGGGjQQGSGQGSG QGGGbYWb     //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PARIN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
