// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IStripToken.sol";

contract PrivateVesting {
    using SafeMath for uint256;

    struct VestingSchedule {
      uint256 totalAmount; // Total amount of tokens to be vested.
      uint256 amountWithdrawn; // The amount that has been withdrawn.
      uint256 startTime;
    }

    address private owner;
    address private presaleContract; // Presale contract
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds

    mapping(address => VestingSchedule) public recipients;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint256 constant TOTAL_SUPPLY = 500e27;
    uint256 constant UNLOCK_UNIT = 10; // 10% of the total allocation will be unlocked
    uint256 constant INITIAL_LOCK_PERIOD = 45 days; // No tokens will be unlocked for the first 45 days

    uint256 public vestingAllocation; // Max amount which will be locked in vesting contract
    
    uint256 private totalAllocated; // The amount of allocated tokens

    event VestingScheduleRegistered(address registeredAddress, uint256 totalAmount);
    event VestingSchedulesRegistered(address[] registeredAddresses, uint256[] totalAmounts);
    event MultiSigAdminUpdated(address _multiSigAdmin);

    IStripToken public stripToken;

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(msg.sender == multiSigAdmin || presaleContract == msg.sender, "Should be multiSig contract");
        _;
    }

    constructor(address _stripToken, address _presaleContract, address payable _multiSigAdmin) {
        owner = msg.sender;

        stripToken = IStripToken(_stripToken);
        presaleContract = _presaleContract;
        multiSigAdmin = _multiSigAdmin;
        vestingAllocation = TOTAL_SUPPLY;
        
        /// Allow presale contract to withdraw unsold strip tokens to multiSig admin
        stripToken.approve(presaleContract, MAX_UINT256);
    }

    function setMultiSigAdminAddress(address payable _multiSigAdmin) external onlyOwner {
        require (_multiSigAdmin != address(0x00));
        multiSigAdmin = _multiSigAdmin;
        emit MultiSigAdminUpdated(multiSigAdmin);
    }

    function setPresaleContractAddress(address _presaleContract) external onlyOwner {
        require (_presaleContract != address(0x00));
        presaleContract = _presaleContract;
        stripToken.approve(_presaleContract, MAX_UINT256);
    }

    function setVestingAllocation(uint256 _newAlloc) external onlyOwner {
        require(_newAlloc <= TOTAL_SUPPLY, "setVestingAllocation: Exceeds total supply");
        vestingAllocation = _newAlloc;
    }

    /**
     * @dev Private function to add a recipient to vesting schedule
     * @param _recipient the address to be added
     * @param _totalAmount integer variable to indicate strip amount of the recipient
     */

    function addRecipient(address _recipient, uint256 _totalAmount, bool isPresaleBuyer) private {
        require(_recipient != address(0x00), "addRecipient: Invalid recipient address");
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(!isPresaleBuyer || (isPresaleBuyer && recipients[_recipient].totalAmount == 0), "addRecipient: Already allocated");
        require(totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount) <= vestingAllocation, "addRecipient: Total Allocation Overflow");

        totalAllocated = totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount);
        
        recipients[_recipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0,
            startTime: block.timestamp
        });
    }
    
    /**
     * @dev Add new recipient to vesting schedule
     * @param _newRecipient the address to be added
     * @param _totalAmount integer variable to indicate strip amount of the recipient
     */

    function addNewRecipient(address _newRecipient, uint256 _totalAmount, bool isPresaleBuyer) external onlyOwner {
        addRecipient(_newRecipient, _totalAmount, isPresaleBuyer);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    /**
     * @dev Add new recipients to vesting schedule
     * @param _newRecipients the addresses to be added
     * @param _totalAmounts integer array to indicate strip amount of recipients
     */

    function addNewRecipients(address[] memory _newRecipients, uint256[] memory _totalAmounts, bool isPresaleBuyer) external onlyOwner {
                for (uint256 i = 0; i < _newRecipients.length; i++) {
            addRecipient(_newRecipients[i], _totalAmounts[i], isPresaleBuyer);
        }
        
        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts);
    }

  
    /**
     * @dev Gets the locked strip amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getLocked(address beneficiary) external view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    /**
     * @dev Gets the claimable strip amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getWithdrawable(address beneficiary) public view returns (uint256) {
        return getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    /**
     * @dev Claim unlocked strip tokens of a recipient
     * @param _recipient address of recipient
     */
    function withdrawToken(address _recipient) external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = _vested.sub(recipients[msg.sender].amountWithdrawn);
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(stripToken.transfer(_recipient, _withdrawable));
        
        return _withdrawable;
    }

    /**
     * @dev Get claimable strip token amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getVested(address beneficiary) public view virtual returns (uint256 _amountVested) {
        require(beneficiary != address(0x00), "getVested: Invalid address");
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];

        if (
            (_vestingSchedule.totalAmount == 0) ||
            (block.timestamp < _vestingSchedule.startTime) ||
            (block.timestamp < _vestingSchedule.startTime.add(INITIAL_LOCK_PERIOD))
        ) {
            return 0;
        }

        uint256 vestedPercent = 0;
        uint256 firstVestingPoint = _vestingSchedule.startTime.add(INITIAL_LOCK_PERIOD);
        uint256 vestingPeriod = 270 days;
        
        uint256 secondVestingPoint = firstVestingPoint.add(vestingPeriod);
        if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
            vestedPercent = 10 + (block.timestamp - firstVestingPoint).mul(90).div(vestingPeriod);
        } else if (block.timestamp > secondVestingPoint) {
            vestedPercent = 100;
        }

        uint256 vestedAmount = _vestingSchedule.totalAmount.mul(vestedPercent).div(100);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }

        return vestedAmount;
    }
}
