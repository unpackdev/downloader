// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";

import "./IHunterValidator.sol";
import "./IHuntGame.sol";
import "./IHuntNFTFactory.sol";

interface IHuntGameDeployer {
    function getPendingGame(address creator) external view returns (address);

    function calcGameAddr(address creator, uint256 nonce) external view returns (address);

    function userNonce(address user) external view returns (uint256);
}
