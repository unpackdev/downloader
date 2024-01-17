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

import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";

import "./IVaultPoolBalances.sol";

contract UsdcToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    IOracle public immutable oracle;
    IERC20 public immutable usdc;

    constructor(IOracle _oracle, IERC20 _usdc) {
        oracle = _oracle;
        usdc = _usdc;
    }

    uint256 private constant DECIMALS = 1e6;

    // solhint-disable-next-line
    function getRate() public view override returns (uint256) {
        return uint256(oracle.latestAnswer());
    }

    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(DECIMALS) * 1e8) / _rate;
    }

    function viewRawAmountLPRatio(
        uint256,
        uint256,
        int128 _amount,
        address,
        bytes32
    ) external pure override returns (uint256 amount_) {
        amount_ = _amount.mulu(DECIMALS);
    }

    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);
    }

    function _getBalancesFromVault(
        address vault,
        bytes32 poolId,
        address quoteTokenAddressToCompare
    ) internal view returns (uint256 quoteTokenBal) {
        (IERC20[] memory tokens, uint256[] memory balances, ) = IVaultPoolBalances(vault).getPoolTokens(poolId);

        if (address(tokens[0]) == quoteTokenAddressToCompare) {
            quoteTokenBal = balances[0];
        } else if (address(tokens[1]) == quoteTokenAddressToCompare) {
            quoteTokenBal = balances[1];
        } else {
            revert(
                '_getBalancesFromVault: quoteTokenAddress is not present in token array returned by Vault.getPoolTokens method'
            );
        }
    }

    function viewNumeraireBalance(address vault, bytes32 poolId) public view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 quoteBalance = _getBalancesFromVault(vault, poolId, address(usdc));

        if (quoteBalance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((quoteBalance * _rate) / 1e8).divu(DECIMALS);
    }

    // adds intakeAmount to baseTokenBal to simulate LP deposit
    function virtualViewNumeraireBalanceIntake(
        address vault,
        bytes32 poolId,
        uint256 intakeAmount
    ) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 quoteBalance = _getBalancesFromVault(vault, poolId, address(usdc));
        quoteBalance += intakeAmount;

        if (quoteBalance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((quoteBalance * _rate) / 1e8).divu(DECIMALS);
    }

    // adds outputAmount to baseTokenBal to simulate LP deposit
    function virtualViewNumeraireBalanceOutput(
        address vault,
        bytes32 poolId,
        uint256 outputAmount
    ) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 quoteBalance = _getBalancesFromVault(vault, poolId, address(usdc));

        quoteBalance = quoteBalance - outputAmount;

        if (quoteBalance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((quoteBalance * _rate) / 1e8).divu(DECIMALS);
    }

    // views the numeraire value of the current balance of the reserve wrt to USD
    // since this is already the USD assimlator, the ratio is just 1
    function viewNumeraireBalanceLPRatio(
        uint256,
        uint256,
        // address _addr,
        address vault,
        bytes32 poolId
    ) external view override returns (int128 balance_) {
        (IERC20[] memory tokens, uint256[] memory balances, ) = IVaultPoolBalances(vault).getPoolTokens(poolId);

        if (address(tokens[0]) == address(usdc)) {
            return balances[0].divu(DECIMALS);
        } else {
            return balances[1].divu(DECIMALS);
        }
    }

    function viewNumeraireAmountAndBalance(
        uint256 _amount,
        address vault,
        bytes32 poolId
    ) external view override returns (int128 amount_, int128 balance_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);

        uint256 quoteBalance = _getBalancesFromVault(vault, poolId, address(usdc));

        balance_ = ((quoteBalance * _rate) / 1e8).divu(DECIMALS);
    }
}
