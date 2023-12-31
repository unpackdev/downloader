// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./AaveBase.sol";
import "./IDelayedBox.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/


contract AaveL1Bridge is AAVEBase {
    uint256 public constant GAS_LIMIT_FOR_CALL = 2_000_000;
    uint256 public constant MAX_FEE_PER_GAS = 1 gwei;
    uint256 public constant MAX_SUBMISSION_COST = 0.001 ether;
    address public constant DELAYED_INBOX =
        0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant ARBITRUM_RECEIVER =
        0x83974C384aABa24C813A2cC8dF42d967FcD479c1;

    receive() external payable {
        uint256 requiredValue = MAX_SUBMISSION_COST +
            GAS_LIMIT_FOR_CALL *
            MAX_FEE_PER_GAS;
        bytes memory depositAaveEthData = abi.encodeWithSelector(
            bytes4(keccak256("depositAaveEth(address)")),
            msg.sender           
        );

        IDelayedBox(DELAYED_INBOX).createRetryableTicket{
            value: msg.value
        }(
            ARBITRUM_RECEIVER,
            msg.value - requiredValue,
            MAX_SUBMISSION_COST,
            msg.sender,
            msg.sender,
            GAS_LIMIT_FOR_CALL,
            MAX_FEE_PER_GAS,
            depositAaveEthData
        );

    }
}
