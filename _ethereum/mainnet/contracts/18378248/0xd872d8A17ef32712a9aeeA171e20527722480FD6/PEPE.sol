// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Planet Pepe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                              ::---:--------::                                              //
//                                       ::::::-=+*##%%%%%%##*+=------:                                       //
//                                   ::::-*######%%%%%%%%%%%%@@@@@@@%*----:                                   //
//                               ::::-+***####%*---*%%%%++%%%%%%%%%@@@@@@%=--:                                //
//                            ::::-+*#+==*%##%%==--=%%%%%%%%%@%*++#%@%%@@@@@@*--::                            //
//                          :::-=+*==---::=@%%%%%%%%%%%%%%%%@#----:-=#@%%+--*@@@+-::                          //
//                        :::-==+*++===---+@%%%%%%%%%*-=%%%%%%====----%%%%%*+%%@@@%-::                        //
//                      :::===++*#**++=--#%#%%%%%%%%%%%%%%%%%%@#*++=-=%%%%%%%%%%%%@@@=::                      //
//                    .::====++**%%#*#%@%#####+=--------=+#%%%%%%@@%@@%%%%%*+=-----==*%-::                    //
//                   ::+===++++******#####+-:::=#@@@@@@%+--:-+##########+-::-=*@@@@%*=-:-:::                  //
//                 ::-+===-::=*******##+-::=%##%%%%%%%%%%%@@*-:=*####*=::-####%%%%%%%%@@@=:::                 //
//                ::+=-=+==-:+********-.:+**##%%#*+=====+*#%%@#::=*#=:.-**##%%%*+======+#%@*::                //
//               ::*=-==##***+******=:.-+**##+=-:::--=--:::-=+%@+.-=:.=+**##+=-::-====-::-=#@-::              //
//              :-+--===++++*+-::**=.:=++**=-::+@@@@@@@@@@@*::-=%*.:.-++**+=::+@@@@@@@@@@*::=#=::             //
//            :::+--===++++++*+=-*+..-=+++-..#@@@@=-::----+@@%:.-*=.:=++*=::*@@@@=-::::-=@@*::*:::            //
//            ::*=-==+*#%#*++*****:.-==+=:.-@@@@=-@@@@@#::::-@@+.:+.-==+=:.%@@@%:%@@@@::::=@%::#::            //
//           .:*=--+-::::--*#****+::-===:.=%@@@-:#@@@@@@-:::::%@*.-.:-==:.+@@@%::@@@@@-:::::@*.=:::           //
//          ..=+--=-::::...-=%***=:-----.-%@@@#..+@@@@@@:.=@*.-@@=.::---..%@@@#..:*#*-..:%+.%@:..:::          //
//          .-*--=--::::::..-****+:----:.+%@@@*...:+#*-...-%+..@@#..:---.:%@@@#.............#@+..+::          //
//         ..+=--+=-----:::.-+****-----:.+#@@@#................@@#..----..#@@@@:............@@=.:##::         //
//         .:*---**===---:::-*****=-----.=#%@@@:..............=@@*.-####-.-#@@@@:..........%%#..+%@::         //
//        ..=+---**#+==--::-=*++***-----..##%@@@-............=@@%-.#%%%%%=.=#%@@@%-.....:*@%#-.-=+#+:.        //
//        ..*=----*###+====*++++=--------.:###%@@%-........-%@%#+.=%%%%%%@*.:*#%%@@@@@@@@%##:.=#%#=*:.        //
//        ..+-:----=*###**++++-+#%@@@%#+--..+###%@@@@%##%@@@%##=.=%@%%%%%%%@=.:+#########*-.-*##%##+::        //
//        ..+--:.---=====+++==**#%#######+-:..+#*###%%%%%####+..*@%%%%%%%%%%%@#-..:::::..:+###*==+**:.        //
//        .:+-==----======++++***+=====*##*=-:...=########+...+%@%%%%=:=%%#.:+%%@@@%%%%%@%##*=:..:-+:.        //
//        .:+-::----=======++++=:......-=+*##+---:.......:-*%@%%%%%%%#..=%%%:.#%##########**=...=+==:.        //
//        ..*-:::----======+++===-.:.:-..:==*****+=+*#%%%%#####%%%%%%%%%%%%%%##########***+-....=*==:.        //
//        ..*=:::---:::-====++++#+..:.-==..:-=+****#################################****+=:.:...+*==::        //
//        ..++-::--:::..:====++++#+..-.:-==...-===*******########################****+=-..:=....*+==..        //
//        :.:*-::=--:::..-====++++#*..--..-===...:-====+********###########*****+===-...-==..:.+*==:..        //
//         ..+=::++=--:::======+++++#=..--:.:-===:.....:-========++++++========-:...:-==-..-..+#=-=..         //
//          .-*-::***=--+=======+++++*#-..:--:..:-===-::.........::::::........:--===-..:-:.:**====..         //
//          ..++-:::=++-----==-::::-=++*#+:..:----:..:--======-----------=======-:..:---:.:+#+=-=+..          //
//           .:#=::::::------:......:-++++*#+-...:--====-:....:::::::::::.....:-===--:..-*#+==--*:.           //
//           :.:*=::-::::--=-:::.....:-==++++*#*+-....:----====++++++++++====---:...:=*#*+===--*-..           //
//            ..-*=:=::::::+=-:::::...:===+++++++*%#*+=........:::::::::........=+*%*++====---*=..            //
//             :.-*=:::::::-**=--:::.:-==-::*==++++++++#%##***+===----==+***##%*+++======----*+..             //
//              ..-#=-:::::::*#*+----====+=-========+++++++++++++++++++++++++++===-...:----=*-..              //
//               ...*+-:::::::-=++++=----===============++++++++++++++++++=======:.::-----+#:..               //
//                 ..+*=-::.::::::::--------=-::::::-================:....-======-:-=++==*+...                //
//                  ..:#*=-=::::::::::::---=::.......:-=====:..:====..:::::-=----***#=-+#:..                  //
//                    ..-#+=-:::::==-:::::-::.........:-====----===-:::--==+----::::-+#=..                    //
//                     ...=#+=-::::++=::::--::::::::...:----=**=---=+*****+:-:-:::-+#=..:                     //
//                       :..-**+=-::::::::-==::::::::.::------------:-==:::-:---=+*=...                       //
//                         :..:+#*=--::::::=**+-:::::---::::::::::::::::::::==+**:..:                         //
//                            ...:+#*+=-:::::+#***+=+=::::::::::::-:::::--=+**:...                            //
//                               ....-#**+=--::::::::::::::::::::::--=+*##=....                               //
//                                   ....:+#***+===----------===++**#+:....                                   //
//                                       :......:-=+********++=:......:                                       //
//                                              :..............:                                              //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Planet Pepe", "PEPE") {}
}
