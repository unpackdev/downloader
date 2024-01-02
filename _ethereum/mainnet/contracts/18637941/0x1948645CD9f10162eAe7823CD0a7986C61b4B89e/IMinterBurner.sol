// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IMinterBurner {
    struct BurnRatioEpoch {
        uint256 volume;
        uint16 deciRatio;
    }
    struct MintReceiver {
        address receiver;
        uint16 deciPercents;
    }
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event BurntAndMinted(uint256 burnt, uint256 minted, uint256 indexed index);
    event IncreasedAmount(address indexed account, uint256 amount);
    event Initialized(uint8 version);
    event Paused(address account);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event SpentBalance(address indexed account, uint256 amount);
    event Unpaused(address account);
    event Upgraded(address indexed implementation);
    event Withdrawn(address indexed account, uint256 amount);

    function CONFIGURATOR_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function MINTER_AND_BURNER_ROLE() external view returns (bytes32);

    function MintReward() external view returns (address);

    function PAUSER_ROLE() external view returns (bytes32);

    function SPENDER_ROLE() external view returns (bytes32);

    function TOKEN_OWNER_ROLE() external view returns (bytes32);

    function Token() external view returns (address);

    function UPGRADER_ROLE() external view returns (bytes32);

    function addBurnRatioEpoch(uint256 volume, uint16 deciRatio) external;

    function addMintReceiver(address receiver, uint16 deciPercents) external;

    function balanceOf(address account) external view returns (uint256);

    function burnAndMint() external;

    function burnAndMintHistory(uint256)
    external
    view
    returns (
        uint256 burntAmount,
        uint256 mintAmount,
        uint16 mintRewardDeciPercents,
        uint256 ts,
        uint256 blk
    );

    function burnRatioEpochs(uint256)
    external
    view
    returns (uint256 volume, uint16 deciRatio);

    function burnTokens(address _addr, uint256 _amount) external;

    function burntAmount() external view returns (uint256);

    function clearBurnRatioEpochs() external;

    function getAmountToMint(uint256 _amountToBurn)
    external
    view
    returns (uint256);

    function getBurnRatioEpochs()
    external
    view
    returns (BurnRatioEpoch[] memory);

    function getBurnRatioIndexAndAmountToBurnOnCurrentEpoch()
    external
    view
    returns (uint256, uint256);

    function getMintReceivers()
    external
    view
    returns (MintReceiver[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
    external
    view
    returns (bool);

    function increaseAmount(uint256 value) external;

    function increaseAmountFor(address _addr, uint256 value) external;

    function initialize(address _token, address _mintReward) external;

    function lastBurnRatio() external view returns (uint256);

    function mintBurnIndex() external view returns (uint256);

    function mintReceivers(uint256)
    external
    view
    returns (address receiver, uint16 deciPercents);

    function mintRewardDeciPercents() external view returns (uint16);

    function mintTokens(address _addr, uint256 _amount) external;

    function pause() external;

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function readyToBurn() external view returns (uint256);

    function receiverBurnAndMintHistory(address, uint256)
    external
    view
    returns (
        uint256 mintAmount,
        uint256 index,
        uint256 deciPercents,
        uint256 ts,
        uint256 blk
    );

    function receiverBurnAndMintIndex(address) external view returns (uint256);

    function removeMintReceiver(address receiver) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setLastBurnRatio(uint16 _lastBurnRatio) external;

    function setMintRewardDeciPercent(uint16 _deciPercents) external;

    function spendForMaintenances(address account, uint256 amount) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function toBurnBalances(address) external view returns (uint256);

    function transferTokenOwnership(address newOwner) external;

    function unpause() external;

    function updateMintReward(address _mintReward) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
    external
    payable;

    function withdraw() external;
}
