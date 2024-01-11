// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVoid721 {
    function allTransfersLocked() external view returns (bool);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function getSecondsSinceLastTransfer(uint256 _id)
        external
        view
        returns (uint256);

    function getSecondsSinceStart() external view returns (uint256);

    function isAdmin(address addressToCheck) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function lockAllTransfers(bool _locked) external;

    function lockTransfer(uint256 _id, bool _locked) external;

    function maxSupply() external view returns (uint256);

    function baseURI() external view returns (string memory);

    function mint(address _recipient, uint256 _amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function royaltyAmount() external view returns (uint16);

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address, uint256);

    function royaltyRecipient() external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setAdmin(address _newAdmin, bool _isAdmin) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory newURI) external;

    function startTime() external view returns (uint256);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalBurned() external view returns (uint256);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferLocks(uint256) external view returns (bool);

    function transferOwnership(address newOwner) external;

    function numberMinted(address buyer) external view returns (uint256);

    function prereleasePurchases(address buyer) external view returns (uint64);

    function setPrereleasePurchases(address buyer, uint64 amount) external;
}
