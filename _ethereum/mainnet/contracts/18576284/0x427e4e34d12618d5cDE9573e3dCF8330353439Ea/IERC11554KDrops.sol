// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC11554K.sol";

/**
 * @dev {IERC11554KDrops} interface:
 */
interface IERC11554KDrops is IERC11554K {
    function setItemUriID(uint256 id, uint256 uriID) external;

    function setVaulted() external;

    function setRevealed(string calldata collectionURI_) external;

    function setMintingDrops(address mintingDrops_) external;
}
