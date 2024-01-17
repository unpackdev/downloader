// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseReward {
    function mintBatch(
        uint256 _activityId,
        address _to,
        uint256 _tokenType,
        uint256 _amount,
        bytes memory _data
    ) external;

    function forceBurn(address account, uint256 id) external;
}