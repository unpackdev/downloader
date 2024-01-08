// SPDX-License-Identifier: Apache-2.0
/**
 * @title: B2B Program Vester Contract
 * @summary:
 * @author: Idle Labs Inc., idle.finance
 */
pragma solidity 0.8.4;

import "./console.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Vester {
  using SafeERC20 for IERC20;

  address private _owner;
  bool public initialized;

  address public idle;
  address public recipient;
  uint256 public claimIndex; // Useful to skip claimed deposits
  uint256 public lastUpdate; // Last claim timestamp
  uint256 public vestingPeriod; // Expressed in seconds
  uint[] public depositTimestamps; // Deposit timestamps array
  uint256[] public depositAmounts; // Deposit amounts array

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
  }

  function initialize (
    address owner_,
    address idle_,
    address recipient_,
    uint256 vestingPeriod_
  ) external {
    require(!initialized, "Already initialized");
    require(idle_ != address(0), 'B2BVester::constructor: invalid Idle address');
    require(owner_ != address(0), 'B2BVester::constructor: invalid Owner address');
    require(recipient_ != address(0), 'B2BVester::constructor: invalid recipient address');

    // Set idle address
    idle = idle_;
    _owner = owner_;
    recipient = recipient_;
    vestingPeriod = vestingPeriod_;

    // Set as inizialized
    initialized = true;
  }

  function setRecipient(address recipient_) external {
    require(recipient_ != address(0), 'B2BVester::setRecipient: invalid');
    require(msg.sender == recipient || msg.sender == _owner, 'B2BVester::setRecipient: unauthorized');
    recipient = recipient_;
  }

  function claim() external {
    require(depositTimestamps.length > 0, 'B2BVester::claim: no deposits yet');
    require(claimIndex < depositTimestamps.length, 'B2BVester::claim: nothing to withdraw');

    uint256 amount = 0;
    uint256 _claimIndex = 0;
    for (uint256 i = claimIndex; i < depositTimestamps.length; i++) {
      uint256 vestingStart = depositTimestamps[i];
      uint256 vestingEnd = vestingStart+vestingPeriod;

      // If lastUpdate >= vestingEnd the deposit has already been totally claimed
      if (lastUpdate < vestingEnd) {
        uint256 _lastUpdate = lastUpdate;
        if (_lastUpdate < vestingStart) {
          _lastUpdate = vestingStart;
        }
        uint256 blockTime = block.timestamp;
        if (blockTime > vestingEnd) {
          blockTime = vestingEnd;
        }

        uint256 vestedAmount = depositAmounts[i]*(blockTime - _lastUpdate)/vestingPeriod;
        amount = amount+vestedAmount;

        // Increase claimIndex to skip claimed deposits
        if (blockTime >= vestingEnd){
          _claimIndex = i+1;
        }

      // Increase claimIndex to skip claimed deposits
      } else {
        _claimIndex = i+1;
      }
    }

    IERC20(idle).safeTransfer(recipient, amount);

    claimIndex = _claimIndex;
    lastUpdate = block.timestamp;
  }

  function deposit(uint256 _amount) external onlyOwner {
    IERC20(idle).transferFrom(msg.sender, address(this), _amount);

    // Initialize lastUpdate
    if (depositTimestamps.length == 0) {
      lastUpdate = block.timestamp;
    }

    depositAmounts.push(_amount);
    depositTimestamps.push(block.timestamp);
  }

  function emergencyWithdrawal(address _token,address to, uint256 amount) external onlyOwner {
    require(_token != address(0), 'B2BVester::emergencyWithdrawal: invalid token address');
    require(to != address(0), 'B2BVester::emergencyWithdrawal: invalid recipient address');
    IERC20(_token).safeTransfer(to, amount);
  }

  function getDepositAmounts() external view returns (uint256[] memory) {
    return depositAmounts;
  }

  function owner() external view virtual returns (address) {
      return _owner;
  }

  function transferOwnership(address newOwner) external onlyOwner {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
  }
}

interface IIdle {
  function balanceOf(address account) external view returns (uint);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
}
