// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Create2.sol";
import "./SpritzReceiver.sol";
import "./AccessControlEnumerable.sol";

/**
 * @title SpritzReceiverFactory
 * @dev This contract acts as a factory for deploying SpritzReceiver instances using CREATE2.
 */
contract SpritzReceiverFactory is AccessControlEnumerable {
    using Create2 for bytes32;

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    // Bytecode for the contract to be deployed
    bytes public constant contractBytecode = type(SpritzReceiver).creationCode;

    address public immutable controller;

    address public spritzPay;
    address public swapModule;

    event ContractDeployed(address deployedAddress);

    constructor(address _controller) {
        controller = _controller;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEPLOYER_ROLE, _controller);
    }

    /**
     * @dev Deploy a new contract instance using CREATE2.
     * @param accountReference The reference for the account (usually bytes32).
     * @return The address of the deployed contract.
     */
    function deploy(bytes32 accountReference) external onlyRole(DEPLOYER_ROLE) returns (address) {
        bytes32 salt = getSalt(controller, accountReference);

        bytes memory bytecodeWithConstructorArgs = abi.encodePacked(
            contractBytecode,
            abi.encode(controller, accountReference)
        );
        address deployedAddress = Create2.deploy(0, salt, bytecodeWithConstructorArgs);

        emit ContractDeployed(deployedAddress);

        return deployedAddress;
    }

    /**
     * @dev Compute the address of a contract that would be deployed using a specific accountReference.
     * @param accountReference The reference for the account (usually bytes32).
     * @return The computed address of the contract.
     */
    function computeAddress(bytes32 accountReference) external view returns (address) {
        bytes32 salt = getSalt(controller, accountReference);

        bytes memory bytecodeWithConstructorArgs = abi.encodePacked(
            contractBytecode,
            abi.encode(controller, accountReference)
        );

        return Create2.computeAddress(salt, keccak256(bytecodeWithConstructorArgs));
    }

    /**
     * @dev Return the address of spritz pay and swap module used for all receivers
     */
    function getDestinationAddresses() external view returns (address, address) {
        return (spritzPay, swapModule);
    }

    /**
     * @dev Set the address of the spritz pay contract
     */
    function setSpritzPay(address _spritzPay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        spritzPay = _spritzPay;
    }

    /**
     * @dev Set the address of the swap module contract
     */
    function setSwapModule(address _swapModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapModule = _swapModule;
    }

    /**
     * @dev Setup initial contract state
     */
    function initialize(address admin, address _spritzPay, address _swapModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
        swapModule = _swapModule;
        spritzPay = _spritzPay;
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Generate a unique salt value from accountReference.
     * @param _controller The controller of the contracts
     * @param _accountReference The reference for the account
     * @return The unique salt for the CREATE2 operation.
     */
    function getSalt(address _controller, bytes32 _accountReference) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_controller, _accountReference));
    }
}
