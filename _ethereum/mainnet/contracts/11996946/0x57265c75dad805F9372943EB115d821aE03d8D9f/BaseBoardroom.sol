// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IVault.sol";
import "./SafeMath.sol";
import "./Operator.sol";
import "./IBoardroom.sol";

abstract contract BaseBoardroom is Operator, IBoardroom {
    using SafeMath for uint256;

    IERC20 public token;

    BoardSnapshot[] public boardHistory;
    mapping(address => Boardseat) public directors;

    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    constructor(IERC20 token_) {
        token = token_;
    }

    function getDirector(address who)
        external
        view
        override
        returns (Boardseat memory)
    {
        return directors[who];
    }

    function getLastSnapshotIndexOf(address director)
        external
        view
        override
        returns (uint256)
    {
        return directors[director].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address director)
        public
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[directors[director].lastSnapshotIndex];
    }

    function latestSnapshotIndex() public view returns (uint256) {
        return boardHistory.length.sub(1);
    }

    function getLatestSnapshot() public view returns (BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
    }

    function rewardPerShare() public view virtual returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function refundReward() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
