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

contract VaultBoardroom is ContractGuard, Operator, IBoardroom {
    using Safe112 for uint112;
    using SafeMath for uint256;

    /**
     * Data structures.
     */

    struct Boardseat {
        // Pending reward from the previous epochs.
        uint256 rewardPending;
        // Total reward earned in this epoch.
        uint256 rewardEarnedCurrEpoch;
        // Last time reward was claimed(not bound by current epoch).
        uint256 lastClaimedOn;
        // The reward claimed in vesting period of this epoch.
        uint256 rewardClaimedCurrEpoch;
        // Snapshot of boardroom state when last epoch claimed.
        uint256 lastSnapshotIndex;
    }

    struct BoardSnapshot {
        // Block number when recording a snapshot.
        uint256 number;
        // Block timestamp when recording a snapshot.
        uint256 time;
        // Amount of funds received.
        uint256 rewardReceived;
        // Equivalent amount per share staked.
        uint256 rewardPerShare;
    }

    struct BondingSnapshot {
        // Time when first bonding was made.
        uint256 firstBondedOn;
        // The snapshot index of when first bonded.
        uint256 snapshotIndexWhenFirstBonded;
    }

    /**
     * State variables.
     */

    // The vault which has state of the stakes.
    Vault public vault;
    IERC20 public token;

    BoardSnapshot[] public boardHistory;
    mapping(address => Boardseat) public directors;
    mapping(address => BondingSnapshot) public bondingHistory;

    // address(director) => uint256(Epcoh) => uint256(balance)
    mapping(address => mapping(uint256 => uint256)) directorBalanceForEpoch;

    /**
     * Modifier.
     */
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

    /**
     * Events.
     */

    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    /**
     * Constructor.
     */
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

    /**
     * Views/Getters.
     */

    function latestSnapshotIndex() public view returns (uint256) {
        return boardHistory.length.sub(1);
    }

    function getDirector(address who) public view returns (Boardseat memory) {
        return directors[who];
    }

    function getBoardhistory(uint256 i)
        public
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[i];
    }

    function getBondingHistory(address who)
        public
        view
        returns (BondingSnapshot memory)
    {
        return bondingHistory[who];
    }

    function getLatestSnapshot() internal view returns (BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address director)
        public
        view
        returns (uint256)
    {
        return directors[director].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address director)
        internal
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[getLastSnapshotIndexOf(director)];
    }

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address director) internal virtual returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        return
            vault
                .balanceWithoutBonded(director)
                .mul(latestRPS.sub(storedRPS))
                .div(1e18)
                .add(directors[director].rewardEarnedCurrEpoch);
    }

    function claimReward() external virtual directorExists returns (uint256) {
        Boardseat memory seat = directors[msg.sender];
        seat.rewardEarnedCurrEpoch = earned(msg.sender);
        seat.lastSnapshotIndex = latestSnapshotIndex();
        directors[msg.sender] = seat;

        uint256 reward = directors[msg.sender].rewardEarnedCurrEpoch;

        if (reward > 0) {
            directors[msg.sender].rewardEarnedCurrEpoch = 0;
            token.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }

        return reward;
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

        BoardSnapshot memory newSnapshot =
            BoardSnapshot({
                number: block.number,
                time: block.timestamp,
                rewardReceived: amount,
                rewardPerShare: nextRPS
            });
        boardHistory.push(newSnapshot);

        token.transferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function refundReward() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
