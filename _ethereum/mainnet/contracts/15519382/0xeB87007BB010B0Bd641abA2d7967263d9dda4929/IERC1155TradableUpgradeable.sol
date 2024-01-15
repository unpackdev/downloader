// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IERC1155Upgradeable.sol";
import "./IERC2981Upgradeable.sol";

interface IERC1155TradableUpgradeable is IERC1155Upgradeable, IERC2981Upgradeable {
    function getCreator(uint256 id) external view
    virtual
    returns (address sender);
}
