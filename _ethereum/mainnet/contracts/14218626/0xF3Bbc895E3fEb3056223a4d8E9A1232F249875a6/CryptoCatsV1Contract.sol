// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CryptoCatsV1Contract {

    // Events

    event CatTransfer(address indexed from, address indexed to, uint catIndex);
    event CatOffered(uint indexed catIndex, uint minPrice, address indexed toAddress);
    event CatBought(uint indexed catIndex, uint price, address indexed fromAddress, address indexed toAddress);
    event CatNoLongerForSale(uint indexed catIndex);
    event Assign(address indexed to, uint256 catIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ReleaseUpdate(uint256 indexed newCatsAdded, uint256 totalSupply, uint256 catPrice, string newImageHash);
    event UpdateReleasePrice(uint32 releaseId, uint256 catPrice);
    event UpdateAttribute(uint indexed attributeNumber, address indexed ownerAddress, bytes32 oldValue, bytes32 newValue);
   
    // Read contract

    function name() external view returns (string memory);

    function catsForSale(uint id) external view returns (bool isForSale, uint catIndex, address seller, uint minPrice, address sellOnlyTo);

    function _totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function imageHash() external view returns (string memory);

    function catIndexToAddress(uint id) external view returns (address);

    function standard() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function symbol() external view returns (string memory);

    function catsRemainingToAssign() external view returns (uint);

    function pendingWithdrawals(address) external view returns (uint);

    function previousContractAddress() external view returns (address);

    function currentReleaseCeiling() external view returns (uint);

    function totalSupplyIsLocked() external view returns (bool);

    // Write contract

    function withdraw() external;

    function buyCat(uint catIndex) external payable;

    function transfer(address _to, uint _value) external;

    function offerCatForSaleToAddress(uint catIndex, uint minSalePriceInWei, address toAddress) external;

    function offerCatForSale(uint catIndex, uint minSalePriceInWei) external;

    function getCat(uint catIndex) external;

    function catNoLongerForSale(uint catIndex) external;

    function lockTotalSupply() external;

}