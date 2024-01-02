// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ITokenMessenger.sol";
import "./IMessageTransmitter.sol";

/// @title CCTPBridge: Trustless Cross chain bridges powered by CCTP
/// @notice Helper contract which can be used to bridge USDC using CCTP
/// @notice A Public good by Fetcch(https://fetcch.xyz)
contract CCTPBridge is AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Float handler for precision handling
    uint256 public constant FLOAT_HANDLER = 10000;

    /// @dev Keeps track of collected fees
    uint256 public collectedFees;

    /// @dev Bridging fees in basis points hundredths (For eg: 5% = 500)
    uint256 public fees;

    /// @dev USDC token address
    IERC20 public usdc;

    /// @dev CCTP TokenMessenger address
    ITokenMessenger public tokenMessenger;

    /// @dev CCTP MessageTransmitter address
    IMessageTransmitter public messageTransmitter;

    /// @dev Throws when amount entered is incorrect
    error IncorrectAmount();

    /// @dev Throws when address entered is incorrect
    error IncorrectAddress();

    /// @dev Throws when receiveMessage fails
    error ReleaseFailed();

    /// @dev Triggers when USDC gets bridged
    event Bridged(
        uint256 amount,
        uint32 destinationChain,
        address sender,
        address receiver
    );

    /// @dev Triggers when USDC gets released
    event Released(address caller, bytes message, bytes signature);

    /// @dev Used to initialize contract by passing necessary addresses
    constructor(
        address usdc_,
        address tokenMessenger_,
        address messageTransmitter_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        usdc = IERC20(usdc_);
        tokenMessenger = ITokenMessenger(tokenMessenger_);
        messageTransmitter = IMessageTransmitter(messageTransmitter_);
    }

    /// @dev This function is used to bridge USDC using CCTP TokenMessenger
    /// @param amount Amount of USDC to be bridged from source chain to destination chain
    /// @param destinationChain Destination Chain ID where the USDC will be sent
    /// @param receiver Address on destination chain where the USDC should be received
    function bridge(
        uint256 amount,
        uint32 destinationChain,
        address receiver
    ) external payable {
        usdc.transferFrom(msg.sender, address(this), amount);
        uint256 amountOut = amount;

        if (fees != 0) {
            collectedFees += ((amountOut * fees) / FLOAT_HANDLER);
            amountOut -= fees;
        }

        usdc.approve(address(tokenMessenger), amountOut);
        tokenMessenger.depositForBurn(
            amountOut,
            destinationChain,
            bytes32(uint256(uint160(receiver))),
            address(usdc)
        );

        emit Bridged(amount, destinationChain, msg.sender, receiver);
    }

    /// @dev This function is used to transfer USDC using CCTP MessageTransmitter
    /// @param message The message raw bytes
    /// @param signature The message signature
    function release(
        bytes calldata message,
        bytes calldata signature
    ) external {
        bool released = messageTransmitter.receiveMessage(message, signature);
        if (!released) revert ReleaseFailed();

        emit Released(msg.sender, message, signature);
    }

    /// @dev Sets the fees for this contract in basis points (hundredths).
    /// @dev Can be only called by admin
    /// @param newFees New fee percentage
    function changeFees(uint256 newFees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fees = newFees;
    }

    /// @dev This function is used to rescue USDC if locked
    /// @dev Can be only called by admin
    function rescueFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender, balance);
    }

    /// @dev This function is used to withdraw collected fees
    /// @dev Can be only called by admin
    /// @param _amount Amount of fees to withdraw
    function withdrawFees(
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdc.transfer(msg.sender, _amount);
        collectedFees -= _amount;
    }
}
