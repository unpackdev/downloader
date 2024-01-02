// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

import "./Transfers.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./ITreasury.sol";
import "./Errors.sol";

contract Treasury is ITreasury, ReentrancyGuard {
    using Transfers for address;

    IAddressManager public immutable addressManager;

    /// [asset][account] => stuck amount
    mapping(address => mapping(address => uint256)) public stuckAssets;

    modifier onlyCegaEntryOrRedepositManager() {
        require(
            msg.sender == addressManager.getCegaEntry() ||
                msg.sender == addressManager.getRedepositManager(),
            Errors.NOT_CEGA_ENTRY_OR_REDEPOSIT_MANAGER
        );
        _;
    }

    constructor(IAddressManager _addressManager) {
        addressManager = _addressManager;
    }

    receive() external payable {}

    function withdraw(
        address asset,
        address receiver,
        uint256 amount,
        bool trustedReceiver
    ) external nonReentrant onlyCegaEntryOrRedepositManager {
        if (trustedReceiver) {
            require(asset.transfer(receiver, amount), Errors.TRANSFER_FAILED);
        } else if (
            receiver.code.length == 0 && asset.transfer(receiver, amount)
        ) {
            emit Withdrawn(asset, receiver, amount);
        } else {
            stuckAssets[asset][receiver] += amount;
            emit StuckAssetsAdded(asset, receiver, amount);
        }
    }

    function withdrawStuckAssets(
        address asset,
        address receiver
    ) external nonReentrant {
        uint256 amount = stuckAssets[asset][msg.sender];
        stuckAssets[asset][msg.sender] = 0;

        require(asset.transfer(receiver, amount), Errors.TRANSFER_FAILED);

        emit Withdrawn(asset, msg.sender, amount);
    }
}
