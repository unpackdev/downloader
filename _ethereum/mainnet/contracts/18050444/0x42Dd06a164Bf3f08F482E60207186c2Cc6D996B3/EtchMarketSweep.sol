// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OrderTypes.sol";

interface IEtchMarket {
    function executeEthscriptionOrder(
        OrderTypes.EthscriptionOrder calldata order,
        address recipient,
        bytes calldata trustedSign
    ) external payable;
}

contract EtchMarketSweep is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address private _marketAddress;

    function initialize() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    function batchBuy(OrderTypes.EthscriptionOrder[] calldata orders) external payable nonReentrant {
        // execute trades
        for (uint256 i = 0; i < orders.length; i++) {
            _buyAsset(orders[i], false);
        }

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function setMarketAddress(address market) external onlyOwner {
        _marketAddress = market;
    }

    function _buyAsset(OrderTypes.EthscriptionOrder calldata order, bool _revertIfTrxFails) internal {
        bytes memory _data = abi.encodeWithSelector(
            IEtchMarket.executeEthscriptionOrder.selector,
            order,
            msg.sender,
            ""
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
