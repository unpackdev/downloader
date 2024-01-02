// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./console.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV3Factory.sol";
import "./IWETH.sol";
import "./ISwapV2Router.sol";
import "./ISwapV3Router.sol";

contract SwapCentral {
    using SafeERC20 for IERC20;

    error InsufficientInput();

    //Owner-Related Variables//
    address public dev;
    address public owner;
    uint256 public FEE_EXCHANGE;
    uint256 public constant FEE_DENOM = 1e6;

    address public immutable WETH;
    address public immutable UNISWAP_V2_ROUTER;
    address public immutable UNISWAP_V3_ROUTER;
    address public immutable UNISWAP_V3_FACTORY;

    ISwapV2Router private immutable V2_ROUTER;
    ISwapV3Router private immutable V3_ROUTER;
    IUniswapV3Factory private immutable V3_FACTORY;

    event UpdateDev(address newDev);
    event UpdateFee(uint256 fee);
    event UpdateOwner(address newOwner);
    event Swap(
        address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    constructor(
        address _WETH,
        address _owner,
        uint256 _exchangeFee,
        address routerV2,
        address routerV3,
        address factoryV3
    ) {
        WETH = _WETH;
        dev = msg.sender;
        FEE_EXCHANGE = _exchangeFee;
        owner = _owner;
        UNISWAP_V2_ROUTER = routerV2;
        V2_ROUTER = ISwapV2Router(routerV2);
        UNISWAP_V3_ROUTER = routerV3;
        V3_ROUTER = ISwapV3Router(routerV3);
        UNISWAP_V3_FACTORY = factoryV3;
        V3_FACTORY = IUniswapV3Factory(factoryV3);
    }

    modifier onlyDev() {
        require(msg.sender == dev, "only dev");
        _;
    }

    // 1
    function exactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut) {
        //split the token
        uint256[2] memory amounts = splitTokenValue(amountIn); //split the token

        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), amounts[1]);

        //swap
        ISwapV3Router.ExactInputSingleParams memory params = ISwapV3Router.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountIn: amounts[1],
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountOut = V3_ROUTER.exactInputSingle(params);

        //transfer to owner
        IERC20(tokenIn).safeTransfer(owner, amounts[0]);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // 2
    function exactETHForTokens(
        address tokenOut,
        uint24 fee,
        uint256 amountOutMin,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external payable returns (uint256 amountOut) {
        //split the token
        uint256[2] memory amounts = splitTokenValue(msg.value);

        //swap
        ISwapV3Router.ExactInputSingleParams memory params = ISwapV3Router.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountIn: amounts[1],
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountOut = V3_ROUTER.exactInputSingle{value: amounts[1]}(params);

        //transfer to owner
        safeTransferETH(owner, amounts[0]);

        emit Swap(msg.sender, address(0), tokenOut, msg.value, amountOut);
    }

    // 3
    function tokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountInMax,
        uint256 amountOutDesired,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {
        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax);

        //swap
        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountOut: amountOutDesired,
            amountInMaximum: amountInMax,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountIn = V3_ROUTER.exactOutputSingle(params);

        //transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);
        if (amountInMax < amountIn + ownerShares) revert InsufficientInput();
        IERC20(tokenIn).safeTransfer(owner, ownerShares);

        // refund to msg.sender
        if (amountInMax > amountIn + ownerShares) {
            IERC20(tokenIn).safeDecreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax - (amountIn + ownerShares));
            IERC20(tokenIn).safeTransfer(msg.sender, amountInMax - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOutDesired);
    }

    // 4
    function tokensForExactETH(
        address tokenIn,
        uint24 fee,
        uint256 amountInMax,
        uint256 amountOutDesired,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {
        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax);

        //swap
        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: WETH,
            fee: fee,
            recipient: address(this), //send to this contract, unwrapped WETH, and send to msg.sender
            deadline: block.timestamp + deadlineInSeconds,
            amountOut: amountOutDesired,
            amountInMaximum: amountInMax,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountIn = V3_ROUTER.exactOutputSingle(params);

        //unwrap WETH
        IWETH(WETH).withdraw(amountOutDesired);

        // transfer to msg.sender
        safeTransferETH(msg.sender, amountOutDesired);

        //transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);
        if (amountInMax < amountIn + ownerShares) revert InsufficientInput();
        IERC20(tokenIn).safeTransfer(owner, ownerShares);

        // refund to msg.sender
        if (amountInMax > amountIn + ownerShares) {
            IERC20(tokenIn).safeDecreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax - (amountIn + ownerShares));
            IERC20(tokenIn).safeTransfer(msg.sender, amountInMax - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, tokenIn, address(0), amountIn, amountOutDesired);
    }

    // 5
    function exactTokensForETH(
        address tokenIn,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut) {
        //split the token
        uint256[2] memory amounts = splitTokenValue(amountIn); //split the token

        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), amounts[1]);

        //swap
        ISwapV3Router.ExactInputSingleParams memory params = ISwapV3Router.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: WETH,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + deadlineInSeconds,
            amountIn: amounts[1],
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountOut = V3_ROUTER.exactInputSingle(params);

        //unwrap WETH
        IWETH(WETH).withdraw(amountOut);

        // transfer to msg.sender
        safeTransferETH(msg.sender, amountOut);

        // transfer to owner
        IERC20(tokenIn).safeTransfer(owner, amounts[0]);

        emit Swap(msg.sender, tokenIn, address(0), amountIn, amountOut);
    }

    // 6
    function ethForExactTokens(
        address tokenOut,
        uint24 fee,
        uint256 amountOutDesired,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external payable returns (uint256 amountIn) {
        // should use WETH as input, otherwise ETH will stuck in router
        IWETH(WETH).deposit{value: msg.value}();
        IERC20(WETH).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), msg.value);

        //swap
        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountOut: amountOutDesired,
            amountInMaximum: msg.value,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        amountIn = V3_ROUTER.exactOutputSingle(params);

        // transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);

        //unwrap WETH
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));

        if (msg.value < amountIn + ownerShares) revert InsufficientInput();

        safeTransferETH(owner, ownerShares);
        // refund to msg.sender
        if (msg.value > amountIn + ownerShares) {
            safeTransferETH(msg.sender, msg.value - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, address(0), tokenOut, amountIn, amountOutDesired);
    }

    /*
    token[0] = token input (in); token[1] = token intermediary (med); token[2] = token output (out)
    fee[0] = fee In-Med; fee[1] = fee Med-Out
    */
    function exactInputMultihop(
        address[3] memory token,
        uint24[2] memory fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        IERC20(token[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        //split the token
        uint256[2] memory amounts = splitTokenValue(amountIn); //split the token

        IERC20(token[0]).safeIncreaseAllowance(UNISWAP_V3_ROUTER, amounts[1]);

        ISwapV3Router.ExactInputParams memory params = ISwapV3Router.ExactInputParams({
            path: abi.encodePacked(token[0], fee[0], token[1], fee[1], token[2]),
            recipient: msg.sender,
            deadline: block.timestamp + deadline,
            amountIn: amounts[1],
            amountOutMinimum: amountOutMinimum
        });

        amountOut = V3_ROUTER.exactInput(params);

        //transfer to owner
        IERC20(token[0]).safeTransfer(owner, amounts[0]);

        emit Swap(msg.sender, token[0], token[2], amountIn, amountOut);
    }

    function exactOutputMultihop(
        address[3] memory token,
        uint24[2] memory fee,
        uint256 amountInMax,
        uint256 amountOutDesired,
        uint256 deadline
    ) external returns (uint256 amountIn) {
        //transfer the token to this contract and give approval
        IERC20(token[0]).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(token[0]).safeIncreaseAllowance(UNISWAP_V3_ROUTER, amountInMax);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        ISwapV3Router.ExactOutputParams memory params = ISwapV3Router.ExactOutputParams({
            path: abi.encodePacked(token[2], fee[1], token[1], fee[0], token[0]),
            recipient: msg.sender,
            deadline: block.timestamp + deadline,
            amountOut: amountOutDesired,
            amountInMaximum: amountInMax
        });

        amountIn = V3_ROUTER.exactOutput(params);

        //transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);

        if (amountInMax < amountIn + ownerShares) revert InsufficientInput();

        IERC20(token[0]).safeTransfer(owner, ownerShares);

        // refund to msg.sender
        if (amountInMax > amountIn + ownerShares) {
            IERC20(token[0]).safeDecreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax - (amountIn + ownerShares));
            IERC20(token[0]).safeTransfer(msg.sender, amountInMax - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, token[0], token[2], amountIn, amountOutDesired);
    }

    // These functions below are for tokens that require fee when doing transactions
    // 7. token exact input -> token
    function v2SwapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadlineInSeconds
    ) external {
        //split the token
        uint256[2] memory dividedAmounts = splitTokenValue(amountIn);

        //approval and stuff
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(UNISWAP_V2_ROUTER, dividedAmounts[1]);

        //swap
        address[] memory path = createPath(tokenIn, tokenOut);
        V2_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            dividedAmounts[1], amountOutMin, path, msg.sender, block.timestamp + deadlineInSeconds
        );

        //transfer to owner
        IERC20(tokenIn).safeTransfer(owner, dividedAmounts[0]);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, uint256(0));
    }

    // 8. ETH exact input -> token
    function v2SwapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        uint256 deadlineInSeconds
    ) external payable {
        //split the token
        uint256[2] memory dividedAmounts = splitTokenValue(msg.value);

        //swap
        address[] memory path = createPath(WETH, tokenOut);

        V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: dividedAmounts[1]}(
            amountOutMin, path, msg.sender, block.timestamp + deadlineInSeconds
        );

        //transfer owner's share
        safeTransferETH(owner, dividedAmounts[0]);

        emit Swap(msg.sender, address(0), tokenOut, msg.value, uint256(0));
    }

    // 9. Token exact input -> ETH
    function v2SwapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadlineInSeconds
    ) external {
        //split the token
        uint256[2] memory dividedAmounts = splitTokenValue(amountIn); //split the token

        //transfer and approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(UNISWAP_V2_ROUTER, dividedAmounts[1]);

        //swap
        address[] memory path = createPath(tokenIn, WETH);
        V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            dividedAmounts[1], amountOutMin, path, msg.sender, block.timestamp + deadlineInSeconds
        );

        //transfer owner's shares
        IERC20(tokenIn).safeTransfer(owner, dividedAmounts[0]);

        emit Swap(msg.sender, address(0), tokenIn, amountIn, uint256(0));
    }

    //---------------Uniswap V3 Starts Here----------------------//
    function v3SwapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut) {
        //split the token
        uint256[2] memory dividedAmounts = splitTokenValue(amountIn); //split the token

        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), dividedAmounts[1]);
        console.log("funds transferred... preparing params");

        //swap
        ISwapV3Router.ExactInputSingleParams memory params = ISwapV3Router.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountIn: dividedAmounts[1],
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountOut = V3_ROUTER.exactInputSingle(params);
        console.log("swap finished. transferring to owner...");

        //transfer to owner
        IERC20(tokenIn).safeTransfer(owner, dividedAmounts[0]);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    //how to divide the amount in?
    function v3SwapExactOutputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOutDesired,
        uint256 amountInMax,
        uint256 deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {
        //transfer the token to this contract and give approval
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax);

        //swap
        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + deadlineInSeconds,
            amountOut: amountOutDesired,
            amountInMaximum: amountInMax,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        amountIn = V3_ROUTER.exactOutputSingle(params);

        //transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);

        if (amountInMax < amountIn + ownerShares) revert InsufficientInput();

        IERC20(tokenIn).safeTransfer(owner, ownerShares);

        // refund to msg.sender
        if (amountInMax > amountIn + ownerShares) {
            IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V3_ROUTER), 0);
            IERC20(tokenIn).safeTransfer(msg.sender, amountInMax - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOutDesired);
    }

    /*
    token[0] = token input (in)
    token[1] = token intermediary (med)
    token[2] = token output (out)

    fee[0] = fee In-Med
    fee[1] = fee Med-Out
    */

    function v3ExactInputMultihop(
        address[3] memory token,
        uint24[2] memory fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        IERC20(token[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        //split the token
        uint256[2] memory dividedAmounts = splitTokenValue(amountIn); //split the token

        IERC20(token[0]).safeIncreaseAllowance(UNISWAP_V3_ROUTER, dividedAmounts[1]);

        ISwapV3Router.ExactInputParams memory params = ISwapV3Router.ExactInputParams({
            path: abi.encodePacked(token[0], fee[0], token[1], fee[1], token[2]),
            recipient: msg.sender,
            deadline: block.timestamp + deadline,
            amountIn: dividedAmounts[1],
            amountOutMinimum: amountOutMinimum
        });

        amountOut = V3_ROUTER.exactInput(params);

        //transfer to owner
        IERC20(token[0]).safeTransfer(owner, dividedAmounts[0]);

        emit Swap(msg.sender, token[0], token[2], amountIn, amountOut);
    }

    function v3ExactOutputMultihop(
        address[3] memory token,
        uint24[2] memory fee,
        uint256 amountInMax,
        uint256 amountOutDesired,
        uint256 deadline
    ) external returns (uint256 amountIn) {
        //transfer the token to this contract and give approval
        IERC20(token[0]).safeTransferFrom(msg.sender, address(this), amountInMax);
        IERC20(token[0]).safeIncreaseAllowance(UNISWAP_V3_ROUTER, amountInMax);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        ISwapV3Router.ExactOutputParams memory params = ISwapV3Router.ExactOutputParams({
            path: abi.encodePacked(token[2], fee[1], token[1], fee[0], token[0]),
            recipient: msg.sender,
            deadline: block.timestamp + deadline,
            amountOut: amountOutDesired,
            amountInMaximum: amountInMax
        });

        amountIn = V3_ROUTER.exactOutput(params);

        //transfer to owner
        uint256 ownerShares = devSharesExactOut(amountIn);

        if (amountInMax < amountIn + ownerShares) revert InsufficientInput();

        IERC20(token[0]).safeTransfer(owner, ownerShares);

        // refund to msg.sender
        if (amountInMax > amountIn + ownerShares) {
            IERC20(token[0]).safeDecreaseAllowance(address(UNISWAP_V3_ROUTER), amountInMax - (amountIn + ownerShares));
            IERC20(token[0]).safeTransfer(msg.sender, amountInMax - (amountIn + ownerShares));
        }

        emit Swap(msg.sender, token[0], token[2], amountIn, amountOutDesired);
    }

    function getPoolAddress(address tokenA, address tokenB, uint24 fee) external view returns (address pool) {
        return V3_FACTORY.getPool(tokenA, tokenB, fee);
    }

    //---------------Global Variable Changer Functions----------------------//
    function updateFee(uint256 newExchangeFee) external onlyDev {
        FEE_EXCHANGE = newExchangeFee;
        emit UpdateFee(FEE_EXCHANGE);
    }

    function updateDev(address newDev) external onlyDev {
        require(newDev != address(0), "input is address zero");
        dev = payable(newDev);
        emit UpdateDev(newDev);
    }

    function updateOwner(address newOwner) external onlyDev {
        require(newOwner != address(0), "input is address zero");
        owner = payable(newOwner);
        emit UpdateOwner(newOwner);
    }

    //---------------Helper Functions----------------------//
    // create path
    function createPath(address tokenIn, address tokenOut) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn; //input token
        path[1] = tokenOut; //output token
        return path;
    }

    //for exact input
    function splitTokenValue(uint256 amount) internal view returns (uint256[2] memory values) {
        values[0] = (amount * FEE_EXCHANGE) / FEE_DENOM; //amount To Owner
        values[1] = amount - values[0]; //amount To Swap
    }

    //for exact output
    // function estAmountInMax(address tokenIn, address tokenOut, uint256 amountOutDesired)
    //     external
    //     view
    //     returns (uint256 amountInMaxEst)
    // {
    //     uint256 amountIn = v2GetEstimatedIn(amountOutDesired, tokenIn, tokenOut); //calculate estimation
    //     amountInMaxEst = amountIn + ((amountIn * FEE_EXCHANGE) / FEE_DENOM); //calculate estimation that includes fee
    // }

    function devSharesExactOut(uint256 amountIn) internal view returns (uint256 ownerShares) {
        ownerShares = amountIn * FEE_EXCHANGE / FEE_DENOM;
        //addedAmountIn = amountIn + ownerShares; //update amountIn with added fee
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    //---------------Universal Getter Functions----------------------//

    function checkETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function checkTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawETH() external onlyDev {
        safeTransferETH(dev, address(this).balance);
    }

    function withdrawToken(address token) external onlyDev {
        IERC20(token).safeTransfer(dev, IERC20(token).balanceOf(address(this)));
    }

    receive() external payable {}
    fallback() external payable {}
}
