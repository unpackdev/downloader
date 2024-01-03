pragma solidity =0.6.8;
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

// Secondary contract to refill Iteration Syndicate's Rebalancer Pool.
contract Refill is ReentrancyGuard {
    using SafeMath for uint256;

    event HasRefilled(uint256 lpAdded);

    address public its;
    address public weth;
    address public gateway;
    address payable public treasury;

    IUniswapV2Router02 router;
    uint256 public lastRefill;
    uint256 public refillInterval;    
    uint256 public callerRewardDivisor;
    uint256 public minItsBalance;

    receive () external payable {}
 
    constructor(address its_, address router_, address weth_) public {
        its = its_;
        lastRefill = block.timestamp;
        refillInterval = 7200;
        callerRewardDivisor = 10;
        minItsBalance = 100 ether;
        router = IUniswapV2Router02(router_);
        weth = weth_;
        gateway = msg.sender;
        treasury = tx.origin;
    }

    function setRefillInverval(uint256 _interval) public {
        require(msg.sender == gateway, "You're not the admin.");
        refillInterval = _interval;
    }

    function setCallerRewardDivisor(uint256 _divisor) public {
        require(msg.sender == gateway, "You're not the admin.");
        require(_divisor > 0);
        callerRewardDivisor = _divisor;
    }
    
    function setItsBalance(uint256 _balance) public {
        require(msg.sender == gateway, "You're not the admin.");        
        minItsBalance = _balance;
    }

    function RefillRebalancer() external nonReentrant { 
        require(block.timestamp > lastRefill + refillInterval, "To soon");
        require(IERC20(its).balanceOf(msg.sender) > minItsBalance, "You aren't part of the syndicate.");
        uint256 callerAmount = address(this).balance / callerRewardDivisor;
        uint256 ethAmount = address(this).balance.sub(callerAmount.mul(2)) / 2;
        uint[] memory amounts = router.swapExactETHForTokens.value(ethAmount)(1, getBuyPath(its), address(this), block.timestamp);
        IERC20(its).approve(address(router), amounts[1]);
        uint256 actualAmounts = IERC20(its).balanceOf(address(this));
        (,,uint liquidity) = router.addLiquidityETH.value(ethAmount)(its, actualAmounts, 1, 1, its, block.timestamp);
        msg.sender.transfer(callerAmount); //21000 gas limit >:)
        treasury.transfer(callerAmount);
        emit HasRefilled(liquidity);
    }

    function getBuyPath(address _token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = _token;
        return path;
    }
}