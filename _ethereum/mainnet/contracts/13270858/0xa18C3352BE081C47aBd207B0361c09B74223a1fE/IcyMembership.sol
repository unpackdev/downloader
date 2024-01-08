// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

// TODO dev only
// import "./console.sol";

/**
 * IcyMembership contract
 * @author @icy_tools
 */
contract IcyMembership is ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  // Events
  event ClaimTrial(address indexed _from);
  event Pay(address indexed _from, uint _value);

  // Enable/disable new/trial members
  bool public isAcceptingNewMemberships = true;
  bool public isAcceptingTrialMemberships = false;

  // 0.0008 ETH
  uint256 public serviceFeePerDay = 800000000000000;

  // Minimum days that can be purchased
  uint8 public minimumServiceDays = 30;

  // Number of days in a trial membership
  uint256 public numberOfTrialMembershipDays = 7;

  // Number of days at which to grant a bonus
  uint256 public bonusIntervalInDays = 300;
  uint256 public bonusDaysGrantedPerInterval = 60;

  mapping(address => uint256) private addressPaidUpTo;
  mapping(address => bool) private addressClaimedTrialMembership;
  mapping(address => bool) private blocklist;

  // Called when contract receives ether
  receive() external payable {
    payForServices();
  }

  function payForServices() public payable {
    require(!blocklist[msg.sender], "Sender not allowed.");
    require(isAcceptingNewMemberships, "Memberships are paused.");

    uint256 minimumServiceFee = serviceFeePerDay.mul(minimumServiceDays);
    require(msg.value >= minimumServiceFee, "Minimum payment not met.");

    // Calculate how many seconds we're buying
    uint256 secondsPerWei = serviceFeePerDay.div(86400);
    uint256 secondsToAdd = msg.value.div(secondsPerWei);
    uint256 daysToAdd = secondsToAdd.div(86400);

    if (bonusDaysGrantedPerInterval > 0 && daysToAdd >= bonusIntervalInDays) {
      secondsToAdd = secondsToAdd.add(daysToAdd.div(bonusIntervalInDays).mul(bonusDaysGrantedPerInterval).mul(86400));
    }

    if (addressPaidUpTo[msg.sender] == 0) {
      addressPaidUpTo[msg.sender] = block.timestamp.add(secondsToAdd);
    } else {
      addressPaidUpTo[msg.sender] = addressPaidUpTo[msg.sender].add(secondsToAdd);
    }

    emit Pay(msg.sender, msg.value);
  }

  function hasActiveMembership(address _addr) external view returns(bool) {
    // get the active address
    // compare active address addressPaidUpTo to current time
    return !isAddressBlocked(_addr) && addressPaidUpTo[_addr] >= block.timestamp;
  }

  // Allows anyone to get the paid up to of an address
  function getAddressPaidUpTo(address _addr) public view returns(uint256) {
    return !isAddressBlocked(_addr) ? addressPaidUpTo[_addr] : 0;
  }

  // Allows anyone to see if an address is on the blocklist
  function isAddressBlocked(address _addr) public view returns(bool) {
    return blocklist[_addr];
  }

  // Allows anyone to claim a trial membership if they haven't already
  function claimTrialMembership() external nonReentrant {
    require(isAcceptingTrialMemberships, "Trials not active.");
    require(!blocklist[msg.sender], "Sender not allowed.");
    require(!addressClaimedTrialMembership[msg.sender], "Trial already claimed.");
    require(addressPaidUpTo[msg.sender] == 0, "Trial not allowed.");

    addressPaidUpTo[msg.sender] = block.timestamp.add(numberOfTrialMembershipDays.mul(86400));
    addressClaimedTrialMembership[msg.sender] = true;

    emit ClaimTrial(msg.sender);
  }

  //
  // ADMIN FUNCTIONS
  //

  // Allows `owner` to add an address to the blocklist
  function addAddressToBlocklist(address _addr) external onlyOwner {
    blocklist[_addr] = true;
  }

  // Allows `owner` to remove an address from the blocklist
  function removeAddressFromBlocklist(address _addr) external onlyOwner {
    delete blocklist[_addr];
  }

  // Allows `owner` to set serviceFeePerDay
  function setBonusIntervalInDays(uint256 _bonusIntervalInDays) external onlyOwner {
    bonusIntervalInDays = _bonusIntervalInDays;
  }

  // Allows `owner` to set serviceFeePerDay
  function setBonusDaysGrantedPerInterval(uint256 _bonusDaysGrantedPerInterval) external onlyOwner {
    bonusDaysGrantedPerInterval = _bonusDaysGrantedPerInterval;
  }

  // Allows `owner` to set address paid up to
  function setAddressPaidUpTo(address _addr, uint256 _paidUpTo) external onlyOwner {
    addressPaidUpTo[_addr] = _paidUpTo;
  }

  // Allows `owner` to set serviceFeePerDay
  function setServiceFeePerDay(uint256 _serviceFeePerDay) external onlyOwner {
    require(_serviceFeePerDay > 0, "serviceFeePerDay cannot be 0");
    serviceFeePerDay = _serviceFeePerDay;
  }

  // Allows `owner` to set minimumServiceDays
  function setMinimumServiceDays(uint8 _minimumServiceDays) external onlyOwner {
    require(_minimumServiceDays > 0, "minimumServiceDays cannot be 0");
    minimumServiceDays = _minimumServiceDays;
  }

  // Allows `owner` to set numberOfTrialMembershipDays
  function setNumberOfTrialMembershipDays(uint8 _numberOfTrialMembershipDays) external onlyOwner {
    require(_numberOfTrialMembershipDays > 0, "numberOfTrialMembershipDays cannot be 0");
    numberOfTrialMembershipDays = _numberOfTrialMembershipDays;
  }

  // Allows `owner` to collect service fees.
  function withdraw(uint256 _amount) external nonReentrant onlyOwner {
    require(_amount <= address(this).balance, "Withdraw less");
    require(_amount > 0, "Withdraw more");

    address owner = _msgSender();
    payable(owner).transfer(_amount);
  }

  // Allows `owner` to toggle if minting is active
  function toggleAcceptingNewMemberships() public onlyOwner {
    isAcceptingNewMemberships = !isAcceptingNewMemberships;
  }

  // Allows `owner` to toggle if minting is active
  function toggleAcceptingTrialMemberships() public onlyOwner {
    isAcceptingTrialMemberships = !isAcceptingTrialMemberships;
  }

  function renounceOwnership() public override view onlyOwner {
    revert("Not allowed");
  }
}
