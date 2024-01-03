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

import "./ERC20.sol";
import "./ProtocolAdapter.sol";


struct ReserveConfigurationMap {
    uint256 data;
}


struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 currentLiquidityRate;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint8 id;
}


/**
 * @dev LendingPoolAddressesProvider contract interface.
 * Only the functions required for AaveV2VariableDebtAdapter contract are added.
 */
interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (LendingPoolV2);
}


/**
 * @dev LendingPool contract interface.
 * Only the functions required for AaveV2VariableDebtAdapter contract are added.
 */
interface LendingPoolV2 {
    function getReserveData(address) external view returns (ReserveData memory);
}


/**
 * @title Debt adapter for Aave protocol (V2, variable debt).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract AaveV2VariableDebtAdapter is ProtocolAdapter {

    string public constant override adapterType = "Debt";

    string public constant override tokenType = "ERC20";

    address internal immutable addressesProvider_;

    constructor(address addressesProvider) public {
        require(addressesProvider != address(0), "Av2VDA: empty addressesProvider");

        addressesProvider_ = addressesProvider;
    }

    /**
     * @return Amount of debt of the given account for the protocol.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        LendingPoolV2 pool = LendingPoolAddressesProvider(addressesProvider_).getLendingPool();

        address variableDebtTokenAddress = pool.getReserveData(token).variableDebtTokenAddress;

        return ERC20(variableDebtTokenAddress).balanceOf(account);
    }
}
