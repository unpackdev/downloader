// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NFTCultForgeComponentsBase
 * @author @NiftyMike, NFT Culture
 * @notice Some code cribbed from Open Zeppelin Ownable.sol.
 * @dev Base implementation of a uri splitter.
 */
abstract contract NFTCultForgeComponentsBase {
    function _SplitUri(
        string calldata tokenUri,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(tokenUri);
        bytes memory result = new bytes(8); //66-34=32, but using 8 to reduce gas.
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return result;
    }
}