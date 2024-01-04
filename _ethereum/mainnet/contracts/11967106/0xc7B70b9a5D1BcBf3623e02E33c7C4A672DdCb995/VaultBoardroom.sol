// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Vault.sol";
import "./SafeMath.sol";
import "./Safe112.sol";
import "./ContractGuard.sol";
import "./Operator.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";

// import "./console.sol";

contract VaultBoardroom is ContractGuard, Operator, IBoardroom {
    using Safe112 for uint112;
    using SafeMath for uint256;

    // The vault which has state of the stakes.
    Vault public vault;
    IERC20 public token;
    uint256 public currentEpoch = 1;

    BoardSnapshot[] public boardHistory;
    mapping(address => Boardseat) public directors;
    mapping(address => mapping(uint256 => BondingSnapshot))
        public bondingHistory;

    mapping(address => mapping(uint256 => uint256)) directorBalanceForEpoch;
    mapping(address => uint256) directorBalanceLastEpoch;

    modifier directorExists {
        require(
            vault.balanceOf(msg.sender) > 0,
            'Boardroom: The director does not exist'
        );
        _;
    }

    modifier onlyVault {
        require(msg.sender == address(vault), 'Boardroom: not vault');

        _;
    }

    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    constructor(IERC20 token_, Vault vault_) {
        token = token_;
        vault = vault_;

        BoardSnapshot memory genesisSnapshot =
            BoardSnapshot({
                number: block.number,
                time: 0,
                rewardReceived: 0,
                rewardPerShare: 0
            });
        boardHistory.push(genesisSnapshot);
    }

    function latestSnapshotIndex() public view returns (uint256) {
        return boardHistory.length.sub(1);
    }

    function getDirector(address who)
        external
        view
        override
        returns (Boardseat memory)
    {
        return directors[who];
    }

    function getBoardhistory(uint256 i)
        public
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[i];
    }

    function getBondingHistory(address who, uint256 epoch)
        public
        view
        returns (BondingSnapshot memory)
    {
        return bondingHistory[who][epoch];
    }

    function getLatestSnapshot() public view returns (BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
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

    function claimAndReinvestReward(Vault _vault) external virtual {
        uint256 reward = _claimReward(msg.sender);
        _vault.bondFor(msg.sender, reward);
    }

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address director) public view virtual returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        return
            vault
                .balanceWithoutBonded(director)
                .mul(latestRPS.sub(storedRPS))
                .div(1e18)
                .add(directors[director].rewardEarnedCurrEpoch);
    }

    function claimReward() public virtual directorExists returns (uint256) {
        return _claimReward(msg.sender);
    }

    function allocateSeigniorage(uint256 amount)
        external
        override
        onlyOneBlock
        onlyOperator
    {
        require(amount > 0, 'Boardroom: Cannot allocate 0');

        uint256 totalSupply = vault.totalBondedSupply();

        // 'Boardroom: Cannot allocate when totalSupply is 0'
        if (totalSupply == 0) return;

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply));

        BoardSnapshot memory snap =
            BoardSnapshot({
                number: block.number,
                time: block.timestamp,
                rewardReceived: amount,
                rewardPerShare: nextRPS
            });
        boardHistory.push(snap);

        // console.log('allocateSeigniorage totalSupply: %s', totalSupply);
        // console.log('allocateSeigniorage time: %s', block.timestamp);
        // console.log('allocateSeigniorage rewardReceived: %s', amount);
        // console.log('allocateSeigniorage rewardPerShare: %s', nextRPS);

        token.transferFrom(msg.sender, address(this), amount);
        currentEpoch = currentEpoch.add(1);
        emit RewardAdded(msg.sender, amount);
    }

    function updateReward(address director) external virtual onlyVault {
        _updateReward(director);
    }

    function _claimReward(address who) internal returns (uint256) {
        _updateReward(who);

        uint256 reward = directors[who].rewardEarnedCurrEpoch;

        if (reward > 0) {
            directors[who].rewardEarnedCurrEpoch = 0;
            token.transfer(who, reward);
            emit RewardPaid(who, reward);
        }

        return reward;
    }

    function refundReward() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function _updateReward(address director) internal {
        Boardseat memory seat = directors[director];
        seat.rewardEarnedCurrEpoch = earned(director);
        seat.lastSnapshotIndex = latestSnapshotIndex();
        directors[director] = seat;
    }
}
