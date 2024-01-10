// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ReentrancyGuard.sol";

import "./ISplitWithdrawable.sol";
import "./SplitWithdrawals.sol";
import "./DivisorBase.sol";

abstract contract SplitWithdrawable is DivisorBase, ISplitWithdrawable, ReentrancyGuard {
    using SplitWithdrawals for SplitWithdrawals.Payout;

    SplitWithdrawals.Payout internal _payout;

    constructor(address[] memory _recipients, uint16[] memory _splits) {
        _payout.recipients = _recipients;
        _payout.splits = _splits;
        _payout.BASE = BASE;

        // initialize the payout library
        _payout.initialize();
    }

    // WITHDRAWAL

    /// @dev withdraw native tokens divided by splits
    function withdraw() external override nonReentrant {
        _payout.withdraw();
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external override nonReentrant {
        _payout.withdrawTokens(_tokenContract);
    }

    /// @dev withdraw ERC721 tokens to the first recipient
    function withdrawNFT(address _tokenContract, uint256[] memory _id) external override nonReentrant {
        _payout.withdrawNFT(_tokenContract, _id);
    }

    /// @dev Allow a recipient to update to a new address
    function updateWithdrawalRecipient(address _recipient) external override nonReentrant {
        _payout.updateWithdrawalRecipient(_recipient);
    }
}
