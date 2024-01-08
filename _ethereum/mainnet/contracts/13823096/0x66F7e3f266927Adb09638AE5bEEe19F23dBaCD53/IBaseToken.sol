// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IBaseToken {
    function initialize(
        string memory name_,
        string memory symbol_
    ) external;
    function grantRole(bytes32 role, address account) external;
    function DEFAULT_ADMIN_ROLE() external returns(bytes32);
    function MINTER_ROLE() external returns(bytes32);
    function mint(address to) external;
    function totalMinted() external returns (uint256);
    function maxSupply() external returns (uint256);
    function setBaseURI(string memory baseURI_) external;
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external;
}