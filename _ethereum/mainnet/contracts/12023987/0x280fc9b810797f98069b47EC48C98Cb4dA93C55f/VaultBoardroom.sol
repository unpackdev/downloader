// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IVault.sol";
import "./SafeMath.sol";
import "./ContractGuard.sol";
import "./BaseBoardroom.sol";

// import "./console.sol";

contract VaultBoardroom is ContractGuard, BaseBoardroom {
    using SafeMath for uint256;

    // The vault which has state of the stakes.
    IVault public vault;
    uint256 public currentEpoch = 1;
    uint256 public buffer = 80;

    mapping(address => mapping(uint256 => BondingSnapshot))
        public bondingHistory;

    mapping(address => mapping(uint256 => uint256)) directorBalanceForEpoch;
    mapping(address => uint256) balanceCurrentEpoch;
    mapping(address => uint256) balanceLastEpoch;
    mapping(address => uint256) balanceBeforeLaunch;

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

    constructor(
        IERC20 token_,
        IVault vault_,
        address owner,
        address operator
    ) BaseBoardroom(token_) {
        vault = vault_;

        BoardSnapshot memory genesisSnapshot =
            BoardSnapshot({
                number: block.number,
                time: 0,
                rewardReceived: 0,
                rewardPerShare: 0
            });
        boardHistory.push(genesisSnapshot);

        transferOperator(operator);
        transferOwnership(owner);
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

    // returns the balance as per the last epoch; if the user deposits/withdraws
    // in the current epoch, this value will not change unless another epoch passes
    function getBalanceFromLastEpoch(address who)
        public
        view
        returns (uint256)
    {
        // console.log('getBalanceFromLastEpoch who %s', who);
        // console.log('getBalanceFromLastEpoch currentEpoch %s', currentEpoch);
        if (currentEpoch == 1) return 0;

        // console.log(
        //     'getBalanceFromLastEpoch balanceLastEpoch[who] %s',
        //     balanceLastEpoch[who]
        // );
        // console.log(
        //     'getBalanceFromLastEpoch balanceCurrentEpoch[who] %s',
        //     balanceCurrentEpoch[who]
        // );

        if (balanceCurrentEpoch[who] == 0) {
            // console.log(
            //     'getBalanceFromLastEpoch balanceOf(who) %s',
            //     balanceOf(who)
            // );
            return balanceOf(who);
        }

        uint256 currentBalance =
            getBondingHistory(who, balanceCurrentEpoch[who]).balance;

        if (balanceCurrentEpoch[who] == currentEpoch) {
            // if boardroom was disconnected before then just return the old balance
            if (balanceLastEpoch[who] == 0) return balanceBeforeLaunch[who];
            return getBondingHistory(who, balanceLastEpoch[who]).balance;
        }

        if (balanceCurrentEpoch[who] < currentEpoch) {
            return currentBalance;
        }

        return 0;
    }

    function claimAndReinvestReward(IVault _vault) external virtual override {
        uint256 reward = _claimReward(msg.sender);
        _vault.bondFor(msg.sender, reward);
    }

    function rewardPerShare() public view override returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function balanceOf(address who) public view returns (uint256) {
        uint256 unbondingAmount = vault.getStakedAmount(who);
        return vault.balanceOf(who).sub(unbondingAmount);
    }

    function earned(address director)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        return
            getBalanceFromLastEpoch(director)
                .mul(latestRPS.sub(storedRPS))
                .div(1e18)
                .add(directors[director].rewardEarnedCurrEpoch);
    }

    function claimReward()
        public
        virtual
        override
        directorExists
        returns (uint256)
    {
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
        uint256 amountAfterBuffer = amount.mul(buffer).div(100);

        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS =
            prevRPS.add(amountAfterBuffer.mul(1e18).div(totalSupply));

        BoardSnapshot memory snap =
            BoardSnapshot({
                number: block.number,
                time: block.timestamp,
                rewardReceived: amountAfterBuffer,
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

    function updateReward(address director)
        external
        virtual
        override
        onlyVault
    {
        _updateBalance(director);
    }

    function _claimReward(address who) internal returns (uint256) {
        _updateReward(who);

        uint256 reward = directors[who].rewardEarnedCurrEpoch;

        if (reward > 0) {
            directors[who].rewardEarnedCurrEpoch = 0;
            token.transfer(who, reward);
            emit RewardPaid(who, reward);

            if (balanceLastEpoch[who] == 0) {
                balanceBeforeLaunch[who] = balanceOf(who);
            }
        }

        return reward;
    }

    function setVault(IVault _vault) external onlyOwner {
        vault = _vault;
    }

    function setBuffer(uint256 _buffer) external onlyOwner {
        buffer = _buffer;
    }

    function _updateReward(address director) internal {
        Boardseat memory seat = directors[director];
        seat.rewardEarnedCurrEpoch = earned(director);
        seat.lastSnapshotIndex = latestSnapshotIndex();
        directors[director] = seat;
    }

    function _updateBalance(address who) internal {
        // console.log('updating balance for director at epoch: %s', currentEpoch);

        BondingSnapshot memory snap =
            BondingSnapshot({
                epoch: currentEpoch,
                when: block.timestamp,
                balance: balanceOf(who)
            });

        bondingHistory[who][currentEpoch] = snap;

        // update epoch counters if they need updating
        if (balanceCurrentEpoch[who] != currentEpoch) {
            balanceLastEpoch[who] = balanceCurrentEpoch[who];
            balanceCurrentEpoch[who] = currentEpoch;
        }

        // if (balanceLastEpoch[who] == 0) {
        //     require(
        //         earned(who) == 0,
        //         'Claim rewards once before depositing again'
        //     );
        // }

        if (balanceLastEpoch[who] == 0) {
            balanceLastEpoch[who] = 1;
        }

        _updateReward(who);
    }
}
