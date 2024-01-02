// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IDeltaNFT.sol";

/**
 * @title IDeltaPool
 * @dev IDeltaPool interface
 * stakePool
 */
interface IDeltaPool {
    function initialize(
        address[5] calldata args1,
        uint256[6] calldata args2
    ) external returns (address poolAddress);

    function setUnlockArgsAddRoot(
        IDeltaNFT.UnlockArgs calldata _unlockArgs,
        bytes32 _merkleRoot
    ) external;

    function getUnlockArgs()
        external
        view
        returns (
            uint256 firstReleaseTime,
            uint256 firstBalance,
            uint256 remainingUnlockedType,
            uint256[4] memory remainingUnlocked,
            uint256 totalBalance
        );

    function subOffer(
        uint256 senderIndex,
        address account,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external payable returns (uint256 level, uint256 index);

    function isLuckyDog(address user) external view returns (bool);

    function refund() external;

    function draw() external;

    function unlockToken(
        uint256 tokenId
    ) external returns (uint256 amount, uint256 _tokenId);
}
