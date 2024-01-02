// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IAcross.sol";
import "./AcrossBridgeBase.sol";
import "./console.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract AcrossToBase is AcrossBridgeBase {
    uint256 public constant CHAIN_ID = 8453;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
        decimal1 = 16;
        decimal2 = 15;
        percent1 = 5;
        percent2 = 2;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);                  
        uint256 valueAfterFees = msg.value - chargedFees;               
        int64 relayerFeePct = getHighRelayersFee(valueAfterFees);
                                                                 
        IAcross(BRIDGE).deposit{value: valueAfterFees}(          
            msg.sender,                                         
            WETH,                                               
            valueAfterFees,                                     
            CHAIN_ID,
            relayerFeePct,
            uint32(block.timestamp),
            "",
            type(uint256).max
        );
    }
}
