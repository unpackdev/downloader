// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface FOXXIES is IERC721Enumerable {
    event TokenPriceChanged(uint256 newTokenPrice);
    event PresaleConfigChanged(address whitelistSigner, uint32 startTime, uint32 endTime);
    event SaleConfigChanged(uint32 startTime, uint32 initMaxCount, uint32 maxCountUnlockTime, uint32 unlockedMaxCount);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event TreasuryChanged(address newTreasury);
    event BaseURIChanged(string newBaseURI);
    event PresaleMint(address minter, uint256 count);
    event SaleMint(address minter, uint256 count);

    // Both structs fit in a single storage slot for gas optimization
    struct PresaleConfig {
        address whitelistSigner;
        uint32 startTime;
        uint32 endTime;
    }
    struct SaleConfig {
        uint32 startTime;
        uint32 initMaxCount;
        uint32 maxCountUnlockTime;
        uint32 unlockedMaxCount;
    }

    function reserveTokens(address recipient, uint256 count) external;

    function setTokenPrice(uint256 _tokenPrice) external;

    function setUpPresale(
        address whitelistSigner,
        uint256 startTime,
        uint256 endTime
    ) external;

    function setUpSale(
        uint256 startTime,
        uint256 initMaxCount,
        uint256 maxCountUnlockTime,
        uint256 unlockedMaxCount
    ) external;

    function setIsBurnEnabled(bool _isBurnEnabled) external;

    function setTreasury(address payable _treasury) external;

    function setBaseURI(string calldata newbaseURI) external;

    function mintPresaleTokens(
        uint256 count,
        uint256 maxCount,
        bytes calldata signature
    ) external payable;

    function mintTokens(uint256 count) external payable;

    function burn(uint256 tokenId) external;
}