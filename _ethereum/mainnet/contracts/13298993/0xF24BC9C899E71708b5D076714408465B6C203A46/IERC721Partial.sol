//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721Partial{
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
