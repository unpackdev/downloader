
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bad Money
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                                                                      %@    //
//    @@                                             ++==                                     %@    //
//    @@                                            %@%#@=                                    %@    //
//    @@                                           -%#@%+             :--.                    %@    //
//    @@                                         -%#.                %@*-@*                   %@    //
//    @@                                       :%@-                 :@@@@@%                   %@    //
//    @@                                     .:@%.                .+@@#**=                    %@    //
//    @@                                   .*+#@.               :***%-                        %@    //
//    @@                                 .*@@+#@.            :+%*-+#                          %@    //
//    @@                              :=-##@@@=#@*=:....:-+*#**##+#                           %@    //
//    @@                             =@@%*######@@@@@@@@####@@@@-@                            %@    //
//    @@                            +###%@##@@@*####@@@@%%@@@@@*#*                            %@    //
//    @@                          :****######%@@#+*+@@*%%:*#@@@+%*                      @=+=  %@    //
//    @@                        :****#####%@@%####@@@@*@@@@*@@@#*@                    @@@%@@  %@    //
//    @@                      =@@@@@@@@@@@#####@@@***%@#%%#@@@@@=%#                 -%@@@@%   %@    //
//    @@                    =%*=+++**##%@@@@@@@#**#@@#**@@@@@*#*%+#%-            :+@@@=       %@    //
//    @@                   **-%@@@@@@@@@@@@@@@@@@@%**#@@**#@@*#@+%#+#%=:     .-+%**@%.        %@    //
//    @@                  -@#@@@@@#*+==----=+*#%@@@@@%**@@%+*@@@@+@@#+**#####***=+@#          %@    //
//    @@               .=%@@@#=:                 =#@@@@@*+%@%+*@@#*+**#@%###%@@#*@#           %@    //
//    @@             :*@@@*-            :@%*=      .+@@@@@#+#@%+#@#***%@@@@@@@%=@#            %@    //
//    @@           .#@@@=       .       %@@@-  *%*=.  =%@@@@#+%@#+%@@@@##+#@@@=@%             %@    //
//    @@          =@@@=         %@@%#+-*@@@*  =@@@#     =%@@@@*+@@**@@*@@*@+@*#@:             %@    //
//    @@         #@@#.          *#@@@@@@@@@+-:@@@@.       =@@@@@+#@%=@@*%@##@-@*         @+#  %@    //
//    @@        #@@+               @@@@@@@@@@@@@@*.        .*@@@@**@@=%@@@@@@=@:       :@@@@  %@    //
//    @@       #@@+               -@@@@@@*=*%@@@@@@%+:       -@@@@#=@@+#@@**%=@      :#%-     %@    //
//    @@      =@@#               .@@@@@@%     .=#@@@@@#.       #@@@@=@@+#+*%+-@+.:-+%*-       %@    //
//    @@      @@@.               #@@@@@@:        =@@@@@@        *@@@@=@@=@@@+%+*#**+.         %@    //
//    @@     -@@#               =@@@@@@=         +@@@@@@.       :@@@@%+@@=@+##@@@%=           %@    //
//    @@   .-#@@=              :@@@@@@@%#+-:   .=@@@@@@#         @@@@@+#@+%+*+@%=             %@    //
//    @@-*@@@@@@-              %@@@@@@@@@@@@@@@@@@@@@@*          %@@@@@-@%+@@%=               %@    //
//    @@@@@@@@@@=             *@@@@@@- .-+*@@@@@@@*+-            @@@@@@=@%+%=                 %@    //
//    @@@@@@@@@@*            -@@@@@@+       :+@@@@%:            .@@@#@@+%=:                   %@    //
//    @@@@@@@@@@@       ++=:-@@@@@@%          +@@@@@=           +@@**@@--                     %@    //
//    @@@@@@@%#@@*     -@@@@@@@@@@@:          #@@@@@%          .@@@:@@=                       %@    //
//    @@@@@@@-#%@@=     :=*#@@@@@@@%*=:.    .*@@@@@@*          %@@%%=                         %@    //
//    @@@@@%%%+#@@@=         *@@@@@@@@@@@%%%@@@@@@@%         .%@@*:                           %@    //
//    @@@@@#+*+%.%@@*       :@@@@. -@@@@@@@@@@@@@@+         :%@@=                             %@    //
//    @@@@@=#-@   *@@%-     %@@@:  *@@@+ .:-===-:          *@@@#.                             %@    //
//    @@@@%%@:%    :%@@%-   .-+=  -@@@%                  +@@@@@@@@%#=.                        %@    //
//    @@@@#=**#      =%@@%=.      :=+#:               :*@@@@@@@@@@@@@@*:                      %@    //
//    @@@@**=%-        :*@@@%+-.                  :=*@@@@@@@@@@@@@@@@@@@@#=:                  %@    //
//    @@@@%@*++    =#+:   -*%@@@@#+=--::..::-=+*%@@@@@%*=%@@@@@@@@@@@@@@@@@@@#-               %@    //
//    @@@@=#=@#     .+@%+:   .-+#%@@@@@@@@@@@@@@@@@@@@*###@@@@@@@@@@@@@@@@@@@@@@+             %@    //
//    @@@@=%=@@%=      -#@@#+-:.    .:-=+#%@@@@@@@@@@@#+*#@@@@@@@@@@@@@@@@@@@@@@@@=.          %@    //
//    @@@%@@+#@@@@#+:    .+%@@@@@@%%@@@@@@@@@@@@@@@@@@#++#@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:      %@    //
//    @@@@+#=@@@@@@@@@#+:    :=*#%@@@@%@@@@@@@@@@@@@@*+@*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-  %@    //
//    @@@@-%=@@: :=*%@@@@@%*+=:.       =@@@@@@@@@@@@@=%+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@    //
//    @@@@##+#@#     .-+#@@@@@@@@@%%%%###@@@@@%%#*##**=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@%%**@@%.         :-=+**+=-::....      :*#+@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@+#-@@@@@%*+-:..              .-+**##%@@@=#=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@**=%@@@@@@@@@@@@@@%%#######%@@@@@@@@@@+**=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract BADM is ERC721Creator {
    constructor() ERC721Creator("Bad Money", "BADM") {}
}
