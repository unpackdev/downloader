//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title interface Decentralized Telecommunication Operator (DTO)
interface IDTO {
    /**
     * @notice set base URI
     * @param uri_ The string with URI
     */
    function setBaseURI(string memory uri_) external;

    /**
     * @notice set start or end contract
     * @param status_ bool value
     */
    function setPause(bool status_) external;

    /**
     * @notice set start or end sale prefix
     * @param status bool value
     */
    function setPausePrefix(bool status) external;

    /**
     * @notice set cost of prefix
     * @param price uint256 price prefix
     */
    function setSalePrice(uint256 price) external;

    /**
     * @notice set size prefix
     * @param size number symbol in Prefix
     */
    function setMaxSizePrefix(uint256 size) external;

    /**
     * @notice add Prefix Owner contract
     * @param prefix_ prefix name
     * @param price prefix price
     * @return prefix Id
     */
    function addPrefixOwner(string memory prefix_, uint256 price)
        external
        returns (uint256);

    /**
     * @notice payable function add Prefix
     * @param prefix prefix name
     * @param price prefix price
     * @return prefix Id
     */
    function addPrefix(string memory prefix, uint256 price)
        external
        payable
        returns (uint256);

    /**
     * @notice change owner prefix
     * @param prefix_ prefix name
     * @param newAddress new address of owner
     */
    function changeOwnerPrerix(string memory prefix_, address newAddress)
        external;

    /**
     * @notice set Price Number in Prefix
     * @param id prefix Id
     * @param price number price
     */
    function changePrice(uint256 id, uint256 price) external;

    /**
     * @notice set new rent duration
     * @param prefixNumber token ID
     * @param duration new rent
     */
    function reRent(uint256 prefixNumber, uint256 duration) external payable;

    /**
     * @notice register new Number
     * @param prefixNumber token ID
     * @param duration new rent
     */
    function registerNumber(uint256 prefixNumber, uint256 duration)
        external
        payable;

    /**
     * @notice get base URI
     * @return String value equals base URI with metadata
     */
    function baseURI() external view returns (string memory);
}
