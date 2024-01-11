// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IAccessControlUpgradeable.sol";

interface ILoyaltyLedger is IAccessControlUpgradeable {
    // ---- events ----
    event BaseUriUpdated(string uri);
    event MaxSupplyLocked(uint256 id);
    event TransferEnabledLocked(uint256 id);
    event TransferEnableUpdated(uint256 id, bool transferable);
    event TokenCreated(uint256 id, string name, uint256 maxSupply, bool transferEnabled);
    event MaxSupplyUpdated(uint256 id, uint256 maxSupply);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();

    function claim(uint256 _id, uint256 _amount) external payable;

    function claimWhitelist(
        uint256 _id,
        bytes32[] calldata _proof,
        uint256 _maxAmount,
        uint256 _claimAmount
    ) external payable;

    function createToken(
        string memory _name,
        uint256 _maxSupply,
        bool _transferEnabled,
        uint256 _claimFee,
        uint256 _claimAmount,
        uint256 _whitelistClaimFee
    ) external returns (uint256);

    function eject() external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function initialize(address _creator) external;

    function isManaged() external view returns (bool);

    function lockMaxSupply(uint256 _id) external;

    function lockTransferEnabled(uint256 _id) external;

    function lockVersion() external;

    function loyaltyLedgerVersion() external pure returns (uint256);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function mintBulk(
        address[] memory _addresses,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function setOwnership(address newOwner) external;

    function setTokenClaimEnabled(uint256 _id, bool _enabled) external;

    function setTokenClaimOptions(
        uint256 _id,
        uint256 _claimFee,
        uint256 _claimAmount
    ) external;

    function setTokenMaxSupply(uint256 _id, uint256 _maxSupply) external;

    function setTokenTransferEnabled(uint256 _id, bool _enabled) external;

    function setTokenWhitelistClaimEnabled(uint256 _id, bool _enabled) external;

    function setTokenWhitelistClaimFee(uint256 _id, uint256 _claimFee) external;

    function setWhitelistOptions(
        uint256 _id,
        uint256 _claimFee,
        bytes32 _whitelistRoot
    ) external;

    function setWhitelistRoot(uint256 _id, bytes32 _whitelistRoot) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function withdraw() external;
}
