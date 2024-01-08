// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./string.sol";
import "./IERC20.sol";
import "./sort.sol";

struct GlqStaker {
    address wallet;
    uint256 block_number;
    uint256 amount;
    uint256 index_at;
    bool already_withdrawn;
}

struct GraphLinqApyStruct {
    uint256 tier1Apy;
    uint256 tier2Apy;
    uint256 tier3Apy;      
}

contract GlqStakingContract {

    using SafeMath for uint256;
    using strings for *;
    using QuickSorter for *;

    event NewStakerRegistered (
        address staker_address,
        uint256 at_block,
        uint256 amount_registered
    );

    /*
    ** Address of the GLQ token hash: 0x9F9c8ec3534c3cE16F928381372BfbFBFb9F4D24
    */
    address private _glqTokenAddress;

    /*
    ** Manager of the contract to add/remove APYs bonuses into the staking contract
    */
    address private _glqDeployerManager;

    /*
    ** Current amount of GLQ available in the pool as rewards
    */
    uint256 private _totalGlqIncentive;

    GlqStaker[]                     private _stakers;
    uint256                         private _stakersIndex;
    uint256                         private _totalStaked;
    bool                            private _emergencyWithdraw;

    mapping(address => uint256)     private _indexStaker;
    uint256                         private _blocksPerYear;
    GraphLinqApyStruct              private _apyStruct;

    constructor(address glqAddr, address manager) {
        _glqTokenAddress = glqAddr;
        _glqDeployerManager = manager;

        _totalStaked = 0;
        _stakersIndex = 1;
        
        _blocksPerYear = 2250000;
        
        // default t1: 30%, t2: 15%, t3: 7.5%
        _apyStruct = GraphLinqApyStruct(50*1e18, 25*1e18, 12500000000000000000);
    }


    /* Getter ---- Read-Only */

    /*
    ** Return the sender wallet position from the tier system
    */
    function getWalletCurrentTier(address wallet) public view returns (uint256) {
        uint256 currentTier = 3;
        uint256 index = _indexStaker[wallet];
        require(
            index != 0,
            "You dont have any tier rank currently in the Staking contract."
        );
        uint256 walletAggregatedIndex = (index).mul(1e18);

        // Total length of stakers
        uint256 totalIndex = _stakers.length.mul(1e18);
        // 15% of hodlers in T1 
        uint256 t1MaxIndex = totalIndex.div(100).mul(15);
        // 55% of hodlers in T2
        uint256 t2MaxIndex = totalIndex.div(100).mul(55);

        if (walletAggregatedIndex <= t1MaxIndex) {
            currentTier = 1;
        } else if (walletAggregatedIndex > t1MaxIndex && walletAggregatedIndex <= t2MaxIndex) {
            currentTier = 2;
        }

        return currentTier;
    }

    /*
    ** Return rank position of a wallet
    */
    function getPosition(address wallet) public view returns (uint256) {
         uint256 index = _indexStaker[wallet];
         return index;
    }

    /*
    ** Return the amount of GLQ that a wallet can currently claim from the staking contract
    */
    function getGlqToClaim(address wallet) public view returns(uint256) {
        uint256 index = _indexStaker[wallet];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];

        uint256 calculatedApr = getWaitingPercentAPR(wallet);
        return staker.amount.mul(calculatedApr).div(100).div(1e18);
    }

    /*
    ** Return the current percent winnable for a staker wallet
    */
    function getWaitingPercentAPR(address wallet) public view returns(uint256) {
        uint256 index = _indexStaker[wallet];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];

        uint256 walletTier = getWalletCurrentTier(wallet);
        uint256 blocksSpent = block.number.sub(staker.block_number);
        if (blocksSpent == 0) { return 0; }
        uint256 percentYearSpent = percent(blocksSpent.mul(10000), _blocksPerYear.mul(10000), 20);

        uint256 percentAprGlq = _apyStruct.tier3Apy;
        if (walletTier == 1) {
            percentAprGlq = _apyStruct.tier1Apy;
        } else if (walletTier == 2) {
            percentAprGlq = _apyStruct.tier2Apy;
        }

        return percentAprGlq.mul(percentYearSpent).div(100).div(1e18);
    }

    /*
    ** Return the total amount of GLQ as incentive rewards in the contract
    */
    function getTotalIncentive() public view returns (uint256) {
        return _totalGlqIncentive;
    }

    /*
    ** Return the total amount in staking for an hodler.
    */
    function getDepositedGLQ(address wallet) public view returns (uint256) {
        uint256 index = _indexStaker[wallet];
        if (index == 0) { return 0; }
        return _stakers[index-1].amount;
    }

    /*
    ** Count the total numbers of stakers in the contract
    */
    function getTotalStakers() public view returns(uint256) {
        return _stakers.length;
    }

    /*
    ** Return all APY per different Tier
    */
    function getTiersAPY() public view returns(uint256, uint256, uint256) {
        return (_apyStruct.tier1Apy, _apyStruct.tier2Apy, _apyStruct.tier3Apy);
    }

    /*
    ** Return the Total staked amount
    */
    function getTotalStaked() public view returns(uint256) {
        return _totalStaked;
    }

    /*
    ** Return the top 3 of stakers (by age)
    */
    function getTopStakers() public view returns(address[] memory, uint256[] memory) {
        uint256 len = _stakers.length;
        address[] memory addresses = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        for (uint i = 0; i < len && i <= 2; i++) {
            addresses[i] = _stakers[i].wallet;
            amounts[i] = _stakers[i].amount;
        }

        return (addresses, amounts);
    }

    /*
    ** Return the total amount deposited on a rank tier
    */
    function getTierTotalStaked(uint tier) public view returns (uint256) {
        uint256 totalAmount = 0;

        // Total length of stakers
        uint256 totalIndex = _stakers.length.mul(1e18);
        // 15% of hodlers in T1 
        uint256 t1MaxIndex = totalIndex.div(100).mul(15);
        // 55% of hodlers in T2
        uint256 t2MaxIndex = totalIndex.div(100).mul(55);

        uint startIndex = (tier == 1) ? 0 : t1MaxIndex.div(1e18);
        uint endIndex = (tier == 1) ? t1MaxIndex.div(1e18) : t2MaxIndex.div(1e18);
        
        if (tier == 3) {
            startIndex = t2MaxIndex.div(1e18);
            endIndex = _stakers.length;
        }

        for (uint i = startIndex; i <= endIndex && i < _stakers.length; i++) {
            totalAmount +=  _stakers[i].amount;
        }
      
        return totalAmount;
    }

    /* Getter ---- Read-Only */


    /* Setter - Read & Modifications */


    /*
    ** Enable emergency withdraw by GLQ Deployer
    */
    function setEmergencyWithdraw(bool state) public {
        require (
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can change the state of the emergency withdraw"
        );
        _emergencyWithdraw = state;
    }

    /*
    ** Set numbers of blocks spent per year to calculate claim rewards
    */
    function setBlocksPerYear(uint256 blocks) public {
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can change blocks spent per year");
        _blocksPerYear = blocks;
    }

    /*
    ** Update the APY rewards for each tier in percent per year
    */
    function setApyPercentRewards(uint256 t1, uint256 t2, uint256 t3) public {
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can APY rewards");
        GraphLinqApyStruct memory newApy = GraphLinqApyStruct(t1, t2, t3);
        _apyStruct = newApy;
    }

    /*
    ** Add GLQ liquidity in the staking contract for stakers rewards 
    */
    function addIncentive(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can add incentive into the smart-contract");
        require(
            glqToken.balanceOf(msg.sender) >= glqAmount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transferFrom(msg.sender, address(this), glqAmount) == true,
            "Error transferFrom on the contract"
        );
        _totalGlqIncentive += glqAmount;
    }

    /*
    ** Remove GLQ liquidity from the staking contract for stakers rewards 
    */
    function removeIncentive(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can remove incentive from the smart-contract");
        require(
            glqToken.balanceOf(address(this)) >= glqAmount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transfer(msg.sender, glqAmount) == true,
            "Error transfer on the contract"
        );

        _totalGlqIncentive -= glqAmount;
    }


    /*
    ** Deposit GLQ in the staking contract to stake & earn
    */
    function depositGlq(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            glqToken.balanceOf(msg.sender) >= glqAmount,
            "Insufficient funds from the sender");
        require(
           glqToken.transferFrom(msg.sender, address(this), glqAmount) == true,
           "Error transferFrom on the contract"
        );

        uint256 index = _indexStaker[msg.sender];
        _totalStaked += glqAmount;

        if (index == 0) {
            GlqStaker memory staker = GlqStaker(msg.sender, block.number, glqAmount, _stakersIndex, false);
            _stakers.push(staker);
            _indexStaker[msg.sender] = _stakersIndex;

            // emit event of a new staker registered at current block position
            emit NewStakerRegistered(msg.sender, block.number, glqAmount);
            _stakersIndex = _stakersIndex.add(1);
        }
        else {
            // claim rewards before adding new staking amount
            if (_stakers[index-1].amount > 0) {
                claimGlq();
            }
            _stakers[index-1].amount += glqAmount;
        }
    }

    function removeStaker(GlqStaker storage staker) private {
        uint256 currentIndex = _indexStaker[staker.wallet]-1;
        _indexStaker[staker.wallet] = 0;
        for (uint256 i= currentIndex ; i < _stakers.length-1 ; i++) {
            _stakers[i] = _stakers[i+1];
            _stakers[i].index_at = _stakers[i].index_at.sub(1);
            _indexStaker[_stakers[i].wallet] = _stakers[i].index_at;
        }
        _stakers.pop();

        // Remove the staker and decrease stakers index
        _stakersIndex = _stakersIndex.sub(1);
        if (_stakersIndex == 0) { _stakersIndex = 1; }
    }

    /*
    ** Emergency withdraw enabled by GLQ team in an emergency case
    */
    function emergencyWithdraw() public {
        require(
            _emergencyWithdraw == true,
            "The emergency withdraw feature is not enabled"
        );
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        IERC20 glqToken = IERC20(_glqTokenAddress);

        require(
            staker.amount > 0,
         "Not funds deposited in the staking contract");

        require(
            glqToken.transfer(msg.sender, staker.amount) == true,
            "Error transfer on the contract"
        );
        staker.amount = 0;
    }

    /*
    ** Withdraw Glq from the staking contract (reduce the tier position)
    */
    function withdrawGlq() public {
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            staker.amount > 0,
         "Not funds deposited in the staking contract");
    
        //auto claim when withdraw
        claimGlq();

        _totalStaked -= staker.amount;
        require(
            glqToken.balanceOf(address(this)) >= staker.amount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transfer(msg.sender, staker.amount) == true,
            "Error transfer on the contract"
        );
        staker.amount = 0;
        
        if (staker.already_withdrawn) {
            removeStaker(staker);
        } else {
            staker.already_withdrawn = true;
        }
    }

    function percent(uint256 numerator, uint256 denominator, uint256 precision) private pure returns(uint256) {
        uint256 _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    /*
    ** Claim waiting rewards from the staking contract
    */
    function claimGlq() public returns(uint256) {
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        uint256 glqToClaim = getGlqToClaim(msg.sender);
        IERC20 glqToken = IERC20(_glqTokenAddress);
        if (glqToClaim == 0) { return 0; }

        require(
            glqToken.balanceOf(address(this)) >= glqToClaim,
            "Not enough funds in the staking program to claim rewards"
        );

        staker.block_number = block.number;

        require(
            glqToken.transfer(msg.sender, glqToClaim) == true,
            "Error transfer on the contract"
        );
        return (glqToClaim);
    }

    /* Setter - Read & Modifications */

}