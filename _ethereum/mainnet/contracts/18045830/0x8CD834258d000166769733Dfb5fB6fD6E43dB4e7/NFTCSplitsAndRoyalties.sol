// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import "./ERC2981_NFTCExtended.sol";
import "./NFTCPaymentSplitter.sol";

/**
 * @title NFTCSplitsAndRoyalties
 * @author @NiftyMike | @NFTCulture
 * @dev One stop shop for Payment Splits and ERC2981 Royalty Definition.
 */
abstract contract NFTCSplitsAndRoyalties is NFTCPaymentSplitter, ERC2981_NFTCExtended {
    constructor(
        address[] memory __addresses,
        uint256[] memory __splits,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyBasisPoints
    ) NFTCPaymentSplitterBase(__addresses, __splits) {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyBasisPoints);
    }

    function _isOwner() internal view virtual override(NFTCPaymentSplitter, ERC2981_NFTCExtended);
}
