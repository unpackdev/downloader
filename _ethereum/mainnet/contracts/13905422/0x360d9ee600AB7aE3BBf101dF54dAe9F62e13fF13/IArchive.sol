// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArchive {
    /**
        @notice Query archived `saleId`
            Note: `saleId` is archived when Seller cancels the 'on sale' item
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function prevSaleIds(uint256 _saleId) external view returns (bool);

    /**
        @notice Query an amount of item that is current 'on sale'
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getCurrentOnSale(uint256 _saleId) external view returns (uint256 _currentAmt);

    /**
        @notice Update new amount of item that is 'on sale'
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
        @param _newAmt          New amount is 'on sale'  
    */
    function setCurrentOnSale(uint256 _saleId, uint256 _newAmt) external;

    /**
        @notice Query locking state of one `saleId`
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getLocked(uint256 _saleId) external view returns (bool _locked);

    /**
        @notice Set locking state of one `saleId`
            Note: Once locking state of one `saleId` is set, it cannot be reset
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function setLocked(uint256 _saleId) external;

    /**
        @notice Archive `saleId`
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function archive(uint256 _saleId) external;
}
