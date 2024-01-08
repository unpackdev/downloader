// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFamilyMaker {
    /**
     * ERC-721 functions
     */

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function exists(uint256 _tokenId) external view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /**
     * Family Maker functions
     */

    function totalSupply() external view returns (uint256);

    function createWork(address _to, string calldata _uri) external;

    function transferOwnership(address newOwner) external;
}
