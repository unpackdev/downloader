// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./ProtocolAdapter.sol";


/**
 * @dev LendingPoolAddressesProvider contract interface.
 * Only the functions required for AaveUniswapDebtAdapter contract are added.
 * The LendingPoolAddressesProvider contract is available here
 * github.com/aave/aave-protocol/blob/master/contracts/configuration/LendingPoolAddressesProvider.sol.
 */
interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (LendingPool);
}


/**
 * @dev LendingPool contract interface.
 * Only the functions required for AaveUniswapDebtAdapter contract are added.
 * The LendingPool contract is available here
 * github.com/aave/aave-protocol/blob/master/contracts/lendingpool/LendingPool.sol.
 */
interface LendingPool {
    function getUserReserveData(address, address) external view returns (uint256, uint256);
}


/**
 * @title Debt adapter for Aave protocol (Uniswap market).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract AaveUniswapDebtAdapter is ProtocolAdapter {

    address internal constant PROVIDER = 0x7fd53085B9A29D236235D6FC593b47C9C33429F1;

    string public constant override adapterType = "Debt";

    string public constant override tokenType = "ERC20";

    /**
     * @return Amount of debt of the given account for the protocol.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        LendingPool pool = LendingPoolAddressesProvider(PROVIDER).getLendingPool();

        (, uint256 debtAmount) = pool.getUserReserveData(token, account);

        return debtAmount;
    }
}
