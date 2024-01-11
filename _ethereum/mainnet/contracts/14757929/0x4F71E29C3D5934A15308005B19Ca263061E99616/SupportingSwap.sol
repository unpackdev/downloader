// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPYESwapRouter.sol";
import "./TransferHelper.sol";
import "./PYESwapLibrary.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IToken.sol";
import "./FeeStore.sol";

abstract contract SupportingSwap is FeeStore, IPYESwapRouter {


    address public override factory;
    address public override WETH;

    event Received(address sender, uint256 value);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PYESwapRouter: EXPIRED');
        _;
    }

    function _swap(address _feeCheck, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(factory, input, output));
            bool isExcluded = PYESwapLibrary.checkIsExcluded(_feeCheck, address(pair));

            uint amountOut = amounts[i + 1];
            {
                uint amountsI = amounts[i];
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                (uint amount0Fee, uint amount1Fee) = PYESwapLibrary._calculateFees(factory, input, output, amountsI, amount0Out, amount1Out, isExcluded);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(factory, output, finalPath) : _to;
                pair.swap(
                    amount0Out, amount1Out, amount0Fee, amount1Fee, to, new bytes(0)
                );

            }
        }
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);
        amounts = PYESwapLibrary.amountsOut(factory, amountIn, path, isExcluded);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        _swap(to, amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]) {
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            (amounts[0], adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );

            amounts = PYESwapLibrary.amountsOut(factory, amounts[0], path, isExcluded);

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );

        } else {
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= amountInMax, "PYESwapRouter: EXCESSIVE_INPUT_AMOUNT");
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );
        }

        _swap(to, amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PYESwapRouter: INVALID_PATH");

        uint eth = msg.value;
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (eth, adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(eth, adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        amounts = PYESwapLibrary.amountsOut(factory, msg.value, path, isExcluded);

        require(amounts[amounts.length - 1] >= amountOutMin, "PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pair, amounts[0]));
        _swap(to, amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');

        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);

        if(path[0] == pairFeeAddress[pair]){
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            (amounts[0],adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0],adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );

            amounts = PYESwapLibrary.amountsOut(factory, amounts[0], path, isExcluded);

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );
        } else {
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );
        }
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');

        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);

        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        amounts = PYESwapLibrary.amountsOut(factory, amountIn, path, isExcluded);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');

        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        bool isExcluded = PYESwapLibrary.checkIsExcluded(to, pair);

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');

            (amounts[0], adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }

            amounts = PYESwapLibrary.amountsOut(factory, amounts[0], path, isExcluded);

            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(pair, amounts[0]));

        } else {
            amounts = PYESwapLibrary.amountsIn(factory, amountOut, path, isExcluded);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(PYESwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        }

        _swap(to, amounts, path, to);
        // refund dust eth, if any
        uint bal = amounts[0] + adminFeeDeduct;
        if (msg.value > bal) TransferHelper.safeTransferETH(msg.sender, msg.value - bal);
    }


    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address _feeCheck, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(factory, input, output));
            bool isExcluded = PYESwapLibrary.checkIsExcluded(_feeCheck, address(pair));

            (uint amountInput, uint amountOutput) = PYESwapLibrary._calculateAmounts(factory, input, output, token0, isExcluded);
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

            (uint amount0Fee, uint amount1Fee) = PYESwapLibrary._calculateFees(factory, input, output, amountInput, amount0Out, amount1Out, isExcluded);

            {
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(factory, output, finalPath) : _to;
                pair.swap(amount0Out, amount1Out, amount0Fee, amount1Fee, to, new bytes(0));
            }
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");

        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');
        uint amountIn = msg.value;

        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    {
        require(path.length == 2, "PYESwapRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');
        address pair = PYESwapLibrary.pairFor(factory, path[0], path[1]);

        if(path[0] == pairFeeAddress[pair]){
            uint adminFeeDeduct = (amountIn * adminFee) / (10000);
            amountIn = amountIn - adminFeeDeduct;
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        _swapSupportingFeeOnTransferTokens(to, path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        amountOutMin;
        if(path[1] == pairFeeAddress[pair]){
            uint adminFeeDeduct = (amountOut * adminFee) / (10000);
            amountOut = amountOut - adminFeeDeduct;
        }
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}