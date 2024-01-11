// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

contract NXCTesting is Ownable {
    bool public saleIsActive = false;
    address private _manager;

    constructor () {
        saleIsActive = false;
    }

    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function flipSaleState() external onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function mint(uint256 quantity) payable external returns (uint256) {
        require(saleIsActive, "Sale is not active");
        return quantity;
        
    }

    function noPayMint() external returns (bool){
        require(saleIsActive, "Sale is not active");
        return true;
    }

    function noPayMintQuantity(uint256 quantity) external returns (uint256) {
        require(saleIsActive, "Sale is not active");
        return quantity;
    }
}