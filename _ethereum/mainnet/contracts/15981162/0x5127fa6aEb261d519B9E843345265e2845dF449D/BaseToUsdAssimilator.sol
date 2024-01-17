// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";

import "./IVaultPoolBalances.sol";

contract BaseToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;

    IERC20 public immutable usdc;
    IOracle public immutable oracle;
    IERC20 public immutable baseToken;
    uint256 public immutable baseDecimals;

    constructor(
        uint256 _baseDecimals,
        IERC20 _baseToken,
        IERC20 _quoteToken,
        IOracle _oracle
    ) {
        baseDecimals = _baseDecimals;
        baseToken = _baseToken;
        usdc = _quoteToken;
        oracle = _oracle;
    }

    function getRate() public view override returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        return uint256(price);
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(baseDecimals) * 1e8) / _rate;
    }

    function _getBalancesFromVault(
        address vault,
        bytes32 poolId,
        address quoteTokenAddressToCompare
    ) internal view returns (uint256 baseTokenBal, uint256 quoteTokenBal) {
        (IERC20[] memory tokens, uint256[] memory balances, ) = IVaultPoolBalances(vault).getPoolTokens(poolId);

        if (address(tokens[0]) == quoteTokenAddressToCompare) {
            baseTokenBal = balances[1];
            quoteTokenBal = balances[0];
        } else if (address(tokens[1]) == quoteTokenAddressToCompare) {
            baseTokenBal = balances[0];
            quoteTokenBal = balances[1];
        } else {
            revert('_getBalancesFromVault: usdc is not present in token array returned by Vault.getPoolTokens method');
        }
    }

    function viewRawAmountLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        int128 _amount,
        address vault,
        bytes32 poolId
    ) external view override returns (uint256 amount_) {
        (uint256 baseTokenBal, uint256 usdcBal) = _getBalancesFromVault(vault, poolId, address(usdc));

        if (baseTokenBal <= 0) return 0;

        // base decimals
        baseTokenBal = baseTokenBal.mul(1e18).div(_baseWeight);
        usdcBal = usdcBal.mul(1e18).div(_quoteWeight);
        uint256 _rate = usdcBal.mul(baseDecimals).div(baseTokenBal);
        amount_ = (_amount.mulu(baseDecimals) * 1e6) / _rate;
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(baseDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case baseToken
    function viewNumeraireBalance(address vault, bytes32 poolId) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        (uint256 baseTokenBal, ) = _getBalancesFromVault(vault, poolId, address(usdc));

        if (baseTokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((baseTokenBal * _rate) / 1e8).divu(baseDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case baseToken
    // adds intakeAmount to baseTokenBal to simulate LP deposit
    function virtualViewNumeraireBalanceIntake(
        address vault,
        bytes32 poolId,
        uint256 intakeAmount
    ) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        (uint256 baseTokenBal, ) = _getBalancesFromVault(vault, poolId, address(usdc));
        baseTokenBal += intakeAmount;

        if (baseTokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((baseTokenBal * _rate) / 1e8).divu(baseDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case baseToken
    // subtracts outputAmount to baseTokenBal to simulate LP withdrawal
    function virtualViewNumeraireBalanceOutput(
        address vault,
        bytes32 poolId,
        uint256 outputAmount
    ) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        (uint256 baseTokenBal, ) = _getBalancesFromVault(vault, poolId, address(usdc));
        baseTokenBal = baseTokenBal - outputAmount;

        if (baseTokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((baseTokenBal * _rate) / 1e8).divu(baseDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case baseToken
    // called for swaps
    function viewNumeraireAmountAndBalance(
        uint256 _amount,
        address vault,
        bytes32 poolId
    ) external view override returns (int128 amount_, int128 balance_) {
        uint256 _rate = getRate();
        amount_ = ((_amount * _rate) / 1e8).divu(baseDecimals);

        (uint256 baseTokenBal, ) = _getBalancesFromVault(vault, poolId, address(usdc));

        balance_ = ((baseTokenBal * _rate) / 1e8).divu(baseDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case baseToken
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio. This is in here to prevent LPs from losing out on future oracle price updates
    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        // address _addr,
        address vault,
        bytes32 poolId
    ) external view override returns (int128 balance_) {
        (uint256 baseTokenBal, uint256 usdcBal) = _getBalancesFromVault(vault, poolId, address(usdc));

        if (baseTokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        usdcBal = usdcBal.mul(1e18).div(_quoteWeight);
        uint256 _rate = usdcBal.mul(1e18).div(baseTokenBal.mul(1e18).div(_baseWeight));

        balance_ = ((baseTokenBal * _rate) / 1e6).divu(1e18);
    }
}
