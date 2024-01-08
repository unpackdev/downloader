// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./IERC1155.sol";

interface IZerionMainnetNFT is IERC1155 {
    /// @notice Collection name.
    function name() external view returns (string memory);

    /// @notice Collection symbol.
    function symbol() external view returns (string memory);

    /// @notice Collection metadata URI.
    function contractURI() external view returns (string memory);

    /// @notice IPFS URI for a given id.
    function uri(uint256) external view returns (string memory);
}
