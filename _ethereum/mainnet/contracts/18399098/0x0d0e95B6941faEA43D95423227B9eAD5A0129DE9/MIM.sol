// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Muse in the Maze
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                            :-==+***##***+=-:.                                                 //
//                                       .-+#%%%%%%%%%%%%%%%%%%%#+-.                                             //
//                                     -*%%%%%%%%%%%%%%%%%%%%%%%%%%%*:                                           //
//                                   -#%%%%%%%%%%#*++=====+**%%%%%%%%%#-                                         //
//                                 :#%%%%%%%%*=:.             .:=*%%%%%%*.                                       //
//                                -%%%%%%%*-.            :-:      .-#%%%%%-                                      //
//                               =%%%%%%*:            .=#%%%%+.      -#%%%%+                                     //
//                              -%%%%%%=             :%%%%%%%%%-      .%%%%%+                                    //
//                             :%%%%%%-              *%%%%%%%%%#       =%%%%%=                                   //
//                             *%%%%%=               :#%%%%%%%%-       :%%%%%%:                                  //
//                            -%%%%%#                  -*%%%#=.        :%%%%%%#                                  //
//                            *%%%%%-                   =#%%=.         -%%%%%%%=                                 //
//                           .%%%%%%:                   %%%%%.         =%%%%%%%%.                                //
//                           :%%%%%%.                   %%%%%.         +%%%%%%%%=                                //
//                           :%%%%%%.                   .%%%-          +%%#%%%%%%                                //
//                           :%%%%%%-                  .-%%%=.         =%%==%%%%%-                               //
//                            %%%%%%+                  :+%%%*:         .%%-.%%%%%=                               //
//                            +%%%%%%.                 .+%%%*:          =%+ =%%%%=                               //
//                            .#%%%%%*                 #%%%%%%           =%#+%%%%-                               //
//                             :%%%%%%*.               %%%%%%%.           :#%%%%#                                //
//                              -%%%%%%#-              *%%%%%%              :*#=                                 //
//                               :#%%%%%%*-            -%%%%%=                                                   //
//                                .+%%%%%%%%+-.         *%%%#                                                    //
//                                  .+%%%%%%%%%%*+=-:.  =%%%+                                                    //
//                                    .=*%%%%%%%%%%%%%%%%%%%%%=:..                                               //
//                                       .-+#%%%%%%%%%%%%%%%%%%%%%%#*+-:                                         //
//                                           .:=+*#%%%%%%%%%%%%%%%%%%%%%%*=.                                     //
//                                                  .:-#%%%%%%##%%%%%%%%%%%%#=.                                  //
//                                                    :%%%%%%%-  .:-=*#%%%%%%%%=                                 //
//                                                    -%%%%%%%=        .=#%%%%%%+                                //
//                                                    .%%%%%%%:           -#%%%%%-                               //
//                                                     -%%%%%=             .#%%%%+                               //
//                                                      %%%%%.              -%%%%+                               //
//                                                     -%%%%%=              :%%%%-                               //
//                                                     .%%%%%:              +%%%#                                //
//                                                      %%%%%.             -%%%%:                                //
//                                                    :+%%%%%*-           -%%%%-                                 //
//                                           :-=-.    =%%%%%%%+     :==:.+%%%%:                                  //
//                                          +%%%%%==*=-#%%%%%#--*+=#%%%%%%%%*.                                   //
//                                       :#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+                                     //
//                                         :*%%%%#::=:-=%%%%%+-:--:%%%%%#-.                                      //
//                                           :=+=.     .%%%%%-  .=#%%%*-                                         //
//                                                     .%%%%%:.+%%%#=.                                           //
//                                                     .%%%%%#%%%*-                                              //
//                                                      %%%%%%%+.                                                //
//                                                      %%%%%=.                                                  //
//                                                     +%%%%%.                                                   //
//                                                   .#%%%%%%                                                    //
//                                                  .#%#%%%%%                                                    //
//                                                  *%%:#%%%#                                                    //
//                                                 .%%+ #%%%#                                                    //
//                                                 :%%- *%%%#                                                    //
//                                                 .%%+ *%%%*                                                    //
//                                                  +%%:*%%%*                                                    //
//                                                   *%##%%%+                                                    //
//                                                    +%%%%%+                                                    //
//                                                     -#%%%+                                                    //
//                                                      +%%%#=.                                                  //
//                                                      =%%%#%%*:                                                //
//                                                      =%%%=.=#%#-                                              //
//                                                      =%%%-   :*%#.                                            //
//                                                      -%%%-     -%#.                                           //
//                                                      -%%%:      =%-                                           //
//                                                      -%%%:      -%=                                           //
//                                                      :%%%:      +%-                                           //
//                                                      :%%%.     .%#                                            //
//                                                      :%%%.   .=%#.                                            //
//                                                      :%%%=+*#%#=                                              //
//                                                   -*%%%%%+==-.                                                //
//                                                 .##-..%%%                                                     //
//                                                 *#.  .%%#                                                     //
//                                                .%=    %%#                                                     //
//                                                .%=    %%#                                                     //
//                                                 =%=.  %%*                                                     //
//                                                  :*%*+%%*                                                     //
//                                                     :-%%%#+:                                                  //
//                                                       #%+.-*#-                                                //
//                                                       #%+   -%=                                               //
//                                                       *%=    -%                                               //
//                                                       *%=    +#                                               //
//                                                       *%-  :*#:                                               //
//                                                       *%+=#*-                                                 //
//                                                       *%*:                                                    //
//                                                     -##%:                                                     //
//                                                    +*.+%:                                                     //
//                                                   *+  =%:                                                     //
//                                                  =#   =%.                                                     //
//                                                  #-   =%.                                                     //
//                                                 :%    -%                                                      //
//                                                 -#    -%                                                      //
//                                                 :#    -%                                                      //
//                                                  #.   -#                                                      //
//                                                  -=   :#                                                      //
//                                                   =:  :*                                                      //
//                                                    =: :*                                                      //
//                                                     :--*                                                      //
//                                                       -*-.                                                    //
//                                                       .+ :--:::..                                             //
//                                                       .=                                                      //
//                                                        =                                                      //
//                                                        =                                                      //
//                                                        -                                                      //
//                                                        :                                                      //
//                                                        :                                                      //
//                                                        .                                                      //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIM is ERC721Creator {
    constructor() ERC721Creator("Muse in the Maze", "MIM") {}
}
