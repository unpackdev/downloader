pragma solidity 0.7.1;
import "./Stooge.sol";

contract Curly is Stooge {
  uint256 unlock;
  receive() external payable {}

  function setMoe(address addr) external onlyOwner {
    require(address(moe) == address(0), 'only once');
    moe = addr;
  }     
    constructor(uint256 startTime_, uint256 duration_, address payable larry_)
    Stooge('CURLY', "CURLY") {
      startTime = startTime_;
      endTime = startTime + duration_;
      larry = ILarry(larry_);
      unlock = 1 days;
    }

    function slap() external override nonReentrant {
        require(endTime < block.timestamp, "It aint on yet.");
        require(slapped == false, 'Already slapped');
        _mint(address(this), 250*(1e18));

        slapped = true;
        _approve(address(this), address(uniswapRouter), 250*1e18);
        uniswapRouter.addLiquidityETH{value: address(this).balance}(
          address(this),
          250*(1e18),
          0,
          0,
          address(this),
          block.timestamp
        );
    }

    function withdrawUnlock(address token_, uint256 amount_) external onlyOwner {
      require(endTime + unlock < block.timestamp, "Too soon");
      IERC20(token_).transfer(msg.sender, amount_);
    }
}