// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IDistributor {
    function nextRewardAt(uint _rate) external view returns (uint);

    function nextRewardFor(address _recipient) external view returns (uint);

    function distribute() external returns (bool);

    function addRecipient(address _recipient, uint _rewardRate) external;

    function removeRecipient(uint _index, address _recipient) external;

    function setAdjustment(
        uint _index,
        bool _add,
        uint _rate,
        uint _target
    ) external;

    function updateCurrentRate(uint _index, uint _rate) external;
}
