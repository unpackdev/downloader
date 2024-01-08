// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./Initializable.sol";

import "./TokenListener.sol";
import "./ControlledToken.sol";
import "./PrizePool.sol";
import "./MultiTokenFaucet.sol";

/// @title TimelockTokenListener
/// @notice Checks to see if a token burn is from a non-zero timelock balance and reverts if so
contract TimelockTokenListener is TokenListener, Initializable {

    /// @notice PrizePool this TokenListener is associated with 
    PrizePool public prizePool;
    
    /// @notice Initializer function that sets the associated PrizePool
    /// @dev Only callable once
    /// @param _prizePool The address of the associated PrizePool
    function initialize(PrizePool _prizePool) external initializer {
        prizePool = _prizePool;
    }

    /// @notice Freezes the contract, so that there is no owner.
    /// @dev Useful for proxy implementations
    function freeze() public initializer {
        // no-op
    }
    
    /// @inheritdoc TokenListenerInterface
    function beforeTokenMint(address to, uint256 amount, address controlledToken, address referrer) external override {        
        // no-op
    }

    /// @inheritdoc TokenListenerInterface
    function beforeTokenTransfer(address from, address to, uint256 amount, address controlledToken) external override {

        if (to == address(0) && prizePool.timelockBalanceOf(from) > 0) {
            revert("TimelockTokenListener/timelock-non-zero");
        }
    }

}