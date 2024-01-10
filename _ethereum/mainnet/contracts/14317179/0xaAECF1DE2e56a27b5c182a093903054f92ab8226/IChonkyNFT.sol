// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface IChonkyNFT is IERC721, IERC721Enumerable {
    function mint() external payable;

    function parseGenome(uint256 _genome)
        external
        pure
        returns (uint256[12] memory result);

    function formatGenome(uint256[12] memory _attributes)
        external
        pure
        returns (uint256 genome);

    function getGenome(uint256 _id) external view returns (uint256);

    function getChonkyAttributesAddress() external view returns (address);

    function getChonkyMetadataAddress() external view returns (address);

    function getChonkySetAddress() external view returns (address);

    function getCID() external pure returns (string memory);
}
