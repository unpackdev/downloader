// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./Amount.sol";

import "./MozartTypes.sol";

interface IMozartCoreV1 {

    function getPosition(
        uint256 id
    )
        external
        view
        returns (MozartTypes.Position memory);

    function getCurrentPrice()
        external
        view
        returns (Decimal.D256 memory);

    function getSyntheticAsset()
        external
        view
        returns (address);

    function getCollateralAsset()
        external
        view
        returns (address);

    function getCurrentOracle()
        external
        view
        returns (address);

    function getInterestSetter()
        external
        view
        returns (address);

    function getBorrowIndex()
        external
        view
        returns (uint256, uint256);

    function getCollateralRatio()
        external
        view
        returns (Decimal.D256 memory);

    function getTotals()
        external
        view
        returns (uint256, uint256);

    function getLimits()
        external
        view
        returns (uint256, uint256);

    function getInterestRate()
        external
        view
        returns (uint256);

    function getFees()
        external
        view
        returns (
            Decimal.D256 memory _liquidationUserFee,
            Decimal.D256 memory _liquidationArcRatio
        );

    function isPositionOperator(
        uint256 _positionId,
        address _operator
    )
        external
        view
        returns (bool);

    function isGlobalOperator(
        address _operator
    )
        external
        view
        returns (bool);
}
