// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IAccessControl.sol";

interface IDeltaNFT is IAccessControl, IERC721 {
    /**
     * @param firstReleaseTime
     * @param firstBalance  
     * @param remainingUnlockedType [0|1|2]
     * @args: type == 0: direct type args = [startTime, 0],
     *        type == 1: linear type args = [startTime, endTime, 0]
              type == 2: period type args = [startTime, interval, stepBalance, 0]
     */
    struct UnlockArgs {
        uint256 firstReleaseTime;
        uint256 firstBalance;
        uint256 remainingUnlockedType;
        uint256[4] remainingUnlocked;
        uint256 totalBalance;
    }

    struct TargetArgs {
        address targetToken;
        address poolAddress;
    }

    function mintNFT(
        address to,
        UnlockArgs calldata unlockArgs,
        TargetArgs calldata targetArgs
    ) external returns (uint256 tokenId);

    function getTokenUnlockArgs(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 firstReleaseTime,
            uint256 firstBalance,
            uint256 remainingUnlockedType,
            uint256[4] calldata remainingUnlocked,
            uint256 totalBalance
        );

    function getTokenTargetToken(
        uint256 tokenId
    ) external view returns (address targetToken, address poolAddress);

    function burnNFT(uint256 tokenId) external;
}
