// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Command implementations
import "./Dispatcher.sol";
import "./RewardsCollector.sol";
import "./RouterImmutables.sol";
import "./Commands.sol";
import "./Constants.sol";
import "./IUniversalRouter.sol";
import "./StableSwapRouter.sol";
import "./Pausable.sol";

contract UniversalRouter is RouterImmutables, IUniversalRouter, Dispatcher, RewardsCollector, Pausable {
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params) RouterImmutables(params) StableSwapRouter(params.stableFactory, params.stableInfo) {}

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs) 
        public 
        payable 
        override 
        isNotLocked 
        whenNotPaused 
    {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands;) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                commandIndex++;
            }
        }

        uint256 balance = address(this).balance;
        if ((balance > 0) && (msg.sender != address(this))) sweep(Constants.ETH, msg.sender, balance);
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}
}
