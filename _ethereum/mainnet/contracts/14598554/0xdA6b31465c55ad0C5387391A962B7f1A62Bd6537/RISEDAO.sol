
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RiseDAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@@@@##%%%%%##@@@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@@#%:,,..........,,:+%#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@#%:,..                 ..,+#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@%:..                         .,+#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@#+,.                               .:#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM@#+.                                    .:#@MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMM@+,.                                       .:#MMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM@#,.                                           .+@MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM@+.                                              .:#MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM#:.                                                 ,%@MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM@%,                                                    .+@MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM@%.                                                      .:@MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM@+.                                                         :@MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM@+.                                                           :@MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM@+.                                                             ,@MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM%.                                                               :@MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM#.                                                                .+@MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM#,                                                                  .%MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM@:                                                                    ,#MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM%.                                                                     :@MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM#.                                                                      .+MMMMMMMMMMMMM    //
//    MMMMMMMMMMMM@:                                                                        .#MMMMMMMMMMMM    //
//    MMMMMMMMMMMM%.                                                                         :@MMMMMMMMMMM    //
//    MMMMMMMMMMM@,                                                                          .#MMMMMMMMMMM    //
//    MMMMMMMMMMM%.                                                                           :@MMMMMMMMMM    //
//    MMMMMMMMMM@,                                                                            .#MMMMMMMMMM    //
//    MMMMMMMMMM%.                                                                             :@MMMMMMMMM    //
//    MMMMMMMMM@:                                                                              .@MMMMMMMMM    //
//    MMMMMMMMM#.                                                                              .%MMMMMMMMM    //
//    MMMMMMMMM+.                                                                               ,MMMMMMMMM    //
//    MMMMMMMM@:                                                                                .@MMMMMMMM    //
//    MMMMMMMM@.                                                                    .            %MMMMMMMM    //
//    MMMMMMMM%                                                      .+%++. .++, .,+%:.          :@MMMMMMM    //
//    MMMMMMMM:                                                      .##%##.,@@#.,@#%@+.         ,@MMMMMMM    //
//    MMMMMMM@,               .........     ...                      .#+.:@:%#+@:+@,.%#.         .#MMMMMMM    //
//    MMMMMMM@.              .%%%%%%%%%+,. .+%:                      .#+,+@:@@#@%+@,,%#.         .%MMMMMMM    //
//    MMMMMMM#.              ,@MM@@@@@M@#:..%M+                      .#@##%+@++%#:#@##:           +MMMMMMM    //
//    MMMMMMM%.              ,@@+,,,,:+#M@,.+%:                      .,,,,.,,. .,..,:,.           :MMMMMMM    //
//    MMMMMMM%.              ,@@:      ,@M: ,,.  ..::::,.     .,:::,.                             :@MMMMMM    //
//    MMMMMMM+               ,@@:      .#M+.%@+ .+#@@@@@+.   ,%@@@@@+.                            ,@MMMMMM    //
//    MMMMMMM:               ,@@:      ,@@:.#M+.+@@%++%@@%. ,@@#++%#@%.                           ,@MMMMMM    //
//    MMMMMMM:               ,@@+.....,%@#..#M+.#M+.  .:@#,.%@+.   ,#@:                           .@MMMMMM    //
//    MMMMMMM:               ,@M@@@@@@@@%, .#M+.%M%,....++.,@@,.....+M%.                          .@MMMMMM    //
//    MMMMMMM:               ,@M####@@#:.  .#M+ :#@@#%++,. :@@%%%%%%#M%.                          .@MMMMMM    //
//    MMMMMMM:               ,@@:...,%M#,  .#M+  ,:%%#@@@+.:@@%+++++++:                           .@MMMMMM    //
//    MMMMMMM:               ,@@:    ,@M%. .#M+.,:,   .:@@:,@@,    .:+:                           ,@MMMMMM    //
//    MMMMMMM+               ,@@:    .+@@: .#M+.%@%.   .@@:.#@+.  .,#@+                           ,@MMMMMM    //
//    MMMMMMM+.              ,@@:     .#M#..#M+ :@@%+++%@@, :@@%+++#@#,                           ,@MMMMMM    //
//    MMMMMMM%.              .#@:      :@@:.%@+ .:#@@@@@#:. .:#@@@@@%,                            :@MMMMMM    //
//    MMMMMMM#.              .,,.      .,,. .,.   .,:::,.     .,:::,.                             :MMMMMMM    //
//    MMMMMMM@.                                                                                  .%MMMMMMM    //
//    MMMMMMM@,                                                                                  .#MMMMMMM    //
//    MMMMMMMM:                                                                                  .@MMMMMMM    //
//    MMMMMMMM%                                                                                  ,@MMMMMMM    //
//    MMMMMMMM#.                                                                                 +MMMMMMMM    //
//    MMMMMMMM@,                                                                                .#MMMMMMMM    //
//    MMMMMMMMM+                                                                                ,@MMMMMMMM    //
//    MMMMMMMMM#.                                                                               +MMMMMMMMM    //
//    MMMMMMMMM@,                                                                              .#MMMMMMMMM    //
//    MMMMMMMMMM%.                                                                             :@MMMMMMMMM    //
//    MMMMMMMMMM@,                                                                            .%MMMMMMMMMM    //
//    MMMMMMMMMMM+.                                                                           ,@MMMMMMMMMM    //
//    MMMMMMMMMMM@,                                                                          .%MMMMMMMMMMM    //
//    MMMMMMMMMMMM%.                                                                         :@MMMMMMMMMMM    //
//    MMMMMMMMMMMM@,                                                                        .#MMMMMMMMMMMM    //
//    MMMMMMMMMMMMM%.                                                                       :@MMMMMMMMMMMM    //
//    MMMMMMMMMMMMM@+.                                                                     ,@MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM@,                                                                    .%MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM#.                                                                  .+@MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM@%.                                                                 :@MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM@+.                                                               ,@MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM@:.                                                             ,#MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM@:.                                                           ,#MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM@:.                                                         ,#MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM@:.                                                       ,#MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM@+.                                                    .:@MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM@%.                                                  .+@MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM#:.                                               ,%@MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM@+.                                            .:#MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM@#:.                                        .,%@MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM@%,.                                    .,+@MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@%:.                                .,+#MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@#+,.                          ..:%@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@%:,..                   ..:+#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@@#+:,....      ....,:+%#@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@@@#%%++++++%%##@@MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RISEDAO is ERC721Creator {
    constructor() ERC721Creator("RiseDAO", "RISEDAO") {}
}
