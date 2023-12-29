// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import "./IERC721Enumerable.sol";

interface IRedemptionNFT is IERC721Enumerable {
    function mint(address to) external returns (uint256 fnftId);

    function burn(uint256 fnftId) external;
    function burnFromOwner(uint256 fnftId, address _owner) external;
}
