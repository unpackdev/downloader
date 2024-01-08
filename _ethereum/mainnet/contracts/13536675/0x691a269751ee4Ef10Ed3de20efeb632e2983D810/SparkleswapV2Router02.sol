pragma solidity =0.6.6; 

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Factory.sol";
import "./UniswapV2Router02.sol";
import "./SparkleswapIncentiveOracle.sol";




contract SparkleswapV2Router02 is Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint;
    using Address for address;
    
IERC20 private _sparkleswap;

    
UniswapV2Router02 public immutable _UniswapV2Router02;
IUniswapV2Factory public immutable _IUniswapV2Factory;
SparkleswapIncentiveOracle public immutable _SparkleswapIncentiveOracle;

    
uint256 private minBalanceForRebate = 100 * (10**18);
address public immutable WETH;

    
constructor(address payable uniswapV2Router02, IERC20 sparkleswap, address _WETH, address iUniswapV2Factory, address sparkleswapOracle) public {
    _UniswapV2Router02 = UniswapV2Router02(uniswapV2Router02);
    _IUniswapV2Factory = IUniswapV2Factory(iUniswapV2Factory);
    _SparkleswapIncentiveOracle = SparkleswapIncentiveOracle(sparkleswapOracle);
    _sparkleswap = sparkleswap;
    WETH = _WETH;
 }
    
 receive() external payable {}   
    
     function updateMinBalanceForRebate (
         uint256 _minBalanceForRebate) external onlyOwner returns (uint256 ) {
            minBalanceForRebate = _minBalanceForRebate;
            return minBalanceForRebate;
         } 
         
     // Withdraw reward token
     function withdrawRewardToken (
        uint256 amount) public onlyOwner returns (uint256) {
        address OwnerAddress = owner();  
            if (OwnerAddress == msg.sender)    
            IERC20(_sparkleswap).transfer(OwnerAddress, amount);
         return amount;
    }
    
      // withdraw random IERC20 token
      // **Only call this function if the token is a trusted source**
     function withdrawStuckToken (
        uint256 amount, address _tokenAddress) public onlyOwner returns (uint256) {
        address OwnerAddress = owner();  
            if (OwnerAddress == msg.sender)    
            IERC20(_tokenAddress).transfer(OwnerAddress, amount);
         return amount;
    }
    
     // Withdraw stuck ETH
     function withdrawStuckETH (
        ) public onlyOwner returns (uint256) {
        address OwnerAddress = owner();
        uint256 amount = address(this).balance;
            if (OwnerAddress == msg.sender)    
            msg.sender.transfer(amount);
         return amount;
    }
    

     // SparkleSwap -> Uniswapv2Router02  - > (Liquidity) 
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) external  {
          // Sparkleswap permission         
        require(IERC20(tokenA).approve(address(this), amountADesired), 'approve failed.');
        require(IERC20(tokenB).approve(address(this), amountBDesired), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired), 'transferFrom failed.');
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(tokenA).approve(address(_UniswapV2Router02), amountADesired), 'approve failed.');
        require(IERC20(tokenB).approve(address(_UniswapV2Router02), amountBDesired), 'approve failed.');     
        _UniswapV2Router02.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RLP());
        } 
       
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external payable{
          // Sparkleswap permission         
        require(IERC20(token).approve(address(this), amountTokenDesired), 'approve failed.');
          // Sparkleswap transfer 
        require(IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired), 'transferFrom failed.');
          // Uniswap permission 
        require(IERC20(token).approve(address(_UniswapV2Router02), amountTokenDesired), 'approve failed.');    
        _UniswapV2Router02.addLiquidityETH{ value: msg.value }(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline);
         // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender,  _SparkleswapIncentiveOracle.RLP());
        } 
    }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) external  {
        // Get Uniswap lp token address
        address UNILP = _IUniswapV2Factory.getPair(tokenA, tokenB);
        // Sparkleswap permission         
        require(IERC20(UNILP).approve(address(this), liquidity), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(UNILP).transferFrom(msg.sender, address(this), liquidity), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(UNILP).approve(address(_UniswapV2Router02), liquidity), 'approve failed.');    
        _UniswapV2Router02.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline);
          // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender,  _SparkleswapIncentiveOracle.RLP());
        } 
    }
    
        
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external  {
         // Sparkleswap permission         
        require(IERC20(token).approve(address(this), liquidity), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(token).transferFrom(msg.sender, address(this), liquidity), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(token).approve(address(_UniswapV2Router02), liquidity), 'approve failed.');
        _UniswapV2Router02.removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender,  _SparkleswapIncentiveOracle.RLP());
        } 
    }
    
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) external  {
        // Sparkleswap permission         
        require(IERC20(token).approve(address(this), liquidity), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(token).transferFrom(msg.sender, address(this), liquidity), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(token).approve(address(_UniswapV2Router02), liquidity), 'approve failed.');
        _UniswapV2Router02.removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender,  _SparkleswapIncentiveOracle.RLP());
        } 
    }
    
    
    // SparkleSwap -> Uniswapv2Router02  - > (Swaps) 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external  {
        // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountIn), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountIn), 'approve failed.');
        _UniswapV2Router02.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender,  _SparkleswapIncentiveOracle.RTX());
        } 
    }
        
        
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline) external {
         // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountInMax), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountInMax), 'approve failed.');
        _UniswapV2Router02.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
        
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline) external payable {
        _UniswapV2Router02.swapExactETHForTokens{ value: msg.value }(
            amountOutMin, 
            path, 
            to, 
            deadline);
        //Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
        
        
    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline) external {
        // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountInMax), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountInMax), 'approve failed.');     
        _UniswapV2Router02.swapTokensForExactETH(
            amountOut, 
            amountInMax, 
            path, 
            to, 
            deadline);
        // Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
        
        
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline) external {
         // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountIn), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountIn), 'approve failed.');  
        _UniswapV2Router02.swapExactTokensForETH (
            amountIn, 
            amountOutMin, 
            path, 
            to, 
            deadline);
        // Give rebate    
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
    
    
    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline) external payable {
        _UniswapV2Router02.swapETHForExactTokens{ value: msg.value }(
            amountOut, 
            path, 
            to, 
            deadline);
        //Give rebate    
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
    
    
  

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external {
         // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountIn), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountIn), 'approve failed.');  
        _UniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens (
            amountIn,
            amountOutMin,
            path,
            to,
            deadline);
        //Give rebate
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external payable {
        _UniswapV2Router02.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline);
        //Give rebate        
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
    }
    
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external {
         // Sparkleswap permission         
        require(IERC20(path[0]).approve(address(this), amountIn), 'approve failed.');
        // Sparkleswap transfer 
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        // Uniswap permission 
        require(IERC20(path[0]).approve(address(_UniswapV2Router02), amountIn), 'approve failed.');  
        _UniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline);
        // Give rebate   
        if (_sparkleswap.balanceOf(msg.sender) > minBalanceForRebate ) {
        _sparkleswap.transfer(msg.sender, _SparkleswapIncentiveOracle.RTX());
        } 
     
    }
    
    
}