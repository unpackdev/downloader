// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./AccessControlUpgradeable.sol";
import "./TransparentUpgradeableProxy.sol";

import "./IContractsRegistry.sol";

contract ContractsRegistry is IContractsRegistry, AccessControlUpgradeable {
    mapping (bytes32 => address) private _contracts;
    mapping (address => bool) private _isProxy;

    bytes32 constant public REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant UNISWAP_BRIGHT_TO_ETH_PAIR_NAME = keccak256("UNI_BRIGHT_ETH_PAIR");
    bytes32 public constant LIQUIDITY_MINING_STAKING_NAME = keccak256("LIQ_MINING_STAKING");

    bytes32 constant public BRIGHT_STAKING_NAME = keccak256("BRIGHT_STAKING_NAME");
    bytes32 constant public BRIGHT_NAME = keccak256("BRIGHT");
    bytes32 constant public STKBRIGHT_NAME = keccak256("STK_BRIGHT");

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "ContractsRegistry: Caller is not an admin");
        _;
    }

    function __ContractsRegistry_init() external initializer {
        __AccessControl_init();

        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);
    }

    function getUniswapBrightToETHPairContract() external view override returns (address) {
        return getContract(UNISWAP_BRIGHT_TO_ETH_PAIR_NAME);
    }

    function getBrightContract() external view override returns (address) {
        return getContract(BRIGHT_NAME);
    }

    function getBrightStakingContract() external view override returns (address) {
        return getContract(BRIGHT_STAKING_NAME);
    }

    function getSTKBrightContract() external view override returns (address) {
        return getContract(STKBRIGHT_NAME);
    }

    function getLiquidityMiningStakingContract() external view override returns (address) {
        return getContract(LIQUIDITY_MINING_STAKING_NAME);
    }

    function getContract(bytes32 name) public view returns (address) {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        return _contracts[name];
    }

    function upgradeContract(bytes32 name, address newImplementation) external onlyAdmin {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(_contracts[name]));

        require(_isProxy[address(proxy)], "ContractsRegistry: Can't upgrade not a proxy contract");

        proxy.upgradeTo(newImplementation);
    }

    function addContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
    }

    function addProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            contractAddress, address(this), ""
        );

        _contracts[name] = address(proxy);
        _isProxy[address(proxy)] = true;
    }

    function deleteContract(bytes32 name) external onlyAdmin {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        delete _isProxy[_contracts[name]];
        delete _contracts[name];
    }
}
