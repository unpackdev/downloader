// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./token-metadata.sol";

interface ISafariErc721 {
    function totalSupply() external view returns(uint256);
    function batchMint(address recipient, SafariToken.Metadata[] memory _tokenMetadata, uint16[] memory tokenIds) external;
}
