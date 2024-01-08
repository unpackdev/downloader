// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";

import "./IERC721SplitWithdrawals.sol";
import "./SplitWithdrawals.sol";
import "./ERC2981Base.sol";

abstract contract ERC721SplitWithdrawals is ERC2981Base, IERC721SplitWithdrawals, ReentrancyGuard {
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
    function withdraw() external nonReentrant {
        _payout.withdraw();
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external nonReentrant {
        _payout.withdrawTokens(_tokenContract);
    }

    /// @dev withdraw ERC721 tokens to the first recipient
    function withdrawNFT(address _tokenContract, uint256[] memory _id) external nonReentrant {
        _payout.withdrawNFT(_tokenContract, _id);
    }

    /// @dev Allow a recipient to update to a new address
    function updateRecipient(address _recipient) external override nonReentrant {
        _payout.updateRecipient(_recipient);
    }
}