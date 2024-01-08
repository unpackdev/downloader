// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract migrates liquidity from the Sushi yveCRV/ETH Pickle Jar to the Sushi yvBOOST/ETH Pickle Jar
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./Ownable.sol";
import "./SafeERC20.sol";

interface IPickleJar {
    function token() external view returns (address);

    function withdraw(uint256 _shares) external;

    function getRatio() external view returns (uint256);

    function deposit(uint256 amount) external;
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface IYearnZapIn {
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        address superVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable returns (uint256 yvBoostRec);
}

contract yvBoost_Migrator_V1_0_1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public stopped = false;

    address constant yveCRV_ETH_Sushi =
        0x10B47177E92Ef9D5C6059055d92DdF6290848991;
    address constant yveCRV_ETH_pJar =
        0x5Eff6d166D66BacBC1BF52E2C54dD391AE6b1f48;

    address constant yvBOOST_ETH_Sushi =
        0x9461173740D27311b176476FA27e94C681b1Ea6b;
    address constant yvBOOST_ETH_pJar =
        0xCeD67a187b923F0E5ebcc77C7f2F7da20099e378;

    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;

    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;

    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    IYearnZapIn yearnZapIn;

    constructor(address _yearnZapIn) public {
        yearnZapIn = IYearnZapIn(_yearnZapIn);
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
    @notice This function migrates pTokens from pSushi yveCRV-ETH to pSushi yveBOOST-ETH 
    @param IncomingLP Quantity of pSushi yveCRV-ETH tokens to migrate
    @param minPTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @return pTokensRec- Quantity of pSushi yveBOOST-ETH tokens acquired
     */
    function Migrate(uint256 IncomingLP, uint256 minPTokens)
        external
        stopInEmergency
        returns (uint256 pTokensRec)
    {
        IERC20(yveCRV_ETH_pJar).safeTransferFrom(
            msg.sender,
            address(this),
            IncomingLP
        );

        uint256 underlyingReceived = _jarWithdraw(yveCRV_ETH_pJar, IncomingLP);

        (uint256 amountA, uint256 amountB, address tokenA, ) =
            _sushiWithdraw(underlyingReceived);

        uint256 wethRec = tokenA == yveCRV ? amountB : amountA;

        uint256 yvBoostRec =
            _yearnDeposit(tokenA == yveCRV ? amountA : amountB);

        IUniswapV2Pair pair = IUniswapV2Pair(yvBOOST_ETH_Sushi);

        uint256 token0Amt = pair.token0() == yvBOOST ? yvBoostRec : wethRec;
        uint256 token1Amt = pair.token1() == yvBOOST ? yvBoostRec : wethRec;

        uint256 sushiLpRec =
            _sushiDeposit(pair.token0(), pair.token1(), token0Amt, token1Amt);

        pTokensRec = _jarDeposit(sushiLpRec);

        require(pTokensRec >= minPTokens, "ERR: High Slippage");

        IERC20(yvBOOST_ETH_pJar).transfer(msg.sender, pTokensRec);
    }

    function _jarWithdraw(address fromJar, uint256 amount)
        internal
        returns (uint256 underlyingReceived)
    {
        uint256 iniUnderlyingBal = _getBalance(yveCRV_ETH_Sushi);
        IPickleJar(fromJar).withdraw(amount);
        underlyingReceived = _getBalance(yveCRV_ETH_Sushi).sub(
            iniUnderlyingBal
        );
    }

    function _jarDeposit(uint256 amount)
        internal
        returns (uint256 pTokensReceived)
    {
        _approveToken(yvBOOST_ETH_Sushi, yvBOOST_ETH_pJar, amount);

        uint256 iniYVaultBal = _getBalance(yvBOOST_ETH_pJar);

        IPickleJar(yvBOOST_ETH_pJar).deposit(amount);

        pTokensReceived = _getBalance(yvBOOST_ETH_pJar).sub(iniYVaultBal);
    }

    function _yearnDeposit(uint256 amountIn)
        internal
        returns (uint256 yvBoostRec)
    {
        _approveToken(yveCRV, address(yearnZapIn), amountIn);

        yvBoostRec = yearnZapIn.ZapIn(
            yveCRV,
            amountIn,
            yvBOOST,
            address(0),
            false,
            0,
            yveCRV,
            address(0),
            "",
            address(0)
        );
    }

    function _sushiWithdraw(uint256 IncomingLP)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            address tokenA,
            address tokenB
        )
    {
        _approveToken(yveCRV_ETH_Sushi, address(sushiSwapRouter), IncomingLP);

        IUniswapV2Pair pair = IUniswapV2Pair(yveCRV_ETH_Sushi);

        address token0 = pair.token0();
        address token1 = pair.token1();
        (amountA, amountB) = sushiSwapRouter.removeLiquidity(
            token0,
            token1,
            IncomingLP,
            1,
            1,
            address(this),
            deadline
        );
        return (amountA, amountB, tokenA, tokenB);
    }

    function _sushiDeposit(
        address toUnipoolToken0,
        address toUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        _approveToken(toUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(toUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                toUnipoolToken0,
                toUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        //Returning Residue in token0, if any
        if (token0Bought.sub(amountA) > 0) {
            IERC20(toUnipoolToken0).safeTransfer(
                msg.sender,
                token0Bought.sub(amountA)
            );
        }

        //Returning Residue in token1, if any
        if (token1Bought.sub(amountB) > 0) {
            IERC20(toUnipoolToken1).safeTransfer(
                msg.sender,
                token1Bought.sub(amountB)
            );
        }

        return LP;
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 _token = IERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    function updateYearnZapIn(address _yearnZapIn) external onlyOwner {
        yearnZapIn = IYearnZapIn(_yearnZapIn);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }
}
