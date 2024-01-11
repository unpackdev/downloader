// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IAdminController.sol";

interface IERC721Token is IAdminController {
    function initialize(string memory _name, string memory _symbol, uint256 _supply, address owner) external;
    function mint(address to, uint256 quantity) external;
    function tokenURI(uint256) external view returns (string memory);
    function setURI(string memory) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function supply() external view returns (uint256);
    function setSupply() external;
    function numberMinted(address) external view returns (uint256);
    function getAux(address) external view returns (uint256);
    function setAux(address, uint64) external;
}