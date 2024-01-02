// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUnikuraCollectibles {
    event BaseURIChanged(string oldBaseURI, string newBaseURI);

    event LogUpdateMinter(address account, bool status);

    event LogUpdateBurner(address account, bool status);

    function initialize(string memory name_, string memory symbol_) external;

    /// @notice onlyOwner
    function setBaseURI(string calldata baseURI_) external;

    function baseURI() external view returns (string memory);

    /// @notice onlyOwner
    function updateMinterRole(address account, bool status) external;

    /// @notice onlyOwner
    function updateBurnerRole(address account, bool status) external;

    /// @notice onlyMinter
    function mint(address to, uint256 tokenId) external;

    /// @notice onlyBurner
    function burn(uint256 tokenId) external;
}
