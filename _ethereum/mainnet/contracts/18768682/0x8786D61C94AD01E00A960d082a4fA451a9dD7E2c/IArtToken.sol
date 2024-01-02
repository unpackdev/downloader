//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20Upgradeable.sol";
import "./IArtERC721.sol";

interface IArtToken is IERC20Upgradeable {
    function initialize(string memory ftName, string memory ftSymbol, address erc721Address) external;

    function mint(address to, uint256 amount) external;
}
