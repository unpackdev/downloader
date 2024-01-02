// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./BatchOrder.sol";
import "./OrderTypes.sol";
import "./ICarpenterMarket.sol";

//interface ICarpenterMarket {
//    function executeOrderWithMerkle(
//        BatchOrder.EthscriptionOrder calldata order,
//        BatchOrder.MerkleTree calldata merkleTree,
//        address recipient
//    ) external payable;
//}

contract CarpenterMarketSweep is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    error RefundFailed();

    address private _marketAddress;

    function initialize() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    function bulkBuy(
        BatchOrder.EthscriptionOrder[] calldata orders,
        BatchOrder.MerkleTree[] calldata merkleTrees
    ) external payable nonReentrant {
        for (uint256 i = 0; i < orders.length; i++) {
            _buyAssetWithMerkle(orders[i], merkleTrees[i], false);
        }

        // return remaining ETH (if any)
        bool success = true;
        assembly {
            if gt(selfbalance(), 0) {
                success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
        if (!success) {
            revert RefundFailed();
        }
    }

    function setMarketAddress(address market) external onlyOwner {
        _marketAddress = market;
    }

    function _buyAssetWithMerkle(
        BatchOrder.EthscriptionOrder calldata order,
        BatchOrder.MerkleTree calldata merkleTree,
        bool _revertIfTrxFails
    ) internal {
        bytes memory _data = abi.encodeWithSelector(
            ICarpenterMarket.executeOrderWithMerkle.selector,
            order,
            merkleTree,
            msg.sender
        );
        (bool success, ) = _marketAddress.call{value: order.price}(_data);
        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
