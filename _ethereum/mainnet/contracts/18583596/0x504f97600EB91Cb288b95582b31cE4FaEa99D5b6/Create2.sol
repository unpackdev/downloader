// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Create2.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Detailed.sol";
import "./ICreate2Deployer.sol";
import "./IRealtMediator.sol";

contract Create2Deployer is
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreate2Deployer
{
    bytes32 public constant DEPLOYER_ROLE = 0xc806a955a4540a681430c702343887fec907f9e462be59f97b2cb3bcf01bb4bd; //keccak256("CREATE2.DEPLOYER.ROLE");
    uint8 public constant VERSION = 3;
    IRealtMediator private _bridge;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRealtMediator bridge_) external reinitializer(VERSION) {
        _bridge = bridge_;
    }

    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer
    ) external override onlyProxy onlyRole(DEPLOYER_ROLE) returns (address) {
        address newContract = Create2.deploy(amount, salt, bytecode);
        if (initializer.length > 0) {
            (bool success, ) = newContract.call(initializer);
            require(success, "Init failed");
        }
        emit Deployed(newContract, salt, keccak256(bytecode));
        return newContract;
    }

    function deployToken(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer,
        bool isBridgeable
    ) external override onlyProxy onlyRole(DEPLOYER_ROLE) returns (address) {
        address newContract = Create2.deploy(amount, salt, bytecode);
        if (initializer.length > 0) {
            (bool success, ) = newContract.call(initializer);
            require(success, "Init failed");
        }
        string memory name = IERC20Detailed(newContract).name();
        string memory symbol = IERC20Detailed(newContract).symbol();
        IRealtMediator bridge = _bridge;
        if (address(bridge) != address(0) && isBridgeable) bridge.setToken(newContract, newContract);
        emit DeployedToken(
            newContract,
            salt,
            keccak256(bytecode),
            name,
            symbol
        );
        return newContract;
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash)
        external
        view
        override
        onlyProxy
        returns (address)
    {
        return Create2.computeAddress(salt, bytecodeHash);
    }

    function bridgeAddress()
        external
        view
        onlyProxy
        returns (IRealtMediator)
    {
        return _bridge;
    }

    function setBridge(IRealtMediator bridge_)
        external
        onlyProxy
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _bridge = bridge_;
    }

    /**
     * Allow send ether
     */
    receive() external payable {}

    function withdraw(uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        payable(_msgSender()).transfer(amount);
        return true;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
