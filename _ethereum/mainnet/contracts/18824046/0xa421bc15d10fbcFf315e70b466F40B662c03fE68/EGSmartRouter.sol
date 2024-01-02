// SPDX-License-Identifier: MIT

/*
  ______ _____  _____                                _____                      _     _____             _            
 |  ____/ ____|/ ____|                              / ____|                    | |   |  __ \           | |           
 | |__ | |  __| (_____      ____ _ _ __    ______  | (___  _ __ ___   __ _ _ __| |_  | |__) |___  _   _| |_ ___ _ __ 
 |  __|| | |_ |\___ \ \ /\ / / _` | '_ \  |______|  \___ \| '_ ` _ \ / _` | '__| __| |  _  // _ \| | | | __/ _ \ '__|
 | |___| |__| |____) \ V  V / (_| | |_) |           ____) | | | | | | (_| | |  | |_  | | \ \ (_) | |_| | ||  __/ |   
 |______\_____|_____/ \_/\_/ \__,_| .__/           |_____/|_| |_| |_|\__,_|_|   \__| |_|  \_\___/ \__,_|\__\___|_|   
                                  | |                                                                                
                                  |_|                                                                                

*/

pragma solidity >=0.8.17;
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";
import "./OwnableUpgradeable.sol";

contract EGSmartRouter is OwnableUpgradeable {
    using TransferHelper for address;
    address public routerAddress;
    address public WETH;

    address public burnAddress;
    uint public burnFee;

    address public treasuryAddress;
    uint public treasuryFee;

    bool public convertToETH;

    receive() external payable {}

    /**
     * @param _routerAddress address of the router
     *
     * @dev initialize the router address
     */
    function initialize(address _routerAddress) external initializer {
        require(
            _routerAddress != address(0),
            "EGSwapSmartRouter: zero address"
        );
        __Ownable_init();
        routerAddress = _routerAddress;
        WETH = IUniswapV2Router02(routerAddress).WETH();
        burnFee = 125;
        treasuryFee = 125;
    }

    /**
     * @param _burnAddress address of the burn wallet
     *
     * @dev set the address of the burn wallet
     */
    function setBurnAddress(address _burnAddress) external onlyOwner {
        require(_burnAddress != address(0), "EGSwapSmartRouter: zero address");
        burnAddress = _burnAddress;
    }

    /**
     * @param _treasuryAddress address of the treasury wallet
     *
     * @dev set the address of the treasury wallet
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(
            _treasuryAddress != address(0),
            "EGSwapSmartRouter: zero address"
        );
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @param _burnFee range [0 ~ 99999], 125 means 0.125%
     *
     * @dev set the burn fee
     */
    function setBurnFee(uint _burnFee) external onlyOwner {
        burnFee = _burnFee;
    }

    /**
     * @param _treasuryFee range [0 ~ 99999], 125 means 0.125%
     *
     * @dev set the treasury fee
     */
    function setTreasuryFee(uint _treasuryFee) external onlyOwner {
        treasuryFee = _treasuryFee;
    }

    /**
     * @param amount amount
     *
     * @dev calculate the burn amount
     */
    function calcBurnFee(uint amount) public view returns (uint) {
        return (amount * burnFee) / 100000;
    }

    /**
     * @param amount amount
     *
     * @dev calculate the treasury amount
     */
    function calcTreasuryFee(uint amount) public view returns (uint) {
        return (amount * treasuryFee) / 100000;
    }

    /**
     * @param amount amount
     *
     * @dev calculate the total fee amount (burn amount + treasury amount)
     */
    function calcRouterFee(uint amount) public view returns (uint) {
        return calcBurnFee(amount) + calcTreasuryFee(amount);
    }

    /**
     * @param _convertToETH true/false
     *
     * @dev set if swap fee or not
     */
    function setConvertToETH(bool _convertToETH) external onlyOwner {
        convertToETH = _convertToETH;
    }

    /**
     * @param token input token address for swap
     * @param amount amount of token
     * @param deadline deadline of swap
     *
     * @dev swap token to ETH and send to treasury wallet
     */
    function transferToTreasury(
        address token,
        uint amount,
        uint deadline
    ) internal {
        require(amount > 0, "EGSwapSmartRouter: zero amount");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "EGSwapSmartRouter: insufficient balance"
        );

        if (convertToETH) {
            token.safeApprove(routerAddress, amount);
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            IUniswapV2Router02(routerAddress)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    path,
                    treasuryAddress,
                    deadline
                );
        } else {
            token.safeTransfer(treasuryAddress, amount);
        }
    }

    /**
     * @param token output token address for swap
     * @param amount amount of ETH
     * @param deadline deadline of swap
     *
     * @dev swap ETH to token and send to burn wallet
     */
    function transferToBurn(
        address token,
        uint amount,
        uint deadline
    ) internal {
        require(amount > 0, "EGSwapSmartRouter: zero amount");
        require(
            address(this).balance >= amount,
            "EGSwapSmartRouter: insufficient balance"
        );

        if (convertToETH) {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = token;
            IUniswapV2Router02(routerAddress)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amount
            }(0, path, burnAddress, deadline);
        } else {
            TransferHelper.safeTransferETH(burnAddress, amount);
        }
    }

    /**
     * @param amountIn amountIn
     * @param path swap path
     *
     * @dev get amounts of swap, cut router fee from output amount
     */
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) public view returns (uint[] memory amounts) {
        amounts = IUniswapV2Router02(routerAddress).getAmountsOut(
            amountIn,
            path
        );
        amounts[amounts.length - 1] =
            amounts[amounts.length - 1] -
            calcRouterFee(amounts[amounts.length - 1]);
    }

    /**
     * @param amountIn amountIn
     * @param amountOutMin minium amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint _contractBalance = IERC20(tokenOut).balanceOf(address(this));

        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenIn.safeApprove(routerAddress, amountIn);
        IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
    }

    /**
     * @param amountIn amountIn
     * @param amountOutMin minium amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        address tokenIn = path[0];
        uint _contractBalance = address(this).balance;

        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenIn.safeApprove(routerAddress, amountIn);
        IUniswapV2Router02(routerAddress).swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint _amountOut = address(this).balance - _contractBalance;
        TransferHelper.safeTransferETH(
            to,
            _amountOut - calcRouterFee(_amountOut)
        );
        if (burnFee > 0) {
            transferToBurn(tokenIn, calcBurnFee(_amountOut), deadline);
        }
        if (treasuryFee > 0) {
            TransferHelper.safeTransferETH(
                treasuryAddress,
                calcTreasuryFee(_amountOut)
            );
        }
    }

    /**
     * @param amountOutMin minium amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        amounts = getAmountsOut(msg.value, path);
        address tokenOut = path[path.length - 1];
        uint _contractBalance = IERC20(tokenOut).balanceOf(address(this));

        IUniswapV2Router02(routerAddress).swapExactETHForTokens{
            value: msg.value
        }(amountOutMin, path, address(this), deadline);

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
    }

    /**
     * @param amountOut amountOut
     * @param path swap path
     *
     * @dev get amounts of swap, cut router fee from output amount
     */
    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) public view returns (uint[] memory amounts) {
        amounts = IUniswapV2Router02(routerAddress).getAmountsIn(
            amountOut,
            path
        );
        amounts[amounts.length - 1] =
            amounts[amounts.length - 1] -
            calcRouterFee(amounts[amounts.length - 1]);
    }

    /**
     * @param amountOut amount of the output token
     * @param amountInMax maximum amount of the input token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint _contractBalance = IERC20(tokenOut).balanceOf(address(this));

        tokenIn.safeTransferFrom(msg.sender, address(this), amounts[0]);
        tokenIn.safeApprove(routerAddress, amounts[0]);
        IUniswapV2Router02(routerAddress).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
    }

    /**
     * @param amountOut amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        address tokenOut = path[path.length - 1];
        uint _contractBalance = IERC20(tokenOut).balanceOf(address(this));

        IUniswapV2Router02(routerAddress).swapETHForExactTokens{
            value: msg.value
        }(amountOut, path, address(this), deadline);

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    /**
     * @param amountOut amount of the output token
     * @param amountInMax maximum amount of the input token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        address tokenIn = path[0];
        uint _contractBalance = address(this).balance;

        tokenIn.safeTransferFrom(msg.sender, address(this), amounts[0]);
        tokenIn.safeApprove(routerAddress, amounts[0]);
        IUniswapV2Router02(routerAddress).swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );

        uint _amountOut = address(this).balance - _contractBalance;
        TransferHelper.safeTransferETH(
            to,
            _amountOut - calcRouterFee(_amountOut)
        );
        if (burnFee > 0) {
            transferToBurn(tokenIn, calcBurnFee(_amountOut), deadline);
        }
        if (treasuryFee > 0) {
            TransferHelper.safeTransferETH(
                treasuryAddress,
                calcTreasuryFee(_amountOut)
            );
        }
    }

    /**
     * @param amountIn amount of the input token
     * @param amountOutMin minimum amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        uint _contractBalance = IERC20(tokenIn).balanceOf(address(this));
        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        uint _amountIn = IERC20(tokenIn).balanceOf(address(this)) -
            _contractBalance;

        _contractBalance = IERC20(tokenOut).balanceOf(address(this));
        tokenIn.safeApprove(routerAddress, _amountIn);
        IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
    }

    /**
     * @param amountIn amount of the input token
     * @param amountOutMin maximum amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        address tokenIn = path[0];
        uint _contractBalance = IERC20(tokenIn).balanceOf(address(this));
        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        uint _amountIn = IERC20(tokenIn).balanceOf(address(this)) -
            _contractBalance;

        _contractBalance = address(this).balance;
        tokenIn.safeApprove(routerAddress, _amountIn);
        IUniswapV2Router02(routerAddress)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );

        uint _amountOut = address(this).balance - _contractBalance;
        TransferHelper.safeTransferETH(
            to,
            _amountOut - calcRouterFee(_amountOut)
        );
        if (burnFee > 0) {
            transferToBurn(tokenIn, calcBurnFee(_amountOut), deadline);
        }
        if (treasuryFee > 0) {
            TransferHelper.safeTransferETH(
                treasuryAddress,
                calcTreasuryFee(_amountOut)
            );
        }
    }

    /**
     * @param amountOutMin minimum amount of the output token
     * @param path swap path
     * @param to recieve address to receive output amount
     * @param deadline deadline
     *
     * @dev swap token and cut router fee from output and send to burn and treasury wallet
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        address tokenOut = path[path.length - 1];
        uint _contractBalance = IERC20(tokenOut).balanceOf(address(this));

        IUniswapV2Router02(routerAddress)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(amountOutMin, path, address(this), deadline);

        uint _amountOut = IERC20(tokenOut).balanceOf(address(this)) -
            _contractBalance;
        tokenOut.safeTransfer(to, _amountOut - calcRouterFee(_amountOut));
        if (burnFee > 0) {
            tokenOut.safeTransfer(burnAddress, calcBurnFee(_amountOut));
        }
        if (treasuryFee > 0) {
            transferToTreasury(tokenOut, calcTreasuryFee(_amountOut), deadline);
        }
    }
}
