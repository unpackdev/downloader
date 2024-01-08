pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenLock365Days is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token = IERC20(address(0));

    constructor() public {}

    function withdraw(address _token) public onlyOwner {
        token = IERC20(_token);
        uint256 contractBalance = token.balanceOf(address(this));

        token.transfer(msg.sender, contractBalance);
    }
}
