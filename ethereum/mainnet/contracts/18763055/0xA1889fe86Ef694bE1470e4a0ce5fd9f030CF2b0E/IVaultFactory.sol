// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IFactory.sol";
import "./IInstanceRegistry.sol";
import "./IERC721.sol";

interface IVaultFactory is IFactory, IInstanceRegistry, IERC721 {
    function create2(bytes32 salt) external returns (address vault);

    function addressToUint(address vault) external pure returns (uint256 tokenId);

    function predictCreate2Address(bytes32 salt) external view returns (address instance);

    function setTokenURIHandler(address tokenURIHandler) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
