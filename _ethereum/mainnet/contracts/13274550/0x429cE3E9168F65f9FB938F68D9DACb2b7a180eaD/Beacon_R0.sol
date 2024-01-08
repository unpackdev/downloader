// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IBeaconUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

import "./BeaconProxy.sol";

import "./IOwnable.sol";
import "./IPausable.sol";
import "./IBeaconDeployer.sol";

contract Beacon_R0 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC165Upgradeable, IBeaconUpgradeable, IBeaconDeployer {

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __Beacon_init();
    }

    function __Beacon_init() internal {
    }

    address private _implementation;
    mapping(bytes32 => address) private _registry;
    address private _operator;
    mapping(address => bool) private _canDeploy;

    function allowDeploy(address deployer) external onlyOperator {
        _canDeploy[deployer] = true;
    }

    function disallowDeploy(address deployer) external onlyOperator {
        delete _canDeploy[deployer];
    }

    // Deploys new unnamed contract
    function deployNewContract(bytes calldata data) external override canDeploy returns (address) {
        require(_implementation != address(0x00), "implementation is not set");
        // deploy new beacon proxy and do init call
        BeaconProxy beaconProxy = new BeaconProxy(address(this), data);
        address deployedAddress = address(beaconProxy);
        emit Deployed('', deployedAddress);
        // If contract declares support of IOwnable transfer ownership from this contract to our owner
        if (ERC165CheckerUpgradeable.supportsInterface(deployedAddress, type(IOwnable).interfaceId)) {
            IOwnable asOwnable = IOwnable(deployedAddress);
            asOwnable.transferOwnership(owner());
        }
        return address(beaconProxy);
    }

    // Deploys new contract and adds its name to registry
    function deployNewNamedContract(string memory name, bytes calldata data) external override canDeploy returns (address) {
        require(_implementation != address(0x00), "implementation is not set");
        // deploy new beacon proxy and do init call
        BeaconProxy beaconProxy = new BeaconProxy(address(this), data);
        address deployedAddress = address(beaconProxy);
        _registry[keccak256(abi.encodePacked(name))] = deployedAddress;
        emit Deployed(name, deployedAddress);
        // If contract declares support of IOwnable transfer ownership from this contract to our owner
        if (ERC165CheckerUpgradeable.supportsInterface(deployedAddress, type(IOwnable).interfaceId)) {
            IOwnable asOwnable = IOwnable(deployedAddress);
            asOwnable.transferOwnership(owner());
        }
        return deployedAddress;
    }

    function implementation() external override view returns (address) {
        return _implementation;
    }

    function upgradeTo(address newImplementation) external override onlyOwner {
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    function getContractByName(string memory name) external view override returns (address) {
        return _registry[keccak256(abi.encodePacked(name))];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IBeaconUpgradeable).interfaceId
        || interfaceId == type(IBeaconDeployer).interfaceId
        || interfaceId == type(IPausable).interfaceId;
    }

    function setOperator(address newOperator) external onlyOwner {
        _operator = newOperator;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    modifier canDeploy() {
        require(msg.sender == owner() || msg.sender == _operator || _canDeploy[msg.sender], "canDeploy: not allowed");
        _;
    }
}
