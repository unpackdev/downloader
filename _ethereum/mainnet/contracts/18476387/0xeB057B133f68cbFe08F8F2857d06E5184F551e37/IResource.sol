// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

interface IResource is IERC1155Upgradeable {
    event StashMinted(address from, uint256 id, uint256 amount, bytes32 nonce);
    event StashBurned(address from, uint256 id, uint256 amount);
    function genesisMinter(address) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes32 nonce
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}