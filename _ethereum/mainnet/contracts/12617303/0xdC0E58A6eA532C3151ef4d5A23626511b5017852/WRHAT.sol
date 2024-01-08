//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract WRHAT is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 constant rhat = IERC20(0x4F0Fe57066AB1c84569dc6DD2EDfE08B92F97F33);

    constructor() ERC20("Wrapped RHAT", "WRHAT") {}

    function wrap(uint amount) public {
        rhat.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * 1e18);
    }

    function unwrap(uint amount) public {
        _burn(msg.sender, amount*1e18);
        rhat.safeTransfer(msg.sender, amount);
    }
}