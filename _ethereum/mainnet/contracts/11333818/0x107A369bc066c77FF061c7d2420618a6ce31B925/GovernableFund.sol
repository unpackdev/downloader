pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

/**
 * @title A simple contract for holding funds.
 */
contract GovernableFund is Ownable, ReentrancyGuard {
  using Address for address payable;
  using SafeERC20 for IERC20;

  function transfer(address token, address to, uint256 value) external onlyOwner nonReentrant returns (bool) {
    require(token != address(0) && to != address(0), 'Address is 0');
    IERC20(token).safeTransfer(to, value);
    return true;
  }
  function transferETH(address payable to, uint256 value) onlyOwner nonReentrant external {
    require(to != address(0), 'Address is 0');
    to.sendValue(value);
  }

  receive() external payable {}
}
