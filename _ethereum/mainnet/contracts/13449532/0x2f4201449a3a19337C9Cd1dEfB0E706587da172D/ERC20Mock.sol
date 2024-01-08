// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./IERC20.sol";
import "./ERC20.sol";

contract ERC20Mock is ERC20("Mock", "MOCK") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
