// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165.sol";
import "./WadRayMath.sol";

import "./Errors.sol";

import "./IInterestRateStrategy.sol";

contract InterestRateStrategy is IInterestRateStrategy, ERC165 {
    using WadRayMath for uint256;
    // a bucket address to its params
    mapping(address => BarCalculationParams) internal calculationParams;

    /**
     * @inheritdoc IInterestRateStrategy
     */
    function setBarCalculationParams(bytes calldata _params) external override {
        BarCalculationParams memory barCalculationParams = abi.decode(_params, (BarCalculationParams));
        calculationParams[msg.sender] = barCalculationParams;
        emit BarCalculationParamsChanged(
            msg.sender,
            barCalculationParams.urOptimal,
            barCalculationParams.k0,
            barCalculationParams.k1,
            barCalculationParams.b0,
            barCalculationParams.b1
        );
    }

    /**
     * @inheritdoc IInterestRateStrategy
     */
    function getBarCalculationParams(address _address) external view override returns (BarCalculationParams memory) {
        return calculationParams[_address];
    }

    /**
     * @inheritdoc IInterestRateStrategy
     */
    function calculateInterestRates(uint256 ur, uint256 reserveRate) public view override returns (uint128, uint128) {
        _require(ur <= WadRayMath.RAY, Errors.UR_IS_MORE_THAN_1.selector);
        if (ur == 0) return (0, 0);
        BarCalculationParams memory barCalcParams = calculationParams[msg.sender];
        uint256 newBAR;
        if (ur <= barCalcParams.urOptimal) {
            newBAR = barCalcParams.k0.rmul(ur) + (barCalcParams.b0);
        } else {
            uint256 k1modified = barCalcParams.k1.rmul(ur);
            if (barCalcParams.b1 < 0) {
                uint256 b1modified = uint256(barCalcParams.b1 * (-1));
                _require(k1modified >= b1modified, Errors.BAR_OVERFLOW.selector);
                newBAR = k1modified - b1modified;
            } else {
                newBAR = k1modified + uint256(barCalcParams.b1);
            }
        }

        // Errors.BAR_OVERFLOW is not possible to test
        _require(newBAR <= type(uint128).max, Errors.BAR_OVERFLOW.selector);
        uint256 newLAR = newBAR.rmul(ur);
        if (reserveRate != 0) {
            newLAR = newLAR.wmul(WadRayMath.WAD - reserveRate);
        }
        _require(newLAR <= type(uint128).max, Errors.LAR_OVERFLOW.selector);

        return (uint128(newBAR), uint128(newLAR));
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IInterestRateStrategy).interfaceId || super.supportsInterface(_interfaceId);
    }
}
