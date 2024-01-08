// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SAave.sol";
import "./UserConfiguration.sol";
import "./ReserveConfiguration.sol";
import "./GelatoString.sol";
import "./ILendingPool.sol";
import "./IPriceOracle.sol";
import "./IERC20.sol";
import "./IProtectionActionV2.sol";
import "./IProtectionAction.sol";
import "./SProtectionV2.sol";
import "./ProtectionResolver.sol";

contract ProtectionResolverV2 is ProtectionResolver {
    using GelatoString for string;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    constructor(IProtectionAction _protectionAction)
        ProtectionResolver(_protectionAction)
    {} // solhint-disable-line no-empty-blocks

    /* solhint-disable function-max-lines */
    function multiGetBestColAndDebtData(
        BestColAndDebtDataInput[] memory _bestColAndDebtDataInputs
    ) external view returns (BestColAndDebtDataResult[] memory) {
        BestColAndDebtDataResult[]
            memory results = new BestColAndDebtDataResult[](
                _bestColAndDebtDataInputs.length
            );

        for (uint256 i = 0; i < _bestColAndDebtDataInputs.length; i++) {
            try
                this.getBestColAndDebtData(_bestColAndDebtDataInputs[i])
            returns (BestColAndDebtDataResult memory bCAndDResult) {
                results[i] = bCAndDResult;
            } catch Error(string memory error) {
                results[i] = BestColAndDebtDataResult({
                    id: _bestColAndDebtDataInputs[i].id,
                    debtToken: DebtTknData({
                        reserve: address(0),
                        debtBalanceInETH: 0,
                        rateMode: 0
                    }),
                    colAndLTs: new CollateralAndLT[](0),
                    totalCollateralETH: 0,
                    totalDebtETH: 0,
                    currentLiquidationThreshold: 0,
                    flashloanPremiumBps: 0,
                    message: error.prefix(
                        "ProtectionResolverV2.getBestColAndDebtData failed :"
                    )
                });
            } catch {
                results[i] = BestColAndDebtDataResult({
                    id: _bestColAndDebtDataInputs[i].id,
                    debtToken: DebtTknData({
                        reserve: address(0),
                        debtBalanceInETH: 0,
                        rateMode: 0
                    }),
                    colAndLTs: new CollateralAndLT[](0),
                    totalCollateralETH: 0,
                    totalDebtETH: 0,
                    currentLiquidationThreshold: 0,
                    flashloanPremiumBps: 0,
                    message: "ProtectionResolverV2.getBestColAndDebtData failed :undefined"
                });
            }
        }
        return results;
    }

    /* solhint-disable function-max-lines, code-complexity */
    function getBestColAndDebtData(
        BestColAndDebtDataInput memory _bestColAndDebtDataInput
    ) public view returns (BestColAndDebtDataResult memory result) {
        result.id = _bestColAndDebtDataInput.id;
        IProtectionActionV2 protectionActionV2 = IProtectionActionV2(
            address(protectionAction)
        );

        ILendingPool lendingPool = protectionActionV2.LENDING_POOL();

        DataTypes.UserConfigurationMap memory userConfig = lendingPool
            .getUserConfiguration(_bestColAndDebtDataInput.user);
        if (userConfig.isEmpty()) {
            return result;
        }

        address[] memory reserveList = lendingPool.getReservesList();
        uint256[] memory pricesInETH = IPriceOracle(
            protectionActionV2.ADDRESSES_PROVIDER().getPriceOracle()
        ).getAssetsPrices(reserveList);

        result.colAndLTs = new CollateralAndLT[](reserveList.length);

        for (uint256 i = 0; i < reserveList.length; i++) {
            if (!userConfig.isUsingAsCollateralOrBorrowing(i)) continue;
            {
                CalculateUserAccountDataVars memory vars;

                DataTypes.ReserveData memory reserveData = lendingPool
                    .getReserveData(reserveList[i]);

                (, vars.liquidationThreshold, , vars.decimals, ) = reserveData
                    .configuration
                    .getParams();

                vars.priceInETH = pricesInETH[i];

                vars.collateralBalanceInETH =
                    (vars.priceInETH *
                        IERC20(reserveData.aTokenAddress).balanceOf(
                            _bestColAndDebtDataInput.user
                        )) /
                    10**vars.decimals;

                if (userConfig.isBorrowing(i)) {
                    vars.stableDebtTokenBalanceInETH =
                        (vars.priceInETH *
                            IERC20(reserveData.stableDebtTokenAddress)
                                .balanceOf(_bestColAndDebtDataInput.user)) /
                        10**vars.decimals;
                    vars.variableDebtTokenBalanceInETH =
                        (vars.priceInETH *
                            IERC20(reserveData.variableDebtTokenAddress)
                                .balanceOf(_bestColAndDebtDataInput.user)) /
                        10**vars.decimals;
                }

                result.colAndLTs[i] = CollateralAndLT(
                    reserveList[i],
                    vars.collateralBalanceInETH,
                    vars.liquidationThreshold
                );

                if (
                    vars.variableDebtTokenBalanceInETH >
                    result.debtToken.debtBalanceInETH
                ) {
                    result.debtToken.reserve = reserveList[i];
                    result.debtToken.debtBalanceInETH = vars
                        .variableDebtTokenBalanceInETH;
                    result.debtToken.rateMode = 2;
                }
                if (
                    vars.stableDebtTokenBalanceInETH >
                    result.debtToken.debtBalanceInETH
                ) {
                    result.debtToken.reserve = reserveList[i];
                    result.debtToken.debtBalanceInETH = vars
                        .stableDebtTokenBalanceInETH;
                    result.debtToken.rateMode = 1;
                }
            }
        }

        (
            result.totalCollateralETH,
            result.totalDebtETH,
            ,
            result.currentLiquidationThreshold,
            ,

        ) = lendingPool.getUserAccountData(_bestColAndDebtDataInput.user);

        result.flashloanPremiumBps = lendingPool.FLASHLOAN_PREMIUM_TOTAL();
        result.message = "OK";
    }
    /* solhint-enable function-max-lines, code-complexity */
}
