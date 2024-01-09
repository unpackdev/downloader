pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

/// @notice cBSN token burner - just approve the contract and then call burn to send the tokens into a black hole.
contract Burner {
    /// @notice Address of the cBSN token
    IERC20 public cBSN;

    /// @param _cBSN Address of cBSN token that will be burned
    constructor(IERC20 _cBSN) {
        cBSN = _cBSN;
    }

    /// @notice Burn `_amount` from `_owner` that has approved this contract
    /// @dev Tokens will be pulled in with no where to go
    /// @param _owner Address that has a cBSN balance and has approved this contract for transfer
    /// @param _amount Number of tokens that will be transferred into the contract and burned forever
    function burn(address _owner, uint256 _amount) external {
        cBSN.transferFrom(_owner, address(this), _amount);
    }
}
