
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Minear | The Legacy Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                   ##                                                                      //
//                                                                            m     @###Q       ##                                                           //
//                                                                                 ]#l@Q%m                @#m                                                //
//                                                                  #b             #GlG#p^@p             #####m                                              //
//                                                                              em#bQQQ8#  %m            '@##^                                               //
//                                                       #                     #bGGGGGGG@b  "#             "                                                 //
//                                                      @##_                  @bGGGGGGGG7#    @m                              %b                             //
//                                                       7                   @#""5555555b@Q    "#                                                            //
//                                          ]#                              @#GGGGGGGGGGGG#p    '@p                                                          //
//                                                               #         @#*sssssssssssS8#      7#          j#                                             //
//                                                                        ;#*GGGGGGGGGGGGGG@b      '@Q                         %#_                           //
//                                                         ,             ]#^GGGGGGGGGGGGGG@#.        %m             ###Q                                     //
//                                                       ,####,      ##m,#.G^^^^^^|||||||#b           ^@p ,s#     ;#b$@##                                    //
//                                                      ##G@b 7@m  ,#b^|5,^^^:*GGGGGGGG;#\              %#7@#@m ,#C755b@Q@m                                  //
//                                      ]#p           ;#b##@#   |@m#b%WWWWWWWWWWWWWWWCG||7775####        "##b 7##'*GGGlG# 7#,         ,#m        7\          //
//                                                  ,#GG###@#    /#`^^^^^^^^^^^^^^^^^^^^^^**Gs#\           7    @Q')eee###  %N        "##.                   //
//                                                 ##G####Q@#   ##j,,,,,,,,,,,,,,,QQQQQQQp*s#\                   "#p*GGGl@#  "@p                             //
//                                               ;#bQQQ#Q##|   #b  `````````....~~^^^^||`s#^                       @p*GGGG@b   ^^7#,                         //
//                         m               #m, ,#GGGGGQ#M`    #b                      .@#^                         j#||?||G@p      %m                        //
//                                       ,#bGG75GGGlQ#M.    ,#"_`^^^^^^^^^^^^^""""""\#M"                            '%#`GGG"#       7#  ,,m      ,           //
//                                     ,#C^755555GQ#O      ;#`_ _____             ,#M`                                "@Q*WW7#  ,,    %T^`7#     `           //
//                                    ##*GGGGGGGG{55555555## :mmmmmmmmmmmmmmmmmm,#M`                                    7#pGG757G@b        ^@p               //
//                                  ,#b,QQQQQQQQQQQQQQQSG#b          _  _ ____,#O                                        ^@QG,QQQ8#          @m              //
//                                 #b*GGGGGGGGGGGGGGGGGj#^              ___ ;#C                    ,                       7#p*GGl#           7#             //
//                               s#~:GGGGGGGGGy#7%###Qs#` ````````````````,#"             ,ae###W57"%N                      '@QGGG@b           ^#,           //
//                             ,#b.'7777777|;#C       ~                   j#    ,,em##W57|`"___ _____|@Q                      "#pG@#             @Q          //
//                            #M.^'^^*^^:G;#C """""""""""""""""""""""""""_ #W5"7^|      "7777777""""___7#                       @Q^#              %#         //
//                    s##W5777| WWWWWWM^,#C                                                             '%                       7##b              "#        //
//                  ;#|___         _'^,#C                                                                 _                        %Q                @Q      //
//                ;#T    __ _,,,_   ,#C    ##%%%#  ##WWW#p"#,  #"  ##Q   ##p  j#    ##p  ,##  #  ##,  @# @#WWWWb  ,##   j#WWWW#     "#,               %m     //
//               #"    '.~^,||``. ,#C      ##WWW#J #mmmm#b  %M#\  #Q @b  @b7@mj#    #b%##Mj#  #  # 7#p@# @####b  ;#,j#p j#mmm##"      %m               "#    //
//                          ___ ,#C        #Mmmm#C #b  "#p   #~ ,#^|||\# @b  "@#    #b  ` j#  #  #   "@# @#####p@#|||`@pj#_  %#        7#,                   //
//                     "77777 ,#M                                                                                                        %N                  //
//                          ,#M   WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                 "@p                //
//                          7`                                 #Q                                         #                                 7b               //
//                     ,mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm  \#w7  emmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm  ",@Q" smmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm           //
//                                        ,                  ",@W|_               #  b jp               ";@w"                  ,                             //
//                                       #]"Q                7,@%,"              ]b  `  #               ";@w7_               ,#@%,                           //
//                                      ",@% "               ^ #m.`              @_  b  @               `,@Q|_              ^.s@W `                          //
//                                     s\ #p^\                 ]_                b   `  ^b                @                 m^,#p"W                          //
//                                      #`] "p                                  @   jb   @                                  ,#`@ %,                          //
//                                     ` #{7m_"                                 #   jb   jb                                 `,O@"p                           //
//                                     "^ #p_`=             ,               ]###M########m###m               #              "_ #  "=                         //
//                                       "] *              #@7Q             #-       p       @p            ,b@7Q              "@^~                           //
//                                        ]              ;C ] ^%,          ]#       jb       j#          ,M` @  %p             @                             //
//                                                     s"  ,#W  ^%         #        jb        @p        5   #@@   7                                          //
//                                                       ,#^]~7m          @b                   #          #\ @ |W                                            //
//                                                     ,#|  @Q _"W        #          c         @b      ,#|  ,#p  ^%,                                         //
//                                                    7   ;M@C@   "_     @~         jb          @      `  ,#`@'%                                             //
//                                                      ,M, ]  |W       {M          jb          ^#      ,#"  @  |%                                           //
//                                                    ;M`  ,@#   ^%,    #           jb           @b   .M^   #@%   "%p                                        //
//                                                       ,#`]_7m       #~                         @p      #\ @ 7W                                            //
//                                                     ,M,  ]  _"W    @b             p            ^#   ,#|   @   ^%p                                         //
//                                                    7    ,##    '" ]#             jb             "# "`    #@@     ^                                        //
//                                                        #"]~7Q    ,#              jb              \b    ;" @ 7p                                            //
//                                                       .  ]       #`              jb               @p      @                                               //
//                                                          ]      #"                                 @p     @                                               //
//                                                          ]     #^                                   @p    8                                               //
//                                                               #"                 jb                  @                                                    //
//                                                              ^|                  jb                   7                                                   //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BM is ERC721Creator {
    constructor() ERC721Creator("Bryan Minear | The Legacy Art Collection", "BM") {}
}
