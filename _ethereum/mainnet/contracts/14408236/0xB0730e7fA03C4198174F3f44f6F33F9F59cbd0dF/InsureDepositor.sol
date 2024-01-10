pragma solidity 0.8.10;

/***
 *@title InsureDepositor
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice convert INSURE to vlINSURE. Lock deposited INSURE into VotingEscrow and aggregate veINSURE.
 */
 
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Interfaces.sol";
import "./IOwnership.sol";

contract InsureDepositor is 
    Initializable, 
    UUPSUpgradeable,
    ERC20Upgradeable 
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event SetGauge(address newGauge);
    event SetLockIncentive(uint256 newLockIncentive);

    address public insure;
    address public escrow;
    address public gauge;
    IOwnership public ownership;

    uint256 private constant MAXTIME = 4 * 365 * 86400;
    uint256 private constant WEEK = 7*86400;
    uint256 public lockIncentive; //incentive to users who spend gas to lock insure
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public incentiveInsure;
    uint256 public unlockTime;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    function initialize(
        address _insure,
        address _escrow,
        address _ownership
    ) public initializer {
        require(_insure != address(0));
        require(_escrow != address(0));
        require(_ownership != address(0));

        insure = _insure;
        escrow = _escrow;
        ownership = IOwnership(_ownership);
        
        __ERC20_init("Vote Locked Insure Token", "vlINSURE");

        IERC20Upgradeable(insure).safeApprove(escrow, type(uint256).max);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}


    function initialLock() external onlyOwner{
        uint256 veinsure = IERC20Upgradeable(escrow).balanceOf(address(this));
        if(veinsure == 0){
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = unlockAt / WEEK;

            //release old lock if exists
            _release();

            //create new lock
            uint256 insureBalanceStaker = IERC20Upgradeable(insure).balanceOf(address(this));
            _createLock(insureBalanceStaker, unlockAt);

            unlockTime = unlockInWeeks;
        }
    }

    function deposit(uint256 _amount, bool _lock, bool _stake) public {
        /**
        * @notice Deposit INSURE and get vlINSURE. This is irreversible.
        * @param _amount amount of INSURE to deposit
        * @param _lock true if lock INSURE
        * @param _stake true if user wants to stake into gauge. 
        * @dev user has to call gauge.set_approve_deposit() first to set true on _stake
        */

        require(_amount > 0,"!>0");

        //transfer token to here
        IERC20Upgradeable(insure).safeTransferFrom(msg.sender, address(this), _amount);
         
        if(!_lock){
            //defer lock cost to another user
            uint256 callIncentive = _amount * lockIncentive / FEE_DENOMINATOR;
            _amount = _amount - callIncentive;

            //add to a pool for lock caller
            incentiveInsure += callIncentive;
        }else{
            _lockInsure();

            if(incentiveInsure > 0){
                //add the incentive tokens here so they can be staked together
                _amount = _amount + incentiveInsure;
                incentiveInsure = 0;
            }
        }

        if(!_stake){
            //mint for msg.sender
            _mint(msg.sender, _amount);
        }else{
            //mint here 
            _mint(address(this), _amount);

            //stake for msg.sender
            IInsureGauge(gauge).deposit(_amount, msg.sender);
        }
    }

    function depositAll(bool _lock, bool _stake) external{
        uint256 insureBal = IERC20Upgradeable(insure).balanceOf(msg.sender);
        deposit(insureBal, _lock, _stake);
    }
    
    function lockInsure() external {
        _lockInsure();

        //mint incentives
        if(incentiveInsure > 0){
            _mint(msg.sender, incentiveInsure);
            incentiveInsure = 0;
        }
    }


    //set functions
    function setGauge(address _gauge)external onlyOwner{
        require(_gauge != address(0));

        gauge = _gauge;
        _approve(address(this), _gauge, type(uint256).max);

        emit SetGauge(_gauge);
    }

    function setLockIncentive(uint256 _lockIncentive)external onlyOwner{
        require(_lockIncentive < FEE_DENOMINATOR, "never be 100%");

        lockIncentive = _lockIncentive;
        emit SetLockIncentive(_lockIncentive);
    }


    //internal functions
    function _lockInsure() internal {
        uint256 insureBalance = IERC20Upgradeable(insure).balanceOf(address(this));
        
        if(insureBalance == 0){
            return;
        }
        
        //increase amount
        _increaseAmount(insureBalance);

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = unlockAt / WEEK ;

        //increase time too if over 2 week buffer
        if(unlockInWeeks - unlockTime > 2){
            _increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    function _createLock(uint256 _value, uint256 _unlockTime) internal returns(bool){
        IInsureVoteEscrow(escrow).create_lock(_value, _unlockTime);
        return true;
    }

    function _increaseAmount(uint256 _value) internal returns(bool){
        IInsureVoteEscrow(escrow).increase_amount(_value);
        return true;
    }

    function _increaseTime(uint256 _value) internal returns(bool){
        IInsureVoteEscrow(escrow).increase_unlock_time(_value);
        return true;
    }

    function _release() internal returns(bool){
        IInsureVoteEscrow(escrow).withdraw();
        return true;
    }
}