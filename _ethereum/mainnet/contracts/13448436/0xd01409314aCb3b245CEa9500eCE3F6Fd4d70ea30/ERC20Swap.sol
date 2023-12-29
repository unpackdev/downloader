pragma solidity ^0.4.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

contract ERC20Swap is ERC20 {
    using SafeERC20 for ERC20Burnable;

    ERC20Burnable public swapToken;

    constructor(ERC20Burnable _swapToken) public {
        swapToken = _swapToken;
    }

    function swap() external {
        address holder = address(msg.sender);
        uint256 amount = swapToken.allowance(holder, address(this));

        require(amount > 0, "No allowance");

        swapToken.burnFrom(holder, amount);
        _mint(holder, amount);
    }
}
