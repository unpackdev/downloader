// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITinyFamiliar {
    function addToPresale(address[] calldata addresses, uint256 numAllowedToMint) external;
    function addToPrivateSale(address[] calldata addresses) external;

    function presaleMintQty(address addr) external returns (uint256);
    function onPresaleList(address addr) external returns (bool);
    function onPrivateSaleList(address addr) external returns (bool);

    function removeFromPresale(address[] calldata addresses) external;
    function removeFromPrivateSale(address[] calldata addresses) external;

    function presaleClaimedBy(address owner) external returns (uint256);
    function privateSaleClaimedBy(address owner) external returns (uint256);

    function mintPublic(uint256 numberOfTokens) external payable;

    function mintPresale(uint256 numberOfTokens) external payable;
    function mintPrivateSale() external payable;

    function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory);

    function ownerMint(uint256 quantity) external;

    function gift(address[] calldata to) external;

    function setIsActive(bool isActive) external;

    function setIsPresaleActive(bool isPresaleActive) external;
    function setIsPrivateSaleActive(bool isPrivateSaleActive) external;

    function setProof(string memory proofString) external;

    function emergencyWithdraw() external payable;

    function withdrawForAll() external payable;

    function setMintPrice(uint256 price) external;

    function setWhiteListMintPrice(uint256 price) external;
}