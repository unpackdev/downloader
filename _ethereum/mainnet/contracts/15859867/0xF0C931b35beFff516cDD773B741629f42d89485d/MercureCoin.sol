// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";


//  ___      ___   _______   _______    ______   ____  ____   _______    _______  
// |"  \    /"  | /"     "| /"      \  /" _  "\ ("  _||_ " | /"      \  /"     "| 
//  \   \  //   |(: ______)|:        |(: ( \___)|   (  ) : ||:        |(: ______) 
//  /\\  \/.    | \/    |  |_____/   ) \/ \     (:  |  | . )|_____/   ) \/    |   
// |: \.        | // ___)_  //      /  //  \ _   \\ \__/ //  //      /  // ___)_  
// |.  \    /:  |(:      "||:  __   \ (:   _) \  /\\ __ //\ |:  __   \ (:      "| 
// |___|\__/|___| \_______)|__|  \___) \_______)(__________)|__|  \___) \_______)

contract MercureCoin is ERC20("Mercure","MRC"), Ownable {
    address ownerAddress = 0x77b18DcC71aD19e21cb60A4cB1B8CA5AC8014C31;

    uint256 constant LIQUIDITY = 2_000_000_000_000_000_000_000_000_000;

    constructor(){
        //For liquidity pool
        _mint(ownerAddress,LIQUIDITY);
        transferOwnership(ownerAddress);
    }
}