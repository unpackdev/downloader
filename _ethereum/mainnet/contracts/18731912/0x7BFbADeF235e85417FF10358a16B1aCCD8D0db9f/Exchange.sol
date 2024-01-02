// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ICurve.sol";
import "./IStETH.sol";
import "./IWstETH.sol";
import "./IExchange.sol";
import "./IWeth.sol";

contract ETHLeverExchange is IExchange {
    using SafeERC20 for IERC20;
    address public leverSS;

    address public weth;

    address public curvePool;

    address public stETH;
    address public wstETH;

    constructor(
        address _weth,
        address _leverSS,
        address _curvePool,
        address _stETH,
        address _wstETH
    ) {
        weth = _weth;
        stETH = _stETH;
        wstETH = _wstETH;
        leverSS = _leverSS;
        curvePool = _curvePool;
        IERC20(stETH).safeApprove(_wstETH, type(uint256).max);
        IERC20(stETH).safeApprove(_curvePool, type(uint256).max);
    }
    receive() external payable {}
    
    modifier onlyLeverSS() {
        require(msg.sender == leverSS, "ONLY_LEVER_VAULT_CALL");
        _;
    }
    function swap(address tokenIn,address tokenOut,uint256 amount,uint256 minAmount) external override onlyLeverSS returns(uint256){
        IERC20(tokenIn).safeTransferFrom(leverSS,address(this),amount);
        if (tokenIn == weth){
            if (tokenOut ==  stETH){
                uint256 balance = swapEthToStEth(amount,minAmount);
                IERC20(tokenOut).safeTransfer(leverSS, balance);
                return balance;
            }else if(tokenOut ==  wstETH){
                minAmount = IWstETH(tokenOut).getStETHByWstETH(minAmount);
                uint256 balance = swapEthToStEth(amount,minAmount);
                balance = IWstETH(tokenOut).wrap(balance);
                IERC20(tokenOut).safeTransfer(leverSS, balance);
                return balance;
            }else{
                require(false,"INVALID_SWAP");
            }
        }else if (tokenOut == weth){
            if (tokenIn ==  stETH){
                uint256 balance =  swapSTEthToEth(amount,minAmount);
                IERC20(tokenOut).safeTransfer(leverSS, balance);
                return balance;
            }else if(tokenIn == wstETH){
                amount = IWstETH(tokenIn).unwrap(amount);
                uint256 balance = swapSTEthToEth(amount,minAmount);
                IERC20(tokenOut).safeTransfer(leverSS, balance);
                return balance;
            }
        }else{
            require(false,"INVALID_SWAP");
        }
        
    }
    function swapEthToStEth(uint256 amount,uint256 minAmount) internal returns(uint256){
        IWeth(weth).withdraw(amount);
        uint256 curveOut = ICurve(curvePool).get_dy(0, 1, amount);
        if (curveOut < amount) {
            IStETH(stETH).submit{value: amount}(address(this));
            return amount;
        } else {
            require(curveOut>=minAmount,"ETH_STETH_SLIPPAGE");
            return ICurve(curvePool).exchange{value: amount}(
                0,
                1,
                amount,
                minAmount
            );
        }
    }
    function swapSTEthToEth(uint256 amount,uint256 minAmount) internal returns(uint256){
        // Approve STETH to curve
        uint256 balance = ICurve(curvePool).exchange(1, 0, amount, minAmount);
        IWeth(weth).deposit{value: balance}();
        return balance;
    }
    function getCurveInputValue(address tokenIn,address tokenOut,uint256 outAmount,uint256 maxInput)external view override onlyLeverSS returns (uint256){
        if(tokenOut == weth){
            if (tokenIn == stETH){
                uint256 curveOut = ICurve(curvePool).get_dy(1, 0, maxInput);
                return outAmount*maxInput/curveOut+1;
            }else if (tokenIn == wstETH){
                maxInput = IWstETH(tokenIn).getStETHByWstETH(maxInput);
                uint256 curveOut = ICurve(curvePool).get_dy(1, 0, maxInput);
                return IWstETH(tokenIn).getWstETHByStETH(outAmount*maxInput/curveOut+1);
            }
        }else{
            require(false,"INVALID_SWAP");
        }
    }
    /*
    function swapExactETH(
        uint256 input,
        uint256 output
    ) external override onlyLeverSS {
        require(
            IERC20(stETH).balanceOf(_msgSender()) >= input,
            "INSUFFICIENT_STETH"
        );
        require(
            IERC20(stETH).allowance(_msgSender(), address(this)) >= input,
            "INSUFFICIENT_ALLOWANCE"
        );

        // ETH output
        uint256 ethOut = ICurve(curvePool).get_dy(1, 0, input);
        require(ethOut >= output, "EXTREME_MARKET");

        // StETH percentage
        uint256 toSwap = (input * output) / ethOut;

        // Transfer STETH from SS to exchange
        TransferHelper.safeTransferFrom(
            stETH,
            _msgSender(),
            address(this),
            toSwap
        );

        // Approve STETH to curve
        IERC20(stETH).approve(curvePool, 0);
        IERC20(stETH).approve(curvePool, toSwap);
        ICurve(curvePool).exchange(1, 0, toSwap, output);

        uint256 ethBal = address(this).balance;

        require(ethBal >= output, "STETH_ETH_SLIPPAGE");

        // Transfer STETH to LeveraSS
        TransferHelper.safeTransferETH(leverSS, ethBal);
    }
    */
}
