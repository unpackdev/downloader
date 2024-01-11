// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC20Upgradeable.sol";

interface IERC1155PaymentSplitterMCUAEUpgradeable is IERC1155Upgradeable {
    // public read erc1155 methods
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function paused() external view returns (bool);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function totalSupply(uint256 tokenId) external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function uri(uint256 tokenId) external view returns (string memory);
    function isTrustedMinter(address account) external view returns (bool);

    // public read paymentSplitter methods
    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20Upgradeable token) external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function released(address account) external view returns (uint256);
    function released(IERC20Upgradeable token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);

    // public write erc1155 methods
    function burn(address account, uint256 tokenId, uint256 value) external;
    function burnBatch(address account, uint256[] memory tokenIds, uint256[] memory values) external;

    // public write paymentSplitter methods
    function release(address payable account) external;
    function release(IERC20Upgradeable token, address account) external;

    // minter write erc1155 methods
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) external;
}
