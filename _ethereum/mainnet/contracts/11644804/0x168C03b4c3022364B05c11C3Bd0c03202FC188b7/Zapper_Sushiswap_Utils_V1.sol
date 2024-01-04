// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

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
///@notice This contract provides liquidity related utility functions for Sushiswap
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);

    function allPairsLength() external view returns (uint256);

    function allPairs(uint256) external view returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Zapper_Sushiswap_Utils_V1 {
    using SafeMath for uint256;

    IUniswapV2Factory private constant SushiswapFactory = IUniswapV2Factory(
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
    );

    /**
    @return numPools- total number of pools within this protocol
     */
    function numPools() public view returns (uint256) {
        return SushiswapFactory.allPairsLength();
    }

    /**
    @param _start pool index to start at
    @param _end pool index to end at
    @dev to get all pools use 0 for start and end indicies
    @return Array of Uniswap V2 Exchange Addresses
     */
    function pools(uint256 _start, uint256 _end)
        external
        view
        returns (address[] memory _pools)
    {
        if (_start == 0 && _end == 0) {
            _start = 0;
            _end = numPools();
        }

        _pools = new address[](_end.sub(_start));
        uint256 j;

        for (uint256 i = _start; i < _end; i++) {
            _pools[j++] = SushiswapFactory.allPairs(i);
        }

        return _pools;
    }

    /**
    @param _pools to get tokens for
    @return Tokens0- token0 belonging to each of the input pools
    @return Tokens1- token1 belonging to each of the input pools
     */
    function tokens(address[] calldata _pools)
        external
        pure
        returns (address[] memory tokens0, address[] memory tokens1)
    {
        tokens0 = new address[](_pools.length);
        tokens1 = new address[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(_pools[i]);
            tokens0[i] = pair.token0();
            tokens1[i] = pair.token1();
        }
    }

    /**
    @param _pools to get reserves for
    @return reserves1- reserves of token0 belonging to each of the input pools
    @return reserves0- reserves of token1 belonging to each of the input pools
     */
    function reserves(address[] calldata _pools)
        external
        view
        returns (uint112[] memory reserves0, uint112[] memory reserves1)
    {
        reserves0 = new uint112[](_pools.length);
        reserves1 = new uint112[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(_pools[i])
                .getReserves();
            reserves0[i] = reserve0;
            reserves1[i] = reserve1;
        }
    }

    /**
    @param _pools to get pool token supplies for
    @return _totalSupplies- total supply of LP tokens belonging to 
    each of the input pools
     */
    function totalSupplies(address[] calldata _pools)
        external
        view
        returns (uint256[] memory _totalSupplies)
    {
        _totalSupplies = new uint256[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            _totalSupplies[i] = IUniswapV2Pair(_pools[i]).totalSupply();
        }
    }

    /**
    @param _account to get LP token balances for
    @param _pools to get pool token supplies for
    @return _poolTokenBalances- balances of LP tokens belonging to 
    the account from each of the input pools
     */
    function poolTokenBalances(address[] calldata _pools, address _account)
        external
        view
        returns (uint256[] memory _poolTokenBalances)
    {
        _poolTokenBalances = new uint256[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            _poolTokenBalances[i] = IUniswapV2Pair(_pools[i]).balanceOf(
                _account
            );
        }
    }

    /**
    @notice This function is used to get the underlying token balance
    of a pool given an arbitrary quantity of LP tokens
    @param _pools to get pool token supplies for
    @param _poolTokens quantity of LP tokens to get underlying balance of
    @return underlyingToken0Balance- underlying balances of token 0 belonging 
    to each of the input pools
    @return underlyingToken1Balance- underlying balances of token 1 belonging 
    to each of the input pools
     */
    function underlyingtokenBalances(
        address[] calldata _pools,
        uint256[] calldata _poolTokens
    )
        external
        view
        returns (
            uint256[] memory underlyingToken0Balance,
            uint256[] memory underlyingToken1Balance
        )
    {
        underlyingToken0Balance = new uint256[](_poolTokens.length);
        underlyingToken1Balance = new uint256[](_poolTokens.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(_pools[i]);
            uint256 totalSupply = pair.totalSupply();
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

            underlyingToken0Balance[i] =
                _poolTokens[i].mul(reserve0) /
                totalSupply;
            underlyingToken1Balance[i] =
                _poolTokens[i].mul(reserve1) /
                totalSupply;
        }
    }
}