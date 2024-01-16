// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IQuestStaking.sol";
import "./IERC721.sol";

/**
 * @dev An interface for ERC-721s that implement IQuestStaking
 */
interface IQuestStakingERC721 is IERC721, IQuestStaking {

}