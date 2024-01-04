pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract SweepToOwner is Ownable {
    using SafeERC20 for IERC20;
    function sweepToOwner(address token) external onlyOwner() returns(bool) {
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
        return true;
    }
}