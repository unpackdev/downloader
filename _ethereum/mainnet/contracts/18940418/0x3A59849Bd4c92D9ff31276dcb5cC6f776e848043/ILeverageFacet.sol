// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILeverageFacet {
    struct LeveragePutOrder {
        uint256 orderId;
        uint256 startDate;
        uint256 expirationDate;
        address lender;
        address borrower;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowAmount;
        uint256 lockedCollateralAmount;
        uint256 debtAmount;
        uint256 pledgeCount;
        uint256 slippage;
        uint256 ltv;
        uint256 platformFeeAmount;
        uint256 tradeFeeAmount;
        uint256 loanFeeAmount;
        uint256 platformFeeRate;
        uint256 tradeFeeRate;
        uint256 interest;
        uint256 index;
    }
    struct LeveragePutLenderData {
        address lender;
        address collateralAsset;
        address borrowAsset;
        uint256 minCollateraAmount;
        uint256 maxCollateraAmount;
        uint256 ltv;
        uint256 interest;
        uint256 slippage;
        uint256 pledgeCount;
        uint256 startDate;
        uint256 expirationDate;
        uint256 platformFeeRate;
        uint256 tradeFeeRate;
    }
    struct FeeData {
        uint collateralAmount;
        uint interestAmount;
        uint tradeFeeAmount;
        uint borrowAmount;
        uint debtAmount;
        uint lockedCollateralAmount;
    }
    event SetLendFeePlatformRecipient(address _recipient);

    function getPriceOracle() external view returns (address);

    function setWhiteList(address _user, bool _type) external;

    function getWhiteList(address _user) external view returns (bool);

    function setLeverageBorrowerPutOrder(
        address _borrower,
        LeveragePutOrder memory _putOrder
    ) external;

    function deleteLeverageBorrowerPutOrder(address _borrower) external;

    function getLeverageBorrowerPutOrder(
        address _borrower
    ) external view returns (LeveragePutOrder memory);

    function setLeverageLenderPutOrder(
        address _lender,
        address _borrower
    ) external;

    function getLeverageLenderPutOrder(
        address _lender
    ) external view returns (address[] memory);

    function getLeverageLenderPutOrderLength(
        address _lender
    ) external view returns (uint256);

    function deleteLeverageLenderPutOrder(
        address _lender,
        uint256 _index
    ) external;

    function setLeverageOrderByOrderId(
        uint256 orderId,
        LeveragePutOrder memory _order
    ) external;

    function getLeverageOrderByOrderId(
        uint256 orderId
    ) external view returns (LeveragePutOrder memory);

    function setLeverageFeeData(uint _orderID, FeeData memory _data) external;

    function deleteLeverageFeeData(uint _orderID) external;

    function getLeverageFeeData(
        uint _orderID
    ) external view returns (FeeData memory);

    function setBorrowSignature(bytes memory _sign) external;

    function getBorrowSignature(
        bytes memory _sign
    ) external view returns (bool);

    function setleverageLendPlatformFeeRecipient(address _addr) external;

    function getleverageLendPlatformFeeRecipient()
        external
        view
        returns (address);
}
