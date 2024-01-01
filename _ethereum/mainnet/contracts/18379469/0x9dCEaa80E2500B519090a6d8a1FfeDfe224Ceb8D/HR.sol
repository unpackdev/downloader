// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721.sol";

//             .       .        .                .        .                           
//     .    .         . .     .-               .  +     @              .   . +.+     
//            .  .               .       .      :     @        .           .  . .    
//       .      +    .   .  .    ..   .             *     #.       -.                
//          *   @    .       -   .                            * -.=.   @       @ . . 
//.     .    *   :       .  =         .            -   .   @     .      :   . @    .  
//                             .     .    .    -    +   =        .       .:.  .  .   
//         .  #              . =    .            :    *                @-            
// ..       .   @ @     *  *  .   .      .  ..  = * +     +   *     -@ .       .   . 
//           ..   @ % # .:.@ -         .  .  .  .       # *  %    @@ @           .   
//   .   . .       -@.#      - % .          .   .*  # #    .. . @-@%      .. .       
//           . ..    %@++..  : *           .   *.  +. ... =. +@@@     .  ..   .   .  
//    .           ..   @@#-=.   .   .  .       @   :.  +- = @@@+         .  .    .   
//* @:       .           @@@@-= . .:.         . *+  ..=%:.@@@*                   @   
// .= -@@@           .     @@@+::@--  =       @* . -+=:#@@@    . .   .       @ @  @ .
//        : @@@ ..            @@@%  : : +      @+: *=@@@@@.               +@# %   .   
//   . .    . @@@#      .      @@@@%+   @    %@.#@@@@@@     .        @@@@ .        . 
//*- .    #   :  * @@@  .    . . @@@@@::@ .  @@+@@@@@         .  @@@+@ +.   @:.   .# 
//@:       @@   #@  + @@@@..       @@@@-@    @@@@@@         @@@@+@-  @.   @@     . - 
// :=   .    ..     %     @@@@@   .  @@@@@. @@@@@ .    @@@@@. #. **     #=    .      
//.     . ..       ..    #    @@@@@+    @@  @@    :@@@@@@  :@@    *           ..  .  
// .       .  +*=.      .      : .@@@@@@ @@@@ @@@@@@=@.              -=-             
//.             -@@@@@@@@@@@@@@-%*        @@    %@@@@%%@@@@@@@@@@@@@*   .            
//@@@=   .    . ..  .        .    .     @@  @@*        .    = .    %@@@@       .*%#% 
//.                . .               :@@@   :@@@@       =    :=   *         ..    .  
//        .             .        .  @@@@+    @@@@@@       :    .  #*         .   .   
//                .       .       @@@@@=.    =@@@@@@@    .         . . :- +@-        
//              -  .            @@@@#*:      :+ #@@@@@@         .    -   @    -@   : 
//     .                 .    @@@ :-*..   ..  @* +-*%@@@@  .       ..                
//            .             @@@%-++* :    .  .@*:*:=@@+@@@-      . .   .           . 
//.  .              . .   @@@%. ==+. *      . -%*:. .:-=%@@@+                      . 
//    .                 @@#**   *-=            **==  : : .%@@@@          .        .  
//      .       . .  .*@ @ :- #:.        .      **+ :#  @  *-*@@@ .    .             
//           .      @@ @ % :   +. . .          .@: : . # + * *@.@@%           .      
//.        . .     @@-@.. @   . -   .    .      ..:+  +   :    .+@.%@@        .     . 
//              @ %# -   .  .  -     . . .         #=    - .- +  @@ -@@              
//            @ @+ :  @  .                       *. * @     @   -  @   @      ..     
// ..         * @    :      . .   ..  .            + #  #   *        @   =  . .      
// .                     .      .          ..     = + @   #           .-  .          
//.     %    .    .      .  .    .  .         .    .    #          .      .  .       
//    @   .              .            . .    .            #  ..                #     
//  %          .  .         .                       +                            = . 
//        .     .              .     .    ..   .         .   .  .                  . 
//  .     .  .    . .              .                      .    .  .       .          
//. .              .         .               .    .          .                        
//                       .                      .     .    .          .      .  

// ERC-721 functions necessary for our interaction
interface IBlackHole is IERC721 {
    function lastBurner() external view returns (address);
    function withdraw() external;
    function minted() external view returns (uint256);
    function burnt() external view returns (uint256);
    function burn(uint256 tokenId) external;
}

contract HawkingRadiation {
    IBlackHole public immutable blackHoleContract;
    mapping(address => uint248) public burntViaHawking;
    uint248 public totalBurntViaHawking;
    bool public hasCollected = false;
    
    receive() external payable {}

    constructor(address _blackHoleAddress) {
        blackHoleContract = IBlackHole(_blackHoleAddress);
    }

    function transferAndBurnViaHawking(uint256 tokenId) external {
        require(!hasCollected, "ETH has been collected, cannot burn anymore");

        // Transfer the NFT to this contract
        blackHoleContract.transferFrom(msg.sender, address(this), tokenId);
        
        // Burn the NFT
        blackHoleContract.burn(tokenId);
        
        burntViaHawking[msg.sender] += 1;
        totalBurntViaHawking += 1;
    }

    function collectBlackHoleETH() external {
        require(!hasCollected, "ETH already collected");

        blackHoleContract.withdraw();

        hasCollected = true;
    }

    function claimETH() external {
        require(hasCollected, "ETH hasn't been collected yet");
    
        uint248 userBurntCount = burntViaHawking[msg.sender];
        require(userBurntCount > 0, "You haven't burnt any NFT via HawkingRadiation");

        uint256 ethShare = (address(this).balance * userBurntCount) / totalBurntViaHawking;

        require(ethShare > 0, "No ETH to claim");
        
        // Resetting the user's burnt count after claiming
        burntViaHawking[msg.sender] = 0; 

        // Removing from total
        totalBurntViaHawking -= userBurntCount;
        
        // Transfer the user's share of ETH
        payable(msg.sender).transfer(ethShare);
    }
}
