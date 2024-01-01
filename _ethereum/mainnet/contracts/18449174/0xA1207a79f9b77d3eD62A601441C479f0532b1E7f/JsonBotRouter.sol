// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// UniswapV2Router02 and IERC20 interfaces
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Ownable contract
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        owner = newOwner;
    }
}

contract JsonBotRouter is Ownable {
    event AvgPriceUpdated(uint256 newAvgPrice); // Define an event

    IUniswapV2Router02 public uniswapRouter;
    address public feeReceiver;
    uint256 public feePercentage; // Fee percentage in basis points (1 basis point = 0.01%)

    constructor() {
        address currentRouter;

        if (block.chainid == 56) {
            currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PCS Router
        } else if (block.chainid == 97) {
            currentRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // PCS Testnet
        } else if (block.chainid == 43114) {
            currentRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //Avax Mainnet
        } else if (block.chainid == 137) {
            currentRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Polygon Ropsten
        } else if (block.chainid == 250) {
            currentRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; //SpookySwap FTM
        } else if (block.chainid == 3) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Ropsten
        } else if (block.chainid == 1 || block.chainid == 4) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet
        } else {
            revert();
        }

        uniswapRouter = IUniswapV2Router02(currentRouter);
        feeReceiver = msg.sender; // Initially, the contract owner is the fee receiver
        feePercentage = 100;
    }

    // ------------------ only owner functions ------------------

    function setFeeReceiver(address _newFeeReceiver) external onlyOwner {
        feeReceiver = _newFeeReceiver;
    }

    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(
            _newFeePercentage <= 100,
            "Fee should be less than 100 basis points"
        );
        feePercentage = _newFeePercentage;
    }

    function withdrawEth() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        return success;
    }

    function withdrawERC20(
        address _tokenAddress
    ) external onlyOwner returns (bool) {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(msg.sender, balance);
        return success;
    }

    // ------------------ public functions ------------------

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 _amountOut,
        address _tokenAddress,
        uint256 _avgPrice,
        uint256 _slippage // slippage is in basis points (1 basis = 0.1%)
    ) external payable {
        uint256 feeAmount = (msg.value * feePercentage) / 10000;
        uint256 swapAmount = msg.value - feeAmount;
        require(feeAmount > 0 && swapAmount > 0, "Insufficient ETH amount");

        IERC20 token = IERC20(_tokenAddress);
        uint256 initialBalance = token.balanceOf(msg.sender);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenAddress;

        // price of 1 token
        uint256 currentPrice = uniswapRouter.getAmountsIn(
            1 * (10 ** token.decimals()),
            path
        )[0];

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: swapAmount
        }(
            slippageCalculator(_amountOut, _slippage, true),
            path,
            msg.sender,
            block.timestamp
        );

        uint256 finalBalance = token.balanceOf(msg.sender);
        uint256 tokensPurchased = finalBalance - initialBalance;

        // Transfer fee to feeReceiver
        (bool success, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, "Fee transfer failed.");

        // Calculate new average price
        if (_avgPrice == 0 && initialBalance > 0) {
            emit AvgPriceUpdated(currentPrice);
        } else {
            emit AvgPriceUpdated(
                ((_avgPrice * initialBalance) +
                    (tokensPurchased * currentPrice)) /
                    (initialBalance + tokensPurchased)
            );
        }
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 _amountOut,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _slippage
    ) external {
        require(_tokenAmount > 0, "Token amount must be greater than zero");
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), _tokenAmount),
            "Token transfer to contract failed"
        );

        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();

        require(
            token.approve(address(uniswapRouter), _tokenAmount),
            "Approval failed"
        );
        uint256 initialBalance = address(this).balance;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            slippageCalculator(_amountOut, _slippage, false),
            path,
            address(this),
            block.timestamp
        );

        uint256 finalBalance = address(this).balance;
        uint256 ethRecieved = finalBalance > initialBalance
            ? finalBalance - initialBalance
            : 0;
        uint256 feeAmount = (ethRecieved * feePercentage) / 10000;
        uint256 swapAmount = ethRecieved - feeAmount;

        // Transfer fee to feeReceiver
        (bool success, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, "Fee transfer failed.");

        // Transfer eth to msg.sender
        (success, ) = payable(msg.sender).call{value: swapAmount}("");
        require(success, "Eth transfer failed.");
    }

    function slippageCalculator(
        uint256 _amount,
        uint256 _slippage,
        bool _isBuy
    ) internal view returns (uint256) {
        if (_isBuy) {
            return
                _amount -
                ((_amount * _slippage) / 1000) -
                ((_amount * feePercentage) / 10000);
        } else {
            return _amount - ((_amount * _slippage) / 1000);
        }
    }

    receive() external payable {}
}