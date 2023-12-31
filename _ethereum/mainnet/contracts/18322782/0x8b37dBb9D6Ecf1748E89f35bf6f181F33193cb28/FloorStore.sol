pragma solidity ^0.8.18;

import "./Administrable.sol";
import "./EIP712Common.sol";
import "./IFloorPack.sol";
import "./Address.sol";

error NotEnoughFunds();
error PackAlreadyOwned();
error PackNotActive();
error PackNotConfigured();

contract FloorStore is EIP712Common, Administrable {
    struct ItemConfig {
        address contractAddress;
        uint64 salePrice;
        uint64 tokenId;
        bool active;
        bool exists;
    }

    // PackID => ItemConfig
    mapping(bytes32 => ItemConfig) public items;

    // Supply Tracking
    mapping(bytes32 => uint32) public mintedSupply;

    // AccountID <> PackID
    mapping(bytes32 => bytes32[]) public ownerships;

    address private treasuryAddress;

    constructor() {
        _setTreasuryAddress(msg.sender);
    }

    // ***********************
    // * Minter
    // ***********************

    function mintPack(
        bytes calldata signature,
        string calldata packId,
        string calldata accountId
    ) external payable requiresAllowlist(signature, packId, accountId) {
        bytes32 encodedPackId = keccak256(bytes(packId));

        ItemConfig memory config = items[encodedPackId];

        if (!config.exists) revert PackNotConfigured();
        if (!config.active) revert PackNotActive();

        if (msg.value < config.salePrice) revert NotEnoughFunds();

        mintedSupply[encodedPackId] += 1;

        IFloorPack(config.contractAddress).airdropSingle(1, msg.sender);
    }

    function isAuthorized(
        bytes calldata signature,
        string calldata packId,
        string calldata accountId
    )
        external
        view
        requiresAllowlist(signature, packId, accountId)
        returns (bool)
    {
        bytes32 encodedPackId = keccak256(bytes(packId));
        bytes32 encodedAccountId = keccak256(bytes(accountId));

        bytes32[] memory ownedPacks = ownerships[encodedAccountId];

        for (uint256 i = 0; i < ownedPacks.length; ) {
            if (ownedPacks[i] == encodedPackId) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    // ***********************
    // * Financials
    // ***********************

    function setTreasuryAddress(
        address _treasuryAddress
    ) external onlyOperatorsAndOwner {
        _setTreasuryAddress(_treasuryAddress);
    }

    function _setTreasuryAddress(
        address _treasuryAddress
    ) internal onlyOperatorsAndOwner {
        treasuryAddress = _treasuryAddress;
    }

    function withdraw() external onlyOperatorsAndOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    // ***********************
    // * Admin
    // ***********************

    function setSigningAddress(
        address _signingAddress
    ) external onlyOperatorsAndOwner {
        signingKey = _signingAddress;
    }

    function getConfig(
        string calldata packId
    ) external view returns (ItemConfig memory) {
        bytes32 encodedPackId = keccak256(bytes(packId));

        return items[encodedPackId];
    }

    function setConfig(
        string calldata packId,
        ItemConfig calldata config
    ) external onlyOperatorsAndOwner {
        bytes32 encodedPackId = keccak256(bytes(packId));

        items[encodedPackId] = config;
    }

    function isOwnerOfPack(
        string calldata packId,
        string calldata accountId
    ) external view returns (bool) {
        bytes32 encodedAccountId = keccak256(bytes(accountId));
        bytes32 encodedPackId = keccak256(bytes(packId));

        bytes32[] memory ownedPacks = ownerships[encodedAccountId];

        for (uint256 i = 0; i < ownedPacks.length; ) {
            if (ownedPacks[i] == encodedPackId) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function supply(string calldata packId) external view returns (uint256) {
        return mintedSupply[keccak256(bytes(packId))];
    }
}
