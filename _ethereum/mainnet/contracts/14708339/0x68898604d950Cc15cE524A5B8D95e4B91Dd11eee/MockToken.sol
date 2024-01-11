// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "ERC20.sol";
import "Ownable.sol";

/**
 * Used for testing purpose only.
 */
contract MockToken is ERC20("MockToken", "MT") {

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}