//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract BridgeRequestAutomationContract {
    using SafeERC20 for IERC20;

    event LogBridgeRequest( // Emit from Source
        string actionId,
        address indexed user,
        address to,
        address token,
        uint256 amount,
        address indexed bridgeAddress,
        uint256 sourceChainId,
        uint256 indexed targetChainId,
        bytes metadata
    );

    // constructor(address __owner) {
    //     _transferOwnership(__owner);
    // }

    function request(
        string memory actionId_,
        address to_,
        address token_,
        uint256 amount_,
        address bridgeAddress_,
        uint256 targetChainId_,
        bytes memory metadata_
    ) public {
        IERC20(token_).safeTransferFrom(msg.sender, bridgeAddress_, amount_);
        emit LogBridgeRequest(
            actionId_,
            msg.sender, 
            to_,
            token_,
            amount_,
            bridgeAddress_,
            block.chainid,
            targetChainId_,
            metadata_
        );
    }
}


//   event LogBridgeCommitted( // Emit from Target
//         string actionId,
//         address user,
//         address to,
//         address token,
//         uint256 amount,
//         address indexed bridgeAddress,
//         uint32 indexed sourceChainId, // ChainId of the contract deployed
//         uint32 targetChainId,
//         bytes32 indexed requestSourceTransactionHash,
//         bytes metadata
//     );

