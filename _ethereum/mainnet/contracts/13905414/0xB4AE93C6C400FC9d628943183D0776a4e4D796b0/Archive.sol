// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IManager.sol";

/**
   @title Archive contract
   @dev This contract archives the `saleID` that was canceled
*/
contract Archive is Ownable {
    struct OnSale {
        uint256 amount;
        bool locked;
    }

    //  Address of Manager contract
    IManager public manager;

    //  A mapping list of current on sale amount of one NFT1155 item
    mapping(uint256 => OnSale) public currentOnSale;

    //  A list of previous SaleIds
    mapping(uint256 => bool) public prevSaleIds;

    modifier onlyAuthorize() {
        require(
            _msgSender() == manager.vendor(), "Unauthorized "
        );
        _;
    }

    constructor(address _manager) Ownable() {
        manager = IManager(_manager);
    }

    /**
        @notice Change a new Manager contract
        @dev Caller must be Owner
        @param _newManager       Address of new Manager contract
    */
    function updateManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Set zero address");
        manager = IManager(_newManager);
    }

    /**
        @notice Query an amount of item that is current 'on sale'
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getCurrentOnSale(uint256 _saleId) external view returns (uint256 _currentAmt) {
        _currentAmt = currentOnSale[_saleId].amount;
    }

    /**
        @notice Update new amount of item that is 'on sale'
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
        @param _newAmt          New amount is 'on sale'  
    */
    function setCurrentOnSale(uint256 _saleId, uint256 _newAmt) external onlyAuthorize {
        currentOnSale[_saleId].amount = _newAmt;
    }

    /**
        @notice Query locking state of one `saleId`
        @dev Caller can be ANY
        @param _saleId       An unique identification number of Sale Info
    */
    function getLocked(uint256 _saleId) external view returns (bool _locked) {
        _locked = currentOnSale[_saleId].locked;
    }

    /**
        @notice Set locking state of one `saleId`
            Note: Once locking state of one `saleId` is set, it cannot be reset
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function setLocked(uint256 _saleId) external onlyAuthorize {
        currentOnSale[_saleId].locked = true;
    }

    /**
        @notice Archive `saleId`
        @dev Caller is restricted
        @param _saleId          An unique identification number of Sale Info
    */
    function archive(uint256 _saleId) external onlyAuthorize {
        prevSaleIds[_saleId] = true;
    }
}
