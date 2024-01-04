// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./RewarderRole.sol";

import "./Loan.sol";
import "./Oracle.sol";
import "./IYLD.sol";
import "./DiscountManager.sol";
import "./VersionManager.sol";


interface IRewardManager
{
  event Claim(address indexed borrower, address indexed loan, uint256 amount);


  function trackLoan(address loan, address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) external returns (bool);
}


contract RewardManager is IRewardManager, RewarderRole, ReentrancyGuard, VersionManager
{
  using SafeMath for uint256;


  address private immutable _YLD;

  uint256 private constant _basePrice = 1e18; // $1 scaled
  uint256 private constant _baseRewardCap = 350 * 1e18; // 350 YLD

  uint256 private _lastPrice = 100 * 1e18;
  uint256 private _rewardCostPct = 1 * 1e18; // 1% scaled
  uint256 private _shortDurationPct = 100 * 1e18; // 100%
  uint256 private _rebasingFactor; // 100%
  uint256 private _currentRewardCap;

  mapping(address => bool) private _claimed;
  mapping(address => bool) private _trackedLoan;
  mapping(address => uint256) private _fullRewardOf;


  constructor()
  {
    _YLD = address(0xDcB01cc464238396E213a6fDd933E36796eAfF9f);

    _rebasingFactor = _basePrice.mul(100 * 1e18).div(_lastPrice);
    _currentRewardCap = _calcPercentOf(_baseRewardCap, _rebasingFactor);
  }


  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(100 * 1e18);
  }


  function getRewardOf(address loan) external view returns (uint256)
  {
    return _fullRewardOf[loan];
  }

  function getDetails() external view returns (uint256, uint256, uint256, uint256, uint256)
  {
    return (_rewardCostPct, _shortDurationPct, _rebasingFactor, _lastPrice, _currentRewardCap);
  }


  function hasClaimed(address loan) public view returns (bool)
  {
    return _claimed[loan];
  }

  function calcUnlockDuration(uint256 duration, uint256 timestampStart, uint256 timestampRepaid) public pure returns (uint256 unlockDuration)
  {
    if (duration <= 12 days)
    {
      unlockDuration = timestampRepaid.add(2 days) >= timestampStart.add(duration) ? 10 days : 90 days;
    }
    else
    {
      unlockDuration = (timestampRepaid > timestampStart.add(12 days) && timestampRepaid >= timestampStart.add(10 days).add(_calcPercentOf(duration, 2500))) ? 10 days : 90 days;
    }
  }


  function _getMintableReward(address loan, uint256 timestampRepaid, uint256 timestampFullUnlock) private view returns (uint256)
  {
    uint256 fullReward = _fullRewardOf[loan];
    uint256 mintRate = fullReward.div(timestampFullUnlock.sub(timestampRepaid));

    uint256 secondsSinceRepaid = block.timestamp.sub(timestampRepaid);
    uint256 mintableReward = block.timestamp >= timestampFullUnlock ? fullReward : secondsSinceRepaid.mul(mintRate);

    return mintableReward > _currentRewardCap ? _currentRewardCap : mintableReward;
  }

  function _isEligibleLoan(address loan, ILoan.Status loanStatus) private view returns (bool)
  {
    return _trackedLoan[loan] && loanStatus == ILoan.Status.Repaid;
  }

  function claimReward(address loan) external nonReentrant
  {
    ILoan.LoanMetadata memory loanMetadata = ILoan(loan).getLoanMetadata();
    ILoan.LoanDetails memory loanDetails = ILoan(loan).getLoanDetails();

    require(msg.sender == loanDetails.borrower, "Go borrow");
    require(!hasClaimed(loan), "Claimed");
    require(_isEligibleLoan(loan, loanMetadata.status), "!eligible");


    uint256 unlockDuration = calcUnlockDuration(loanDetails.duration, loanMetadata.timestampStart, loanMetadata.timestampRepaid);

    uint256 reward = _getMintableReward(loan, loanMetadata.timestampRepaid, loanMetadata.timestampRepaid.add(unlockDuration));

    require(IYLD(_YLD).mint(msg.sender, reward));

    _claimed[loan] = true;

    emit Claim(msg.sender, loan, reward);
  }

  /*
   * ((interest - 1) * principalInUSD) / 100;
   * if discounted: ((interest - 0.75) * principalInUSD) / 100;
   */
  function _calcFullReward(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view returns (uint256)
  {
    uint256 maxReward = _currentRewardCap;

    uint256 interestPct = interest.mul(1e18).div(100); // BP (coming from LoanFac) -> 1e18
    uint256 multiplier = interestPct.sub(_rewardCostPct);
    uint256 principalInUSD = IOracle(VersionManager._oracle()).convertToUSD(lendingToken, principal);

    if (IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower))
    {
      multiplier = multiplier.add(0.25 * 1e18);
    }

    multiplier = _calcPercentOf(multiplier, _rebasingFactor);

    if (duration <= 12 days)
    {
      maxReward = _calcPercentOf(maxReward, _shortDurationPct);
    }

    uint256 reward = _calcPercentOf(principalInUSD, multiplier);

    return reward > maxReward ? maxReward : reward;
  }

  function trackLoan(address loan, address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) external override onlyRewarder returns (bool)
  {
    require(!_trackedLoan[loan], "Tracked");

    _fullRewardOf[loan] = _calcFullReward(borrower, lendingToken, principal, interest, duration);

    require(_fullRewardOf[loan] > 0 && _fullRewardOf[loan] < type(uint256).max, "Err setting reward");

    _trackedLoan[loan] = true;

    return true;
  }


  // below in 1e18
  function setRewardCostPct(uint256 newPct) external onlyRewarder
  {
    require(newPct > 0 && newPct < type(uint256).max, "Invalid x%");

    _rewardCostPct = newPct;
  }

  function setShortDurationPct(uint256 newPct) external onlyRewarder
  {
    require(newPct > 0 && newPct < type(uint256).max, "Invalid x%");

    _shortDurationPct = newPct;
  }

  function setLastPrice(uint256 lastPrice) external onlyRewarder
  {
    require(lastPrice > 0 && lastPrice < type(uint256).max, "Invalid $x");

    _lastPrice = lastPrice;
    _rebasingFactor = _basePrice.mul(100 * 1e18).div(lastPrice);
    _currentRewardCap = _calcPercentOf(_baseRewardCap, _rebasingFactor);
  }

  function renounceMinter() external onlyRewarder
  {
    IYLD(_YLD).renounceMinter();
  }
}
