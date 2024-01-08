// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

// --------------------------------------------------------------------------------------
// At expansion Stakers (LIFT & CTRL) collect 20% (variable below) in CTRL
// CTRL is distributed as a % of value staked
//      LIFT Value = LIFT Amount * LIFT Price
//      CTRL Value = CTRL Amount * CTRL Price

// Staking LIFT is timelocked 60 days; removal prior to end of timelock = 60 - days staked reduction as a percent
// abandoned LIFT is migrated to IdeaFund

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Operator.sol";
import "./ContractGuard.sol";
import "./ShareWrapper.sol";

//import "./IBasisAsset.sol";
import "./IOracle.sol";

//import "./console.sol";

contract Boardroom is ShareWrapper, ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    //uint256[2][] is an array of [amount][timestamp]
    //used to handle the timelock of LIFT tokens
    struct StakingSeatShare {        
        uint256 lastSnapshotIndex;
        uint256 rewardEarned; 
        uint256[2][] stakingWhenQuatity;
        bool isEntity;
    }

    //used to handle the staking of CTRL tokens
    struct StakingSeatControl {        
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        bool isEntity;
    }

    struct BoardSnapshotShare {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    struct BoardSnapshotControl {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerControl;
    }

    /* ========== STATE VARIABLES ========== */

    mapping(address => StakingSeatShare) private stakersShare;
    mapping(address => StakingSeatControl) private stakersControl;

    BoardSnapshotShare[] private boardShareHistory;
    BoardSnapshotControl[] private boardControlHistory;

    uint daysRequiredStaked = 90; // staking less than X days = X - Y reduction in withdrawl, Y = days staked
    address ideaFund; //Where the forfeited shares end up
    address theOracle;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _share, address _control, address _ideafund, address _theOracle) {
        share = _share;
        control = _control;
        ideaFund = _ideafund;
        theOracle = _theOracle;

        BoardSnapshotShare memory genesisSSnapshot = BoardSnapshotShare({
            time: block.number,
            rewardReceived: 0,
            rewardPerShare: 0
        });
        boardShareHistory.push(genesisSSnapshot);

        BoardSnapshotControl memory genesisCSnapshot = BoardSnapshotControl({
            time: block.number,
            rewardReceived: 0,
            rewardPerControl: 0
        });
        boardControlHistory.push(genesisCSnapshot);
    }

    /* ========== Modifiers =============== */
    modifier stakerExists {
        require(
            getbalanceOfControl(msg.sender) > 0 ||
            getbalanceOfShare(msg.sender) > 0,
            'Boardroom: The director does not exist'
        );
        _;
    }

    modifier updateRewardShare(address staker, uint256 amount) {
        if (staker != address(0)) {
            StakingSeatShare storage seatS = stakersShare[staker];
            (seatS.rewardEarned, ) = earned(staker);
            seatS.lastSnapshotIndex = latestShareSnapshotIndex();
            seatS.isEntity = true;
            
            //validate this is getting stored in the struct correctly
            if(amount > 0) {
                seatS.stakingWhenQuatity.push([amount, block.timestamp]);
            }      
            stakersShare[staker] = seatS;
        }
        _;
    }

    modifier updateRewardControl(address staker, uint256 amount) {
        if (staker != address(0)) {
            StakingSeatControl memory seatC = stakersControl[staker];
            (, seatC.rewardEarned) = earned(staker);
            seatC.lastSnapshotIndex= latestControlSnapshotIndex();
            seatC.isEntity = true;            
            stakersControl[staker] = seatC;
        }
        _;
    }

    modifier updateRewardWithdraw(address staker) {
        if (staker != address(0)) {
            StakingSeatShare memory seatS = stakersShare[staker];
            StakingSeatControl memory seatC = stakersControl[staker];
            (seatS.rewardEarned, seatC.rewardEarned) = earned(staker);
            seatS.lastSnapshotIndex = latestShareSnapshotIndex();
            seatC.lastSnapshotIndex= latestControlSnapshotIndex();
            seatS.isEntity = true;
            seatC.isEntity = true;
            stakersShare[staker] = seatS;
            stakersControl[staker] = seatC;
        }
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestShareSnapshotIndex() public view returns (uint256) {
        return boardShareHistory.length.sub(1);
    }

    function getLatestShareSnapshot() internal view returns (BoardSnapshotShare memory) {
        return boardShareHistory[latestShareSnapshotIndex()];
    }

    function getLastShareSnapshotIndexOf(address staker)
        public
        view
        returns (uint256)
    {
        return stakersShare[staker].lastSnapshotIndex;
    }

    function getLastShareSnapshotOf(address staker)
        internal
        view
        returns (BoardSnapshotShare memory)
    {
        return boardShareHistory[getLastShareSnapshotIndexOf(staker)];
    }

    // control getters
    function latestControlSnapshotIndex() internal view returns (uint256) {
        return boardControlHistory.length.sub(1);
    }

    function getLatestControlSnapshot() internal view returns (BoardSnapshotControl memory) {
        return boardControlHistory[latestControlSnapshotIndex()];
    }

    function getLastControlSnapshotIndexOf(address staker)
        public
        view
        returns (uint256)
    {
        return stakersControl[staker].lastSnapshotIndex;
    }

    function getLastControlSnapshotOf(address staker)
        internal
        view
        returns (BoardSnapshotControl memory)
    {
        return boardControlHistory[getLastControlSnapshotIndexOf(staker)];
    }

    // =========== Director getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestShareSnapshot().rewardPerShare;
    }

    function rewardPerControl() public view returns (uint256) {
        return getLatestControlSnapshot().rewardPerControl;
    }

    
    // Staking and the dates staked calculate the percentage they would forfeit if they withdraw now
    // be the warning
    function getStakedAmountsShare() public view returns (uint256[2][] memory earned) {
            StakingSeatShare memory seatS = stakersShare[msg.sender];
            return seatS.stakingWhenQuatity;
    }

    function earned(address staker) public view returns (uint256, uint256) {
        uint256 latestRPS = getLatestShareSnapshot().rewardPerShare;
        uint256 storedRPS = getLastShareSnapshotOf(staker).rewardPerShare;

        uint256 latestRPC = getLatestControlSnapshot().rewardPerControl;
        uint256 storedRPC = getLastControlSnapshotOf(staker).rewardPerControl;

        return
            (getbalanceOfShare(staker).mul(latestRPS.sub(storedRPS)).div(1e18).add(stakersShare[staker].rewardEarned),
            getbalanceOfControl(staker).mul(latestRPC.sub(storedRPC)).div(1e18).add(stakersControl[staker].rewardEarned));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeShare(uint256 amount)
        public
        override
        onlyOneBlock
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        stakeShareForThirdParty(msg.sender, msg.sender,amount);
        emit Staked(msg.sender, amount);
    }

    function stakeShareForThirdParty(address staker, address from,uint256 amount)
        public
        override
        onlyOneBlock
        updateRewardShare(staker, amount)
        {
            require(amount > 0, 'Boardroom: Cannot stake 0');
            super.stakeShareForThirdParty(staker, from, amount);
            emit Staked(from, amount);
        }

    function stakeControl(uint256 amount)
        public
        override
        onlyOneBlock
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        stakeControlForThirdParty(msg.sender, msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function stakeControlForThirdParty(address staker, address from, uint256 amount)
        public
        override
        onlyOneBlock
        updateRewardControl(staker, amount)
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        super.stakeControlForThirdParty(staker, from, amount);
        emit Staked(staker, amount);
    }

    // this function withdraws all of your LIFT tokens regardless of timestamp 
    // using this function could lead to significant reductions if claimed LIFT
    function withdrawShareDontCallMeUnlessYouAreCertain()
        public
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        uint256 actualAmount = 0;
        require(getbalanceOfShare(msg.sender) > 0, 'Boardroom: Cannot withdraw 0');

        StakingSeatShare storage seatS = stakersShare[msg.sender];
        //forloop that iterates on the stakings and determines the reduction if any before creating a final amount for withdrawl
         for (uint256 i = 0; i < seatS.stakingWhenQuatity.length; i++) {
             uint256[2] storage arrStaked = seatS.stakingWhenQuatity[i];
             uint daysStaked = (block.timestamp - arrStaked[1]) / 60 / 60 / 24; // = Y Days
             if (daysStaked >= daysRequiredStaked){
                   settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                   setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                   IERC20(share).safeTransfer(msg.sender, arrStaked[0]);
                   actualAmount += arrStaked[0];
             } else {
                //calculate reduction percentage  
                // EX only staked 35 days of 60 
                // 60 - 35 = 25% reduction
                // 100 - 25% = 75% remaining (multiply by that / div 100)
                uint256 reducedAmount = arrStaked[0].mul(uint256(100).sub(daysRequiredStaked.sub(daysStaked))).div(100);
                settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                IERC20(share).safeTransfer(msg.sender, reducedAmount);
                IERC20(share).safeTransfer(address(ideaFund), arrStaked[0].sub(reducedAmount));
                actualAmount += reducedAmount;
             }
            //Make sure this is actually 0ing out and saving to the struct
            arrStaked[0] = 0;
            arrStaked[1] = 0;
         }

        emit WithdrawnWithReductionShare(msg.sender, actualAmount);
    }

    // The withdrawShare function with a timestamp input should take that data right out of the below 
    // and feed it back to withdraw
    function withdrawShare(uint256 stakedTimeStamp)
        public
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        uint256 amount = 0;
        uint256 actualAmount = 0;

        StakingSeatShare storage seatS = stakersShare[msg.sender];
        //forloop that iterates on the stakings and determines the reduction if any before creating a final amount for withdrawl
         for (uint256 i = 0; i < seatS.stakingWhenQuatity.length; i++) {
             uint256[2] storage arrStaked = seatS.stakingWhenQuatity[i];
             if(arrStaked[1] == stakedTimeStamp) {
                amount = arrStaked[0];
                uint daysStaked = (block.timestamp - arrStaked[1]) / 60 / 60 / 24; // = Y Days
                //console.log("days staked", daysStaked);
                if (daysStaked >= daysRequiredStaked){
                    settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                    setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                    IERC20(share).safeTransfer(msg.sender, arrStaked[0]);
                    actualAmount += arrStaked[0];
                } else {
                    //calculate reduction percentage  
                    // EX only staked 35 days of 60 
                    // 60 - 35 = 25% reduction
                    // 100 - 25% = 75% remaining (multiply by that / div 100)
                    uint256 reducedAmount = arrStaked[0].mul(uint256(100).sub(daysRequiredStaked.sub(daysStaked))).div(100);

                    settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                    setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                    IERC20(share).safeTransfer(msg.sender, reducedAmount);
                    IERC20(share).safeTransfer(address(ideaFund), arrStaked[0].sub(reducedAmount));
                    actualAmount += reducedAmount;
                }
                
                //Make sure this is actually 0ing out and saving to the struct
                arrStaked[0] = 0;
                arrStaked[1] = 0;
             }          
         }

        emit WithdrawnWithReductionShare(msg.sender, actualAmount);
    }

    function withdrawControl(uint256 amount)
        public
        override
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        require(amount > 0, 'Boardroom: Cannot withdraw 0');
        super.withdrawControl(amount);
        emit WithdrawControl(msg.sender, amount);
    }

    function claimReward()
        public
        updateRewardWithdraw(msg.sender)
    {
        uint256 reward = stakersShare[msg.sender].rewardEarned;
        reward += stakersControl[msg.sender].rewardEarned;

        if (reward > 0) {
            stakersShare[msg.sender].rewardEarned = 0;
            stakersControl[msg.sender].rewardEarned = 0;
            IERC20(control).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount)
        external
        onlyOneBlock
        onlyOperator
    {
        if(amount == 0)
            return;

        if(gettotalSupplyShare() == 0 && gettotalSupplyControl() == 0)
            return;

        uint256 shareValue = gettotalSupplyShare().mul(IOracle(theOracle).priceOf(share));
        uint256 controlValue = gettotalSupplyControl().mul(IOracle(theOracle).priceOf(control));

        uint256 totalStakedValue = shareValue + controlValue;

        uint percision = 9;

        uint256 rewardPerShareValue = amount.mul(shareValue.mul(10**percision).div(totalStakedValue)).div(10**percision);
        uint256 rewardPerControlValue = amount.mul(controlValue.mul(10**percision).div(totalStakedValue)).div(10**percision);

        if (rewardPerShareValue > 0) {
            uint256 prevRPS = getLatestShareSnapshot().rewardPerShare;

            uint256 nextRPS = prevRPS.add(rewardPerShareValue.mul(1e18).div(gettotalSupplyShare()));

            BoardSnapshotShare memory newSSnapshot = BoardSnapshotShare({
                time: block.number,
                rewardReceived: amount,
                rewardPerShare: nextRPS
            });
            boardShareHistory.push(newSSnapshot);
        }

        if (rewardPerControlValue > 0 ) {
            uint256 prevRPC = getLatestControlSnapshot().rewardPerControl;

            uint256 nextRPC = prevRPC.add(rewardPerControlValue.mul(1e18).div(gettotalSupplyControl()));

            BoardSnapshotControl memory newCSnapshot = BoardSnapshotControl({
                time: block.number,
                rewardReceived: amount,
                rewardPerControl: nextRPC
            });
            boardControlHistory.push(newCSnapshot);
        }

        IERC20(control).safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function updateOracle(address newOracle) public onlyOwner {
        theOracle = newOracle;
    }

    function setIdeaFund(address newFund) public onlyOwner {
        ideaFund = newFund;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event WithdrawControl(address indexed user, uint256 amount); 
    event WithdrawnWithReductionShare(address indexed user, uint256 actualAmount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);
}