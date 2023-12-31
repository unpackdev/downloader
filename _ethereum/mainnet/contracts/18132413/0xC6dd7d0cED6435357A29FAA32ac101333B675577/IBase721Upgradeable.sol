// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IBaseUpgradeable.sol";

interface IBase721Upgradeable is IBaseUpgradeable {
    error NFT__InvalidType();

    event Registered(
        address indexed recipient,
        uint256 indexed typeNFT,
        uint256 tokenId,
        uint256 quantity,
        uint256 soldByType
    );

    event ReferralBonus(
        address nftAddress,
        uint256 tokenId,
        address recipient,
        uint256 quantity,
        address paymentToken,
        address referral,
        uint256 referralBonus
    );

    function buy(uint256 typeNFT_, uint256 quantity_, address recipient_, address referral_) external payable;
}
