// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract CNftInterface {
    // TODO: Consider separating into storage contract.
    address public underlying;
    bool public isPunk;
    bool public is1155;
    address public comptroller;
    bool public constant isCNft = true;

    /// @notice Mapping from user to number of tokens.
    // TODO: Possibly add more mappings to make it easy to enumerate if Moralis doesn't work.
    mapping(address => uint256) public totalBalance;

    function seize(address liquidator, address borrower, uint256[] calldata seizeIds, uint256[] calldata seizeAmounts) external virtual;
}

abstract contract NftPriceOracle {
    /// @notice Indicator that this is a NftPriceOracle contract (for inspection)
    bool public constant isNftPriceOracle = true;

    /**
      * @notice Get the underlying price of a cNft asset
      * @param cNft The cNft to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CNftInterface cNft) external virtual view returns (uint);
}

