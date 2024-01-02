// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";

contract PaalXSwapContract is Context, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    // Uniswap v2 Router
    IUniswapV2Router02 public router;

    uint256 public swappingFee;
    uint256 public swappingFeeDivisior;

    bool public isStopped;

    event Buy(address indexed sender, uint256 amountIn, address indexed tokenOut, uint256 amountOut);
    event Sell(address indexed sender, address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    event SellTokensForTokens(address indexed sender, address indexed tokenIn, address indexed tokenOut, uint256 amountInAfterFee, uint256 amountOut);

    /**     
     * @param _router the address of the Uniswap v2 Router or compatible
     */
    constructor(IUniswapV2Router02 _router) {
        router = _router;        
        swappingFee = 10000; // 1%
        swappingFeeDivisior = 1000000; // Divisor to 10000 = 1%
    }   

    /** 
     * @notice Swaps ETH for tokens.
     * @dev The caller must send ETH along with the transaction.
     * @param tokenAddr The address of the token to be received.
     * @param amountOutMin The minimum amount of tokens to receive; the transaction will revert if not met.
     * @return amountOut The actual amount of tokens received.     
     */ 
    function swapExactETHForTokens(address tokenAddr, uint256 amountOutMin, uint256 _deadline) external payable nonReentrant returns (uint256 amountOut){
        require(!isStopped, "PAALXSWAP: Contract is not active");
        require(tokenAddr != address(0), "PAALXSWAP: Invalid _tokenAddress");
        require(msg.value > 0, "PAALXSWAP: Not enough ether");

        IERC20 token = IERC20(tokenAddr);
        IERC20 weth = IERC20(router.WETH());
        address sender = _msgSender();

        // Calculate the swapping fee and the transaction amount
        uint256 fee = (msg.value * swappingFee) / swappingFeeDivisior;
        uint256 amountIn = msg.value - fee;

        // Approve the router to spend the tokens for the swap
        weth.safeApprove(address(router), amountIn);
        
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddr;

        // Record the sender initial balance
        uint256 beforeBalance = token.balanceOf(sender);
        
        // Perform the token swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountIn
        }(amountOutMin, path, sender, block.timestamp + _deadline);

        // Record the sender final balance
        uint256 afterBalance = token.balanceOf(sender);

        // Calculate the amount of tokenOut received
        amountOut = afterBalance - beforeBalance;

        emit Buy(sender, msg.value, tokenAddr, amountOut);
    }

    /**
     * @notice Swaps tokens for ETH.
     * @dev The caller must have approved this contract to spend the token on their behalf.
     * @param tokenAddr The address of the token to be swapped.
     * @param amountIn The amount of tokens to be swapped.
     * @param amountOutMin The minimum amount of ETH to receive; the transaction will revert if not met.
     * @return amountOut The actual amount of ETH received.
     */    
    function swapExactTokensForETH(address tokenAddr, uint256 amountIn, uint256 amountOutMin, uint256 _deadline) external nonReentrant returns (uint256 amountOut){        
        require(!isStopped, "PAALXSWAP: Contract is not active");
        require(tokenAddr != address(0), "PAALXSWAP: Invalid _tokenAddress");
        require(amountIn > 0, "PAALXSWAP: Invalid amountIn");

        IERC20 token = IERC20(tokenAddr);
        address sender = _msgSender();

        // Record the contract initial balance
        uint256 initialBalance = token.balanceOf(address(this));

        // Transfer the tokens from the sender to this contract
        token.safeTransferFrom(sender, address(this), amountIn);

        // Calculate the actual tokens received after any fee-on-transfer
        uint256 actualReceived = token.balanceOf(address(this)) - initialBalance;

        // Calculate the swapping fee and the transaction amount
        uint256 fee = (actualReceived * swappingFee) / swappingFeeDivisior;
        uint256 amount = actualReceived - fee;

        // Approve the router to spend the tokens for the swap
        token.safeApprove(address(router), amount);

        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = router.WETH();

        // Record the sender initial balance
        uint256 beforeBalance = sender.balance;
        
        // Perform the token swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            amountOutMin,
            path,
            sender,
            block.timestamp + _deadline
        );
        
        // Record the sender final balance
        uint256 afterBalance = sender.balance;

        // Calculate the amount of tokenOut received
        amountOut = afterBalance - beforeBalance;

        emit Sell(sender, tokenAddr, amountIn, amountOut);
    }

    /**
     * @notice Swaps tokens for tokens.
     * @dev The caller must have approved this contract to spend the token on their behalf.
     * @param tokenIn the address of the token to be sent
     * @param tokenOut the address of the token to be received
     * @param amountIn the amount of tokenIn to be sent
     * @param amountOutMin the minimum amount of tokenOut to be received
     */
    function swapExactTokenForToken(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, uint256 _deadline) external nonReentrant returns (uint256 amountOut) {
        require(!isStopped, "PAALXSWAP: Contract is not active");
        require(tokenIn != address(0), "PAALXSWAP: Invalid tokenIn address");
        require(tokenOut != address(0), "PAALXSWAP: Invalid tokenOut address");
        require(amountIn > 0, "PAALXSWAP: Invalid amountIn");

        IERC20 tokenInContract = IERC20(tokenIn);
        IERC20 tokenOutContract = IERC20(tokenOut);
        address sender = _msgSender();

        // Calculate the 1% fee
        uint256 fee = (amountIn * swappingFee) / 1000000; // 1% fee

        // Deduct the fee from the input amount
        uint256 amountInAfterFee = amountIn - fee;

        // Transfer the tokens from the sender to this contract (including the fee)
        tokenInContract.safeTransferFrom(sender, address(this), amountIn);

        // Record the contract's initial balance of tokenOut
        uint256 initialBalance = tokenOutContract.balanceOf(address(this));

        // Set up the path for the swap
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Approve the router to spend the tokens for the swap
        tokenInContract.safeApprove(address(router), amountInAfterFee);

        // Perform the token swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInAfterFee,
            amountOutMin,
            path,
            sender,
            block.timestamp + _deadline
        );

        // Calculate the amount of tokenOut received
        uint256 afterBalance = tokenOutContract.balanceOf(address(this));        
        amountOut = afterBalance - initialBalance;

        emit SellTokensForTokens(sender, tokenIn, tokenOut, amountInAfterFee, amountOut);
    }

    /**     
     * @param newRouter the address of the new Uniswap v2 Router or compatible
     * @notice the router is used for the swap to be executed.
     */
    function setRouter(IUniswapV2Router02 newRouter) external onlyOwner {
        require(address(newRouter) != address(0), "PAALXSWAP: Invalid address");
        router = newRouter;
    }

    /**
     * @notice Withdraws all the ether held by the contract.
     * @dev Only callable by the owner.
     */
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Withdraws all the tokens held by the contract.
     * @dev Only callable by the owner.
     */
    function withdrawERC20(address tokenAddress) external onlyOwner returns (bool result){
        IERC20 token = IERC20(tokenAddress);
        result = token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Withdraws all the tokens held by the contract.
     * @dev Only callable by the owner.
     * @param _swappingFee the new swapping fee in percentage
     * @param _swappingFeeDivisior the new swapping fee divisior
     * 
     * Example: 
     *  1% = 10000 / 1000000
     *  0.1% = 1000 / 1000000
     *  0.01% = 100 / 1000000
     */
    function setSwappingFee(uint256 _swappingFee, uint256 _swappingFeeDivisior) external onlyOwner {
        swappingFee = _swappingFee;
        swappingFeeDivisior = _swappingFeeDivisior;
    }

    /**
     * @notice This function is used to stop the contract in case of emergency.
     * @param _isStopped the new state of the contract
     * @dev Only callable by the owner.
     */
    function emergencyStop(bool _isStopped) external onlyOwner {
        isStopped = _isStopped;
    }

    /**
     * @notice This function is used to stop the contract in case of emergency and withdraw all the funds.
     * @param _isStopped the new state of the contract
     * @dev Only callable by the owner.
     */
    function emergencyStopAndWithdraw(bool _isStopped) external onlyOwner {
        isStopped = _isStopped;
        payable(owner()).transfer(address(this).balance);
    }
    
}
