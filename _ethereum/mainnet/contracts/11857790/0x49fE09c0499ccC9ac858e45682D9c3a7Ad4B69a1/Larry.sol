pragma solidity 0.7.1;
import "./Stooge.sol";

contract Larry is Stooge {
    receive() external payable {}
  function setCurly(address payable addr) external onlyOwner {
    require(address(curly) == address(0), 'only once');
    curly = ICurly(addr);
  }
    constructor(uint256 startTime_, uint256 duration_, address moe_)
    Stooge('LARRY', "LARRY") {
      startTime = startTime_;
      endTime = startTime + duration_;
      moe = moe_;

    }

    function slap() external override nonReentrant {
      require(slapped == false, "Already slapped");
      require(endTime < block.timestamp, "It aint on yet.");
      slapped = true;
      IERC20 pair = IERC20(uniswapFactory.getPair(address(this), weth));
      IERC20(pair).approve(address(uniswapRouter), pair.balanceOf(address(this)));
      uniswapRouter.removeLiquidityETH(
        address(this),
        pair.balanceOf(address(this)),
        0,
        0,
        address(this),
        block.timestamp
      );
      curly.mint(address(this), 750*(1e18));
      curly.approve(address(uniswapRouter), 750*(1e18));  
      payable(address(curly)).transfer(address(this).balance);
    }

    function bonk() external nonReentrant {
      require(slapped == true, "Not yet");
      require(bonked == false, "Already bonked");
      require(endTime < block.timestamp, "It aint on yet.");
      bonked = true;

      _approve(address(this), address(uniswapRouter), balanceOf(address(this)));
      uniswapRouter.addLiquidity(
        address(this),
        address(curly),
        balanceOf(address(this)),
        750*(1e18),
        0,
        0,
        address(this),
        block.timestamp
      );
    }
}