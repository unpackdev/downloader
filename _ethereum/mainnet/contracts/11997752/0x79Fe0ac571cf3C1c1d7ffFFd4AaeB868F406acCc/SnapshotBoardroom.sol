// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IVault.sol";
import "./SafeMath.sol";

import "./Operator.sol";
import "./IBoardroom.sol";

contract SnapshotBoardroom is IBoardroom, Operator {
    using SafeMath for uint256;
    IERC20 public token;
    mapping(address => uint256) public pendingRewards;

    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    Boardseat private dummySeat;

    constructor(IERC20 token_, address operator) {
        token = token_;
        transferOperator(operator);
    }

    function claimAndReinvestReward(IVault _vault) external virtual {
        uint256 reward = _claimReward(msg.sender);
        _vault.bondFor(msg.sender, reward);
    }

    function earned(address director)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return pendingRewards[director];
    }

    function claimReward() public virtual override returns (uint256) {
        return _claimReward(msg.sender);
    }

    function allocateSeigniorage(uint256 amount)
        external
        override
        onlyOperator
    {
        require(amount > 0, 'Boardroom: Cannot allocate 0');
        token.transferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function updateReward(address director) external virtual override {}

    function _claimReward(address who) internal returns (uint256) {
        uint256 reward = pendingRewards[who];

        if (reward > 0) {
            pendingRewards[who] = 0;
            token.transfer(who, reward);
            emit RewardPaid(who, reward);
        }

        return reward;
    }

    function setBalances(address[] memory who, uint256[] memory amt)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < who.length; i++) {
            pendingRewards[who[i]] = amt[i];
        }
    }

    function getDirector(address who)
        external
        view
        override
        returns (Boardseat memory)
    {
        require(who != address(0));
        return dummySeat;
    }

    function getLastSnapshotIndexOf(address who)
        external
        view
        override
        returns (uint256)
    {
        return pendingRewards[who];
    }
}
