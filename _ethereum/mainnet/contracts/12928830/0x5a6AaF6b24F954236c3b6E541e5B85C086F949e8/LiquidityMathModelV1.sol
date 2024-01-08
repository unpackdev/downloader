// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./LiquidityMathModelInterface.sol";
import "./MToken.sol";
import "./ErrorReporter.sol";
import "./ExponentialNoError.sol";
import "./AssetHelpers.sol";
import "./Moartroller.sol";
import "./SimplePriceOracle.sol";
import "./Ownable.sol";


contract LiquidityMathModelV1 is LiquidityMathModelInterface, LiquidityMathModelErrorReporter, ExponentialNoError, Ownable, AssetHelpers {


    /**
     * @notice get the maximum asset value that can be still optimized.
     * @notice if protectionId is supplied, the maxOptimizableValue is increased by the protection lock value'
     * which is helpful to recalculate how much of this protection can be optimized again
     */
    function getMaxOptimizableValue(LiquidityMathModelInterface.LiquidityMathArgumentsSet memory arguments) external override view returns (uint){
        uint returnValue;
        uint hypotheticalOptimizableValue = getHypotheticalOptimizableValue(arguments);
        uint totalProtectionLockedValue;
        (totalProtectionLockedValue, ) = getTotalProtectionLockedValue(arguments);
        if(hypotheticalOptimizableValue <= totalProtectionLockedValue){
            returnValue = 0;
        }
        else{
            returnValue = sub_(hypotheticalOptimizableValue, totalProtectionLockedValue);
        }

        return returnValue;
    }

    /**
     * @notice get the maximum value of an asset that can be optimized by protection for the given user
     * @dev optimizable = asset value * MPC
     * @return the hypothetical optimizable value
     * TODO: replace hardcoded 1e18 values
     */
    function getHypotheticalOptimizableValue(LiquidityMathModelInterface.LiquidityMathArgumentsSet memory arguments) public override view returns(uint) {
        uint assetValue = div_(
            mul_(
                div_(
                    mul_(
                    arguments.asset.balanceOf(arguments.account),
                    arguments.asset.exchangeRateStored()
                    ),
                    1e18
                ),
                arguments.oracle.getUnderlyingPrice(arguments.asset)
            ),
            getAssetDecimalsMantissa(arguments.asset.getUnderlying())
        );

        uint256 hypotheticalOptimizableValue = div_(
            mul_(
                assetValue,
                arguments.asset.maxProtectionComposition()
            ),
            arguments.asset.maxProtectionCompositionMantissa()
        );
        return hypotheticalOptimizableValue;
    }

    /**
     * @dev gets all locked protections values with mark to market value. Used by Moartroller.
     */
    function getTotalProtectionLockedValue(LiquidityMathModelInterface.LiquidityMathArgumentsSet memory arguments) public override view returns(uint, uint) {
        uint _lockedValue = 0;
        uint _markToMarket = 0;

        uint _protectionCount = arguments.cprotection.getUserUnderlyingProtectionTokenIdByCurrencySize(arguments.account, arguments.asset.underlying());
        for (uint j = 0; j < _protectionCount; j++) {
            uint protectionId = arguments.cprotection.getUserUnderlyingProtectionTokenIdByCurrency(arguments.account, arguments.asset.underlying(), j);
            bool protectionIsAlive = arguments.cprotection.isProtectionAlive(protectionId);

            if(protectionIsAlive){
                _lockedValue = add_(_lockedValue, arguments.cprotection.getUnderlyingProtectionLockedValue(protectionId));

                uint assetSpotPrice = arguments.oracle.getUnderlyingPrice(arguments.asset);
                uint protectionStrikePrice = arguments.cprotection.getUnderlyingStrikePrice(protectionId);

                if( assetSpotPrice > protectionStrikePrice) {
                    _markToMarket = _markToMarket + div_(
                        mul_(
                            div_(
                                mul_(
                                    assetSpotPrice - protectionStrikePrice,
                                    arguments.cprotection.getUnderlyingProtectionLockedAmount(protectionId)
                                ),
                                getAssetDecimalsMantissa(arguments.asset.underlying())
                            ),
                            arguments.collateralFactorMantissa
                        ),
                    1e18
                    );
                }
            }
            
        }
        return (_lockedValue , _markToMarket);
    }
}