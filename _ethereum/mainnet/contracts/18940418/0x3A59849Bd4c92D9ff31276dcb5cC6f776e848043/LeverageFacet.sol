// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ILeverageFacet.sol";

contract LeverageFacet is ILeverageFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.LeverageFacet.diamond.storage");
    struct Leverage {
        mapping(address => LeveragePutOrder) borrowerPutOrder;
        mapping(uint256 => LeveragePutOrder) leverageOrder;
        mapping(address => address[]) lenderPutOrder;
        bytes32 domainHash;
        mapping(address => bool) whiteList;
        address priceOracle;
        mapping(bytes => bool) borrowSignature;
        mapping(uint => FeeData) feeDataOrder;
        address  leverageLendPlatformFeeRecipient;

    }

    function setWhiteList(address _user, bool _type) external {
        Leverage storage ds = diamondStorage();
        ds.whiteList[_user] = _type;
    }

    function setBorrowSignature(bytes memory _sign) external {
        Leverage storage ds = diamondStorage();
        ds.borrowSignature[_sign] = true;
    }


    function getBorrowSignature(
        bytes memory _sign
    ) external view returns (bool) {
        Leverage storage ds = diamondStorage();
        return ds.borrowSignature[_sign];
    }

    function setPriceOracle(address _o) external {
        Leverage storage ds = diamondStorage();
        ds.priceOracle = _o;
    }
    function setleverageLendPlatformFeeRecipient(address _addr) external {
        Leverage storage ds = diamondStorage();
        ds.leverageLendPlatformFeeRecipient = _addr;
    }

    function getleverageLendPlatformFeeRecipient(
    ) external view returns (address) {
        Leverage storage ds = diamondStorage();
        return ds.leverageLendPlatformFeeRecipient;
    }
    function getPriceOracle() external view returns (address) {
        Leverage storage ds = diamondStorage();
        return ds.priceOracle;
    }

    function getWhiteList(address _user) external view returns (bool) {
        Leverage storage ds = diamondStorage();
        return ds.whiteList[_user];
    }

    function diamondStorage() internal pure returns (Leverage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setLeverageBorrowerPutOrder(
        address _borrower,
        LeveragePutOrder memory _putOrder
    ) external {
        Leverage storage ds = diamondStorage();
        ds.borrowerPutOrder[_borrower] = _putOrder;
    }

    function deleteLeverageBorrowerPutOrder(address _borrower) external {
        Leverage storage ds = diamondStorage();
        delete ds.borrowerPutOrder[_borrower];
    }

    function setLeverageFeeData(uint _orderID, FeeData memory _data) external {
        Leverage storage ds = diamondStorage();
        ds.feeDataOrder[_orderID] = _data;
    }

    function deleteLeverageFeeData(uint _orderID) external {
        Leverage storage ds = diamondStorage();
        delete ds.feeDataOrder[_orderID];
    }

    function getLeverageFeeData(
        uint _orderID
    ) external view returns (FeeData memory) {
        Leverage storage ds = diamondStorage();
        return ds.feeDataOrder[_orderID];
    }

    function getLeverageBorrowerPutOrder(
        address _borrower
    ) external view returns (LeveragePutOrder memory) {
        Leverage storage ds = diamondStorage();
        return ds.borrowerPutOrder[_borrower];
    }

    function setLeverageLenderPutOrder(
        address _lender,
        address _borrower
    ) external {
        Leverage storage ds = diamondStorage();
        ds.lenderPutOrder[_lender].push(_borrower);
    }

    function getLeverageLenderPutOrder(
        address _lender
    ) external view returns (address[] memory) {
        Leverage storage ds = diamondStorage();
        return ds.lenderPutOrder[_lender];
    }

    function getLeverageLenderPutOrderLength(
        address _lender
    ) external view returns (uint256) {
        Leverage storage ds = diamondStorage();
        return ds.lenderPutOrder[_lender].length;
    }

    function deleteLeverageLenderPutOrder(
        address _lender,
        uint256 _index
    ) external {
        Leverage storage ds = diamondStorage();
        uint256 lastIndex = ds.lenderPutOrder[_lender].length - 1;
        if (lastIndex != _index) {
            address lastAddr = ds.lenderPutOrder[_lender][lastIndex];
            ds.borrowerPutOrder[lastAddr].index = _index;
            ds.lenderPutOrder[_lender][_index] = lastAddr;
        }
        ds.lenderPutOrder[_lender].pop();
    }

    function getLeverageOrderByOrderId(
        uint256 orderId
    ) external view returns (LeveragePutOrder memory) {
        Leverage storage ds = diamondStorage();
        return ds.leverageOrder[orderId];
    }

    function setLeverageOrderByOrderId(
        uint256 orderId,
        LeveragePutOrder memory _order
    ) external {
        Leverage storage ds = diamondStorage();
        ds.leverageOrder[orderId] = _order;
    }
}
