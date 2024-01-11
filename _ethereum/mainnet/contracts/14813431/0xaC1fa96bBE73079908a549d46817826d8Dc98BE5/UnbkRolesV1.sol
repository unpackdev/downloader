// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract UnbkRolesUpgradeableV1 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CONTRACT_UPDATER = keccak256("CONTRACT_UPDATER");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    bytes32 public constant BONUS_REWARDER = keccak256("BONUS_REWARDER");

    modifier onlyContractUpdater() {
        require(hasRole(CONTRACT_UPDATER, msg.sender), "UCUA");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address firstContractUpdater,
        address firstBonusRewarder,
        address firstTreasury
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _setupRole(CONTRACT_UPDATER, firstContractUpdater);
        _setupRole(BONUS_REWARDER, firstBonusRewarder);
        _setupRole(TREASURY, firstTreasury);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function setupContractUpdater(address _addr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _setupRole(CONTRACT_UPDATER, _addr);
        return true;
    }

    function setupTreasuryRole(address _addr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _setupRole(TREASURY, _addr);
        return true;
    }

    function setupBonusRewarderRole(address _addr)
        external
        onlyContractUpdater
        returns (bool)
    {
        _setupRole(BONUS_REWARDER, _addr);
        return true;
    }
}
