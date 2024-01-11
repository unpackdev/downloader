// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DataTypes.sol";
import "./KyokoMath.sol";
import "./PercentageMath.sol";
import "./ReserveLogic.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";

library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMathUpgradeable for uint256;
    using KyokoMath for uint256;
    using PercentageMath for uint256;

    struct CalculateUserAccountDataVars {
        uint256 decimals;
        uint256 tokenUnit;
        uint256 compoundedBorrowBalance;
        uint256 totalDebtInWEI;
        uint256 i;
        address currentReserveAddress;
    }

    /**
    * @dev Calculates the user total Debt in WEI across the reserves.
    * @param user The address of the user
    * @param reservesData Data of all the reserves
    * @param reserves The list of the available reserves
    * @param reservesCount the count of reserves
    * @return The total debt of the user in WEI
    **/
    function calculateUserAccountData(
        address user,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount
    )
        internal
        view
        returns (uint256)
    {
        CalculateUserAccountDataVars memory vars;
        for (vars.i = 0; vars.i < reservesCount; vars.i++) {

            vars.currentReserveAddress = reserves[vars.i];
            DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

            vars.decimals = currentReserve.getDecimal();
            uint256 decimals_ = 1 ether;
            vars.tokenUnit = uint256(decimals_).div(10**vars.decimals);

            uint256 currentReserveBorrows = IERC20Upgradeable(currentReserve.variableDebtTokenAddress).balanceOf(user);
            if (currentReserveBorrows > 0) {
                vars.totalDebtInWEI = vars.totalDebtInWEI.add(
                    uint256(1).mul(currentReserveBorrows).mul(vars.tokenUnit)
                );
            }
        }
        return vars.totalDebtInWEI;
    }
}