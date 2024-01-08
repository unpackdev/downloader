// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./ILQTYToken.sol";

/*
* The lockup contract architecture utilizes a single LockupContract, with an unlockTime. The unlockTime is passed as an argument 
* to the LockupContract's constructor. The contract's balance can be withdrawn by the beneficiary when block.timestamp > unlockTime. 
* At construction, the contract checks that unlockTime is at least one year later than the Liquity system's deployment time. 

* Within the first year from deployment, the deployer of the LQTYToken (Liquity AG's address) may transfer LQTY only to valid 
* LockupContracts, and no other addresses (this is enforced in LQTYToken.sol's transfer() function).
* 
* The above two restrictions ensure that until one year after system deployment, LQTY tokens originating from Liquity AG cannot 
* enter circulating supply and cannot be staked to earn system revenue.
*/
contract LockupContract {
    using SafeMath for uint;

    // --- Data ---
    string constant public NAME = "LockupContract";

    uint constant public SECONDS_IN_ONE_YEAR = 3 * 31 days; 
    // uint constant public SECONDS_IN_ONE_YEAR = 1 days; 


    address public immutable beneficiary;

    // Unlock time is the Unix point in time at which the beneficiary can withdraw.
    uint public unlockTime;

    bool public isStakingTransfer;

    // --- Events ---

    event LockupContractCreated(address _beneficiary, uint _unlockTime);
    event LockupContractEmptied(uint _LQTYwithdrawal);

    // --- Functions ---

    constructor 
    (
        address _beneficiary
    )
        public 
    {
        /*
        * Set the unlock time to a chosen instant in the future, as long as it is at least 1 year after
        * the system was deployed 
        */
        unlockTime = block.timestamp.add(SECONDS_IN_ONE_YEAR);
        
        beneficiary =  _beneficiary;
        emit LockupContractCreated(_beneficiary, unlockTime);
    }

    function withdrawLQTY(address _lqtyToken) external {
        _requireCallerIsBeneficiary();
        _requireLockupDurationHasPassed();

        ILQTYToken lqtyTokenCached = ILQTYToken(_lqtyToken);
        uint LQTYBalance = lqtyTokenCached.balanceOf(address(this));
        lqtyTokenCached.transfer(beneficiary, LQTYBalance);
        emit LockupContractEmptied(LQTYBalance);
    }

    function withdrawLQTYForStaking(address _stakingSupplyContract, address _lqtyToken) external {
        _requireCallerIsBeneficiary();
        _requireStakingTransfeOnce();
        ILQTYToken lqtyTokenCached = ILQTYToken(_lqtyToken);
        uint LQTYBalance = lqtyTokenCached.balanceOf(address(this));
        lqtyTokenCached.transfer(_stakingSupplyContract, LQTYBalance.div(2));
    }

    // --- 'require' functions ---

    function _requireCallerIsBeneficiary() internal view {
        require(msg.sender == beneficiary, "LockupContract: caller is not the beneficiary");
    }

    function _requireLockupDurationHasPassed() internal view {
        require(block.timestamp >= unlockTime, "LockupContract: The lockup duration must have passed");
    }

    // function _requireUnlockTimeIsAtLeastOneYearAfterSystemDeployment(uint _unlockTime) internal view {
    //     uint systemDeploymentTime = lqtyToken.getDeploymentStartTime();
    //     require(_unlockTime >= systemDeploymentTime.add(SECONDS_IN_ONE_YEAR), "LockupContract: unlock time must be at least one year after system deployment");
    // }

    function _requireStakingTransfeOnce() internal {
        require (isStakingTransfer == false, "LockupContract: can be transferred only once");
        isStakingTransfer = true;
    }
}
