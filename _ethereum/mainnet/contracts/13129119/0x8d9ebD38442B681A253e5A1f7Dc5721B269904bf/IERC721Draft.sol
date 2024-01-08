// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* ERC721 Draft Specification, December 2017: https://github.com/ethereum/eips/issues/721 */
interface IERC721Draft {
    // Required Functions
    function implementsERC721() external pure returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Optional Functions
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}
