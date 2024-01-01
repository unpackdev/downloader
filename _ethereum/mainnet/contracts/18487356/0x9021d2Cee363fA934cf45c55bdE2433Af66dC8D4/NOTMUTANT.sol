// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOT MUTANT PUNKS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//    THESE ARE DEFINITELY NOT MUTANT PUNKS MARK                                                                                                                                  //
//                                                                                                                                                                                //
//                           '*|||||||||l}ll}}ll}t                               }]*\;;\+=11?lilllll})||||||||*`          }illlll}}=                                              //
//                           '*|||||||||}lll}}ll}t                              '+;::::---:;;|+=1?il})||||||||*`          }illlll}}=                                              //
//                           '*|||||||||llll}}ll}t                           ':*|;;;;::::::::;;|||*)1+\|||||||*`          }ll}lll}}=                                              //
//                           '*|||||||||llll}}lllt                         -*)))))=)*|**+**+**===)=))*;;;|||||*`          }illlll}}=                                              //
//                           '*|||||||\|l}lll}ll}t                      `|)=)1ll1]>=)=))==1>==>>]>>1i?]==*;\||*`          }llllll}}=                                              //
//                           '*|||||||\|}ll}l}lllt                    .*?tr}}}tr}i1]=)+=)]111]]111illlliii]|;|+`          }ll}l}l}l=                                              //
//                  .'''''''',}i????????uu333u33uL`                 .|ilrrvvttrtt}l]==]]1ill?ili?ir}ttvvttl=]=?.          u3u33333ot                                              //
//                 `--,,-,-,";o3333cc33chZTZZZZZZP^               .|1rttttc3cItvt}}l1111>*)++==)1}trtr}t}}r}?1}:         .ahhZZhhhhL          ..........`                         //
//                 `-,,----,_;o333cc3ccchTTZZZZZZP^             `*tcIt}}vc3cvvvccLooo&a&n3ccuouLcri?>1?1]???1i?l=~       .aZhZZZZhho          ..........`                         //
//                 `--,----,";o3333c333chZZZhZhhZP^            "toIv}tuooLol}t>;;;+==):-"~-:--:)*)]rrl1i}}li1?lttr*'     .aZhZZhZhho          ..........`                         //
//                 `--",---,";o333cc33cchZZZZZZZhP^           |cuuvtro&YoY&]]1;^^~:::-^^^`  `'''    *>=1}r}aoIvccvti^    .aThZZZZZZo          ..........`                         //
//                            .'.'''''''---------:           :vcvvIvcLLclr=``'`   '..-}tt;^^:IIIr}l=```````n&&utttrvr     ---------^                                              //
//                                                           }tcccu3o3a3|*:```````...-??i;,,:rr}}li=.``````tvvi))>YVu*                                                            //
//                                                         ^tcuu3ooLPOO*   `''^----::-~~^-:::-::----::::---...`   lVYVt                                                           //
//                                                        -33o333oonODD*   ...~---::::---:::::::----:---,,,```    l0&YO0'                                                         //
//                                                       iooocIt3uoLOOO*   ^^^,::::;;;::::::::::::::---_^^^       laat:=&3:                                                       //
//                                                      )uvvvrtYY3ooaaT;      `.''....^^^.'''`'`````              >YYt:--1&)                                                      //
//                                                     ]vvcItohY}uooV&0:       ` ``````''`                        )oot:-^.-Tv.                                                    //
//                                                    lvvcccYtti>>>====+\\|*++*++*|*|\:::|=)+;;;:::::::::::::::;;;1}}?-^^^.|Tt'                                                   //
//                                                  ^IIrtoTV}l}}>))))))=>=>1]]]>>==)=)|||=?i]***\;:;|||****+++)==>i}l}-^^^.`;a]                                                   //
//                                                 :tlrIo0};}+))=]]1l}}1+**+**|;;\|||)l}}}}}=::::::;|||)111}rr1)))tcco:`''^``}0:                                                  //
//                                               .:1ivcnc+|]t*+)=>>]ill]++***|****|**)l}}}rt1:::;;;\**+)]>1Ivvl)))v3cu|```. `_&I.                                                 //
//                                      ........-1Io&0l**+*=i||\)===1??>))+;;;)ii?=)+=ilitccr+*+)))=>]]>===3oot=)=cnLu+```` ` >a)..`                                              //
//                            `         .....`,loVv=\;|;:::=1;\:||||\||;:::-:::;\\::::---1ccl;;;:::::;;;::\=1?\---lvvr)' ``   ^Zv,.`                                              //
//                                      .....\cc?;-::----,:++;;:;;;;:::-,,-,-------__^.'`+u3i:---"",------:;|*-`'')}}]:^   ``  un:.`                                              //
//                            `         ...,1;.^--,,,_~,,-:+)))+:_~_",-"^~^....^^^...`   :cv>-_""_~_~~~_"--*=>;~~~```.++;. `   ia;.`                                              //
//                            ``````````~^"1+."--^..^^^^"-:;:==):^^~",-,~~^''.'''''''    ,}}+-_",,,-__",--:*==;"_^   `111.     =T*~'                                              //
//                            ----,,----;;r}^~,^.```^^..^_*;:::;)==)|||;::::::               ***:--::::)}}}          .oLL_     )a1\:                                              //
//                            ----------\=3-``^..'`''_...:;-:**|)1?1)+)|:::;;;               +));::::;;=ttr          .Y&V_     >&>|:                                              //
//                            ----------;1}  _-``````..^^;:-::;:+}}l===*:::;;;               ;;;:------\r}}          ^Zhh-     to+|:                                              //
//                            ----------:1] '-_`````''.^_-_,-:--)vttrrr:   ```               '..```````.:::```    ,::)&&&-    ^0I|\:                                              //
//                            ----------:?\ `-.`````''`.,..-:::;1cvv3uu~       ...`   ```               `'''''`  `133uLLn~    lai|\:                                              //
//                            ----------;}: `,.` `'`````~.-||;|:=cccuuu-   `'`berkberkberk-             ````'..````vaT}^"^`   ;DY=||:                                             //
//                            ----------;l- `^`` `.``'''',|||*|-*3ccuoo:   ~_berkberkberk;       ``````````'..````cOO] `     >PI|||:                                              //
//                            ----------:1:  '``  ```'.``.-:::-^|ooucc3;  `--,----_^^.```           `'''...```````cOP> ` ``  na1;\|:                                              //
//                            ----------;1*  ```  ```'....---^'`|LLo33u|```---~...```               `''....```````cOO]   `  -Oc);\|:                                              //
//                            ----------\*r   ````     .`._..'`.+VV&Zhh1..."""^...`                `...^~__```````oXX)      >Pc*;;\:                                              //
//                                      --?`  `` `      `......^)YnYaaa>...,,,^...```            ```...^^~^``````'ngd+     -DO0I=;. --:::::::-                                    //
//                                      -->-  .``      ``...``..|3333c3*..^:::-~~^.''`          `'''.......````...&EE=     DDPaaa00V3c}=+|\;|:                                    //
//                                    `-}uVc` `````     `...```.*u333uu*''.^^^_---^..'   ```    ````'''```````.^~_aEm=    tOhaaa0V&aaYnLncl]):                                    //
//                                 -+}vuonna:           `.'`````*uu33uu*''`'''^:--_^^.``````     ```'''` ``'..^,--amm=   -bha0aaZaaTaanVVVnnoc:                                   //
//                              `:vItc3n&a0aV`         `..`  ```*LooZhh?^^^^^^^""_~^^^...'''``````'`       _""-:::TO&;  :POhZZaahhZaaa0aTha&&0Yn3]^                               //
//                            -]3nVYoVV0ThZTho`   `     `'`    .]YLnOOO}__~__~~~^^^^^^......'```'''`       ---::::~    "@PPOOOZZTaZhhhZha0VVaZTaaaaY1.                            //
//                         ,1tc3LoLVLnn0hhhOPP3   ``    `      -}00&aaar:::^^^^^.................'.`    ```;\\\:,'     0OPOOOOZTTaZhhhhPhZaVY&&a&V&aaVol-                         //
//                      :rcoccuunYYV0V0ThhODOPO|     `  `      "]Ir}}}t?+);^^......''......^....````    ''.|*+'      'Y@PDOOOhPhhhhPPPPPPPhZTaa0YY&&&000&o>`                      //
//                    +3Y&Y&YYLV0&0&&&TZPPP@OOO@r              ^^.^^` `}a0I''`````````'''^__^...       `-:-}c]    `;TX@DDOPPOhPOOhhThhPPhhPPPhhTZTY&VV00aTTao`                    //
//                   tVL&a0YYYV000&ahhhTOOD@ODbSX1             .`   ` ^ca0r~^^.```````''...^:}l}*:::`  ^|||rv. ^?PXXXb@ODPhPhOPPOOhZThhThhhhhPOPhaVV0000aTPOTY-                   //
//                  vaaaZZT&&a0aTa0aZO@OSOOODbddXX:            ``     _l0Ou:::^````````'''..|HHqZLYv' `->===\|&dXddbbb@DSDOhPOhPPPOhhhZhhhhhhOOOPh0000ahOOOOha&)                  //
//                'oaTZZZTa0TTaTaaTThDXX@DDSbXXbbgS.            `    `-=thYt\--;::.```   :?iIYVV0TZu^.'-*;;_=O@dbXdXddSbSSShhOOOhhOhZZhhhhhZhOD@OOPaaaaPODPZT000o:                //
//               :0hTTTaaTTTTaZTaaaODDS@@@SbSXXXdddo                 ^,=|IZTL*;1]=^```   |VVLvvv&hho"^-:::-`|SDSdXXXXb@bdXSOOPPPPPhhPhPhhhhhhPO@DDPhTTPDDOTZTaaaVo3-              //
//              l0PhZTZZZhPhZaa0aaaODS@bdXbbbdXbbbXd\                ^-}+-ohh&tOOOYoLv\;;vZZo)=)LOhv:-------TdbbdXXXdbbddX@PhOODOOPOPhPPPhZhhOO@O@D@ZZZOhTaZTTThhZ&u.             //
//            ~oVZOPhZahZhPPZTaTaThDSD@XdXbbbXXddddbv               `.~1\ ^vhPYPPhnu3};;;}ooI*+*oOo*,___"-^:D@bbbS@bXSXdddXDPhhOPPhPOhZhOhhPhhO@DD@SDPPDOZZhhhPOOOh0n_            //
//           :aTTZPhTaahhPOOO@DDODSSSSbbSXXXXbXddbdK@`                `+|   *aY0Y?:.`        ``'-;--,__~:i uXSXdXbbbbSXdggXSOPPOPOOOOOOOOOOPOO@@@@S@DOOOPhhOOODSDOOPTV^           //
//          -TZhPhODZaZOS@DDDbD@@XSS@SXdddddXbSXgdXdXa` .'`           ^)|     *nTh0I:^         `'^^_~-\th- bXbbdKdXXXbddgddSOhhPOODODOOODOD@@DbD@bS@@hhS@@@DDSXS@DOPZa&:          //
//          cahhOOOOhDXbbbbbbXSbbSbbbdXXgddgddddXXdgdS]':.`           :):`     `*naPTt:.     `'..~:=I0OOo 3bd@dgdXXXXdggdddb@DOhOOOOOOD@@@@@bdXS@bS@@OPSSS@@bbS@DOPOPZa0;         //
//         IaOOOOP@@@DXbXdXbSXbSbbddgXbdgggddddggdgdgdXa*             ,=|         |YZZ&v;~'  '~;>c&hPho) :bgKgdddXXXbbggdXddbSDOOOOP@DD@SSSbbdSSb@bSS@DSbbXSbXDDDOOhPOPha-        //
//        cTZhhOOOSbbbXddXddbbSbbXXdddXdgdgddddddXgdggXbO`            `|).          ;YaZ0oi+}c&hZhac],` `ZXggddKdXddXXggXddXb@@DOOPObS@b@bSbbbbbSbXbSD@OSbXXdbb@OOOOhOOPZL        //
//      ^LPhPPOODDD@SbbXggdgXbXXdddggddddXdddgggdgggddddda.            :*~            iaa0aTZhZo>-`  ` 'vXbdXdgdddXXXgddggXXXSDOOOODbbb@SbbXSSSbbbSbb@S@XgbXddbSDD@OhOOOPOl       //
//     -nTPhhDDSD@SSS@bbXdddgggdggggggdgKdgKgdgdddgdggKggg@;           ~=-             :n0a&t;'        |SdgdddgddgdXbddXddXddb@DDOPOObSbbbbXbXbS@S@S@bX@SdXdddSSDD@D@OOODPh+      //
//    :&0hhPO@ODD@D@bbbXXdddgggdXdggKdddgggggdggdgdXgggKgKgdt           |-`             .i:`          `oggddggggggXXbdgdggddXbbb@@DOOS@bdddddXXSbSbbXXXSSKKKggS@S@DODPhOPPPh)     //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                ██████  ███████ ██████  ██   ██                                                                                 //
//                                                                ██   ██ ██      ██   ██ ██  ██                                                                                  //
//                                                                ██████  █████   ██████  █████                                                                                   //
//                                                                ██   ██ ██      ██   ██ ██  ██                                                                                  //
//                                                                ██████  ███████ ██   ██ ██   ██                                                                                 //
//                                                                                                                                                                                //
//                                                                     █████  ██   ██  █████                                                                                      //
//                                                                    ██   ██ ██  ██  ██   ██                                                                                     //
//                                                                    ███████ █████   ███████                                                                                     //
//                                                                    ██   ██ ██  ██  ██   ██                                                                                     //
//                                                                    ██   ██ ██   ██ ██   ██                                                                                     //
//                                                                                                                                                                                //
//                                ██████  ██████  ██ ███    ██  ██████ ███████ ███████ ███████      ██████  █████  ███    ███ ███████ ██                                          //
//                                ██   ██ ██   ██ ██ ████   ██ ██      ██      ██      ██          ██      ██   ██ ████  ████ ██      ██                                          //
//                                ██████  ██████  ██ ██ ██  ██ ██      █████   ███████ ███████     ██      ███████ ██ ████ ██ █████   ██                                          //
//                                ██      ██   ██ ██ ██  ██ ██ ██      ██           ██      ██     ██      ██   ██ ██  ██  ██ ██      ██                                          //
//                                ██      ██   ██ ██ ██   ████  ██████ ███████ ███████ ███████      ██████ ██   ██ ██      ██ ███████ ███████                                     //
//                                                                                                                                                                                //
//                                                                     █████  ██   ██  █████                                                                                      //
//                                                                    ██   ██ ██  ██  ██   ██                                                                                     //
//                                                                    ███████ █████   ███████                                                                                     //
//                                                                    ██   ██ ██  ██  ██   ██                                                                                     //
//                                                                    ██   ██ ██   ██ ██   ██                                                                                     //
//                                                                                                                                                                                //
//                                ██████  ██    ██ ███████ ██████  ██████  ██ ██      ██       █████      ██████  ██ ███    ███ ██████                                            //
//                               ██       ██    ██ ██      ██   ██ ██   ██ ██ ██      ██      ██   ██     ██   ██ ██ ████  ████ ██   ██                                           //
//                               ██   ███ ██    ██ █████   ██████  ██████  ██ ██      ██      ███████     ██████  ██ ██ ████ ██ ██████                                            //
//                               ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██      ██      ██   ██     ██      ██ ██  ██  ██ ██                                                //
//                                ██████   ██████  ███████ ██   ██ ██   ██ ██ ███████ ███████ ██   ██     ██      ██ ██      ██ ██                                                //
//                                                                                                                                                                                //
//                              ███    ███ ██ ███    ██ ██  ██████  ███    ██     ██████   █████  ███████ ████████  █████  ██████  ██████                                         //
//                              ████  ████ ██ ████   ██ ██ ██    ██ ████   ██     ██   ██ ██   ██ ██         ██    ██   ██ ██   ██ ██   ██                                        //
//                              ██ ████ ██ ██ ██ ██  ██ ██ ██    ██ ██ ██  ██     ██████  ███████ ███████    ██    ███████ ██████  ██   ██                                        //
//                              ██  ██  ██ ██ ██  ██ ██ ██ ██    ██ ██  ██ ██     ██   ██ ██   ██      ██    ██    ██   ██ ██   ██ ██   ██                                        //
//                              ██      ██ ██ ██   ████ ██  ██████  ██   ████     ██████  ██   ██ ███████    ██    ██   ██ ██   ██ ██████                                         //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOTMUTANT is ERC721Creator {
    constructor() ERC721Creator("NOT MUTANT PUNKS", "NOTMUTANT") {}
}
