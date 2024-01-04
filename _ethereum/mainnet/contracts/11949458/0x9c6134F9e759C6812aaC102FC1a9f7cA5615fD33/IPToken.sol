// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title Deri Protocol non-fungible position token interface
 */
interface IPToken is IERC721 {

    /**
     * @dev Emitted when `owner`'s position is updated
     */
    event Update(
        address indexed owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Position struct
     */
    struct Position {
        // Position volume, long is positive and short is negative
        int256 volume;
        // Position cost, long position cost is positive, short position cost is negative
        int256 cost;
        // The last cumuFundingRate since last funding settlement for this position
        // The overflow for this value is intended
        int256 lastCumuFundingRate;
        // Margin associated with this position
        uint256 margin;
        // Last timestamp this position updated
        uint256 lastUpdateTimestamp;
    }

    /**
     * @dev Set pool address of position token
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of current pool
     */
    function pool() external view returns (address);

    /**
     * @dev Returns the token collection name
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the total number of ever minted position tokens, including those burned
     */
    function totalMinted() external view returns (uint256);

    /**
     * @dev Returns the total number of existent position tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns if `owner` owns a position token in this contract
     */
    function exists(address owner) external view returns (bool);

    /**
     * @dev Returns if position token of `tokenId` exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the position of owner `owner`
     *
     * `owner` must exist
     */
    function getPosition(address owner) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Returns the position of token `tokenId`
     *
     * `tokenId` must exist
     */
    function getPosition(uint256 tokenId) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Mint a position token for `owner` with intial margin of `margin`
     *
     * Can only be called by pool
     * `owner` cannot be zero address
     * `owner` must not exist before calling
     */
    function mint(address owner, uint256 margin) external;

    /**
     * @dev Update the position token for `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function update(
        address owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) external;

    /**
     * @dev Burn the position token owned of `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function burn(address owner) external;

}
