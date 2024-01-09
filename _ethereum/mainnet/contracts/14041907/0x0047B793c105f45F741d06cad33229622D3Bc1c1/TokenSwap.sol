pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TokenSwap {
    IERC20 public token1;
    IERC20 public token2;

    constructor(
        address _token1,
        address _token2
    ) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function swap(uint256 amount) public {
        token1.transferFrom(msg.sender, address(this), amount);
        
        token2.transfer(msg.sender, amount);
    }
}