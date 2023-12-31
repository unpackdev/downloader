// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IPortal.sol";
import "./FriendTechBridgeBase.sol";

contract EthSharesPurchaser is FriendTechBridgeBase {
    
    receive() external payable {
        bytes memory buySharesData = abi.encodeWithSelector(
            bytes4(keccak256("buyShares(address)")),
            msg.sender
        );

        Protal(CROSS_CHAIN_PORTAL).depositTransaction{value: msg.value}(
            BASE_RECEIVER,
            msg.value,
            GAS_LIMIT,
            false,
            buySharesData
        );
    }
}
