//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IERC20.sol";

import "./Timeboundable.sol";
import "./SyntheticToken.sol";
import "./Migratable.sol";

/// @title A pool to swap one token for another
contract SwapPool is Timeboundable, Migratable {
    IERC20 public inToken;
    SyntheticToken public outToken;

    /// Creates a new swap pool
    /// @param _start The block timestamp to start from (in secs). Use 0 for unbounded start.
    /// @param _start The block timestamp to start from (in secs). Use 0 for unbounded start.
    /// @param _finish The block timestamp to finish in (in secs). Use 0 for unbounded finish.
    constructor(
        address _inToken,
        address _outToken,
        uint256 _start,
        uint256 _finish
    ) public Timeboundable(_start, _finish) {
        outToken = SyntheticToken(_outToken);
        inToken = IERC20(_inToken);
    }

    /// Swap inToken for outToken in the same amount
    /// @param amount Amount to swap
    /// @dev `inToken` should be approved (`amount` tokens) to this contract
    function swap(uint256 amount) external inTimeBounds {
        inToken.transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            amount
        );
        outToken.mint(msg.sender, amount);
    }
}
