// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Interface of the PunkCrushers.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
interface IPunkCrushers {
    /**
     * @dev Emitted when `baseURI` is changed.
     */
    event BaseURIUpdated(string baseURI);

    /**
     * @dev Emitted when a new token is minted.
     */
    event NFTMinted(uint256 indexed tokenId, address indexed beneficiary);

    /**
     * @dev Emitted when `amount` ether are send to `beneficiary`.
     */
    event FundsTransferred(address indexed beneficiary, uint256 amount);

    /**
     * @dev Returns the max allowed supply i.e. 10,000.
     */
    function MAX_SUPPLY() external view returns (uint256);

    /**
     * @dev Returns the price per token if `1` token is to be minted.
     */
    function PRICE_PER_TOKEN_FOR_1() external view returns (uint256);

    /**
     * @dev Returns the price per token if `3` tokens is to be minted.
     */
    function PRICE_PER_TOKEN_FOR_3() external view returns (uint256);

    /**
     * @dev Returns the price per token if `5` tokens is to be minted.
     */
    function PRICE_PER_TOKEN_FOR_5() external view returns (uint256);

    /**
     * @dev Returns the price per token if `10` tokens is to be minted.
     */
    function PRICE_PER_TOKEN_FOR_10() external view returns (uint256);

    /**
     * @dev Returns the price per token if `20` tokens is to be minted.
     *
     * Note: only for {presaleMint}.
     */
    function PRICE_PER_TOKEN_FOR_20() external view returns (uint256);

    /**
     * @dev Returns bool flag if presale is active or not.
     */
    function presaleActive() external view returns (bool);

    /**
     * @dev Returns the address of {dev}.
     */
    function dev() external view returns (address);

    /**
     * @dev Returns the string value of {baseURI}.
     */
    function baseURI() external view returns (string calldata);

    /**
     * @dev Returns bool flag is token exists.
     */
    function tokenExists(uint256 _tokenId) external view returns (bool);

    /**
     * @dev Returns the price for `_noOfTokens`.
     */
    function tokensPrice(uint256 _noOfTokens) external pure returns (uint256);

    /**
     * @dev Mints `_noOfTokens` and transfers to `caller`.
     *
     * Note:
     * - that only callable if {presaleActive} is true.
     * - that only 20 NFTs can be minted per transaction.
     *
     * Emits a {NFTMinted} and {FundsTransferred} events.
     */
    function presaleMint(uint256 _noOfTokens) external payable;

    /**
     * @dev Mints `_noOfTokens` and transfers to `caller`.
     *
     * Note: that only 10 NFTs can be minted per transaction.
     *
     * Emits a {NFTMinted} and {FundsTransferred} events.
     */
    function mint(uint256 _noOfTokens) external payable;

    /**
     * @dev Reserves/Mints `_noOfTokens` and transfers to `owner`.
     *
     * Note
     * - that caller must be {owner}.
     * - that only 30 NFTs can be minted per transaction.
     *
     * Emits a {NFTMinted} and {FundsTransferred} events.
     */
    function reserveTokens(uint256 _noOfTokens) external;

    /**
     * @dev Toggles presale active or inactive.
     *
     * Note that caller must be {owner}.
     */
    function togglePresale() external;

    /**
     * @dev Sets {baseURI} to `_newBaseTokenURI`.
     *
     * Note
     * - `_newBaseTokenURI` must be in format: "ipfs://{hash}/"
     * - that caller must be {owner}.
     * - that only callable once.
     *
     * Emits a {BaseURIUpdated} event.
     */
    function setBaseURI(string calldata _newBaseTokenURI) external;
}
