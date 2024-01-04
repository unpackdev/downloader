pragma solidity 0.7.1;
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./ICurly.sol";
import "./ILarry.sol";
import "./IStooge.sol";
import "./Stooge.sol";

contract Stooge is ERC20, Ownable, ReentrancyGuard, IStooge {
  uint256 public startTime;
  uint256 public endTime;

  bool slapped;
  bool bonked;
  bool dropkicked;

  ILarry larry;
  ICurly curly;
  
  address moe;
  address payable public treasury;
  address weth;

  IUniswapV2Router02 uniswapRouter;
  IUniswapV2Factory uniswapFactory;


  constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_){
    treasury = msg.sender;
    uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    weth = uniswapRouter.WETH();
  }
  function slap() external override virtual { }
  function mint(address account, uint256 amount) external {
    require(msg.sender == moe || msg.sender == address(larry) || msg.sender == address(curly), 'Only Stooges!');
    _mint(account, amount);
  }
}