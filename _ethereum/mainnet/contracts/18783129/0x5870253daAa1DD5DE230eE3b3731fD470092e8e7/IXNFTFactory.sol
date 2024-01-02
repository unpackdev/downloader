// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IXNFTFactory {
    struct AccountInfo {
        uint256 mintTimestamp;
        uint256 revealTimestamp;
        uint32 maxMintCount;
        uint32 maxMintPerWallet;
        uint256 mintPrice;
        address accountFeeAddress;
        bytes32 accountNameHash;
    }

    struct AccountAddressInfo {
        address xnftCloneAddr;
        address xnftLPAddr;
    }

    function accountAddresses(
        uint256
    ) external view returns (address xnftCloneAddr, address xnftLPAddr);

    function accounts(
        uint256
    )
        external
        view
        returns (
            uint256 mintTimestamp,
            uint256 revealTimestamp,
            uint32 maxMintCount,
            uint32 maxMintPerWallet,
            uint256 mintPrice,
            address accountFeeAddress,
            bytes32 accountNameHash
        );

    function claim(uint256 _accountId, uint256 tokenId) external;

    function contractURI(
        uint256 _accountId
    ) external view returns (string calldata);

    function creatorFeeBps() external view returns (uint32);

    function getAccountAddresses(
        bytes32 _accountNameHash
    ) external view returns (AccountAddressInfo calldata);

    function getAccountInfo(
        bytes32 _accountNameHash
    )
        external
        view
        returns (AccountInfo calldata, uint256, uint256, uint256, uint256);

    function getUserMintCount(
        bytes32 _accountNameHash,
        address user
    ) external view returns (uint256);

    function initialize(
        uint256 _minMintPrice,
        address _marketplaceFeeAddress,
        address _newOperator,
        address _whitelist,
        address _xnftBeaconAddress,
        address _xnftLPBeaconAddress
    ) external;

    function locklists(uint256, uint256) external view returns (bool);

    function marketplaceFeeAddress() external view returns (address);

    function marketplaceFeeBps() external view returns (uint32);

    function marketplaceHash() external view returns (bytes4);

    function marketplaceSecondaryFeeBps() external view returns (uint32);

    function minMintPrice() external view returns (uint256);

    function mintCount(uint256) external view returns (uint256);

    function mintMany(uint256 _accountId, uint32 quantity) external;

    function owner() external view returns (address);

    function pauseWhitelist(bool _status) external;

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function redeem(uint256 _accountId, uint256 tokenId) external;

    function redeemPrice(uint256 _accountId) external view returns (uint256);

    function renounceOwnership() external;

    function royaltyFeeBps() external view returns (uint32);

    function royaltyInfo(
        uint256 _accoundId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function setBaseURI(string calldata baseURI) external;

    function setCreatorFeeBps(uint32 _creatorFeeBps) external;

    function setLocklist(
        bytes32 _accountNameHash,
        uint256 _tokenId,
        bool _status
    ) external;

    function setMarketplaceFeeAddress(address _marketplaceFeeAddress) external;

    function setMarketplaceFeeBps(uint32 _marketplaceFeeBps) external;

    function setMarketplaceHash(bytes4 _marketplaceHash) external;

    function setMarketplaceSecondaryFeeBps(
        uint32 _marketplaceSecondaryFeeBps
    ) external;

    function setMinMintPrice(uint256 _minMintPrice) external;

    function setOperator(address newOperator) external;

    function setPause(bool _status) external;

    function setRoyaltyFeeBps(uint32 _royaltyFeeBps) external;

    function setUpAccount(
        string calldata accountName,
        uint256 _mintTimestamp,
        uint256 _revealTimestamp,
        uint32 _maxMintCount,
        uint32 _maxMintPerWallet,
        uint256 _mintPrice,
        address _accountFeeAddress,
        bytes32 _accountNameHash,
        bytes32 _accountIdHash
    ) external;

    function setWhitelist(address _whitelist, bool _status) external;

    function tokenURI(
        uint256 _accountId,
        uint256 tokenId
    ) external view returns (string calldata);

    function transferOwnership(address newOwner) external;

    function updateAccount(
        uint256 _accountId,
        uint256 _mintTimestamp,
        uint256 _revealTimestamp,
        uint32 _maxMintCount,
        uint32 _maxMintPerWallet,
        uint256 _mintPrice,
        address _accountFeeAddress,
        bytes32 _accountNameHash
    ) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external;

    function wethAddress() external view returns (address);

    function whitelistPaused() external view returns (bool);

    function whitelists(address) external view returns (bool);

    function xnftContracts(address) external view returns (bool);
}
