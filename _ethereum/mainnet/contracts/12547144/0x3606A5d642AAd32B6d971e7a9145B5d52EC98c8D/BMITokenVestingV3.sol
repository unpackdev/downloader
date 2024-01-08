// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";


contract BMITokenVestingV3 is Initializable, OwnableUpgradeable {
  using MathUpgradeable for uint256;
  using SafeMathUpgradeable for uint256;
  using SafeERC20 for IERC20;

  enum VestingSchedule {
    ANGELROUND,
    SEEDROUND,
    PRIVATEROUND,
    LISTINGS,
    GROWTH,
    OPERATIONAL,
    FOUNDERS,
    DEVELOPERS,
    BUGFINDING,
    VAULT,
    ADVISORSCUSTOMFIRST,
    ADVISORSCUSTOMSECOND
  }

  struct Vesting {
    bool isValid;
    address beneficiary;
    uint256 amount;
    VestingSchedule vestingSchedule;
    uint256 paidAmount;
    bool isCancelable;
  }

  struct LinearVestingSchedule {
    uint256 portionOfTotal;
    uint256 startDate;
    uint256 periodInSeconds;
    uint256 portionPerPeriod;
    uint256 cliffInPeriods;
  }

  uint256 public constant SECONDS_IN_MONTH = 60 * 60 * 24 * 30;
  uint256 public constant PORTION_OF_TOTAL_PRECISION = 10**10;
  uint256 public constant PORTION_PER_PERIOD_PRECISION = 10**10;

  IERC20 public token;
  Vesting[] public vestings;
  uint256 public amountInVestings;
  uint256 public tgeTimestamp;
  mapping(VestingSchedule => LinearVestingSchedule[]) public vestingSchedules;

  event TokenSet(IERC20 token);
  event VestingAdded(uint256 vestingId, address beneficiary);
  event VestingCanceled(uint256 vestingId);
  event VestingWithdraw(uint256 vestingId, uint256 amount);

  function initialize(uint256 _tgeTimestamp) public initializer {
    __Ownable_init();
    tgeTimestamp = _tgeTimestamp;

    initializeVestingSchedules();
  }

  function initializeVestingSchedules() internal {
    _addLinearVestingSchedule(
      VestingSchedule.ANGELROUND,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(4),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.SEEDROUND,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(2),
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH.mul(2)),
        periodInSeconds: SECONDS_IN_MONTH.mul(2),
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(2),
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.SEEDROUND,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(2),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.PRIVATEROUND,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(4),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.LISTINGS,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(100).mul(60),
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.LISTINGS,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(100).mul(40),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.GROWTH,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp.add(SECONDS_IN_MONTH.mul(2)),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(100).mul(5),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.OPERATIONAL,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(100).mul(5),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.FOUNDERS,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(100),
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.FOUNDERS,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(100).mul(99),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(25),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.DEVELOPERS,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(100).mul(4),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.BUGFINDING,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(2),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.BUGFINDING,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(2),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH.mul(3),
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.VAULT,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(100).mul(5),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.ADVISORSCUSTOMFIRST,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(10**10).mul(2643266476),
        startDate: tgeTimestamp.sub(SECONDS_IN_MONTH),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION,
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.ADVISORSCUSTOMFIRST,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(10**10).mul(2199133238),
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(3),
        cliffInPeriods: 0
      })
    );
    _addLinearVestingSchedule(
      VestingSchedule.ADVISORSCUSTOMFIRST,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION.div(10**10).mul(5157600286),
        startDate: tgeTimestamp.add(SECONDS_IN_MONTH.mul(3)),
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(10**10).mul(3512953455),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.ADVISORSCUSTOMSECOND,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH,
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(12).add(1),
        cliffInPeriods: 0
      })
    );
  }

  function addLinearVestingSchedule(VestingSchedule _type, uint256[5] memory _vestingParams) external onlyOwner {

    uint256 portionOfTotal  = _vestingParams[0];
    uint256 startDate       = _vestingParams[1];
    uint256 periodInSeconds = _vestingParams[2];
    uint256 portionPerPeriod= _vestingParams[3];
    uint256 cliffInPeriods  = _vestingParams[4];

    _addLinearVestingSchedule(
      _type,
      LinearVestingSchedule(portionOfTotal, startDate, periodInSeconds, portionPerPeriod, cliffInPeriods)
    );
  }


  function _addLinearVestingSchedule(VestingSchedule _type, LinearVestingSchedule memory _schedule) internal {
    vestingSchedules[_type].push(_schedule);
  }

  function setToken(IERC20 _token) external onlyOwner {
    require(address(token) == address(0), "token is already set");
    token = _token;
    emit TokenSet(token);
  }

  function createPartlyPaidVestingBulk(
    address[] calldata _beneficiary,
    uint256[] calldata _amount,
    VestingSchedule[] calldata _vestingSchedule,
    bool[] calldata _isCancelable,
    uint256[] calldata _paidAmount
  ) external onlyOwner {
    require(
      _beneficiary.length == _amount.length &&
        _beneficiary.length == _vestingSchedule.length &&
        _beneficiary.length == _isCancelable.length &&
        _beneficiary.length == _paidAmount.length,
      "Parameters length mismatch"
    );

    for (uint256 i = 0; i < _beneficiary.length; i++) {
      _createVesting(_beneficiary[i], _amount[i], _vestingSchedule[i], _isCancelable[i], _paidAmount[i]);
    }
  }

  function createVestingBulk(
    address[] calldata _beneficiary,
    uint256[] calldata _amount,
    VestingSchedule[] calldata _vestingSchedule,
    bool[] calldata _isCancelable
  ) external onlyOwner {
    require(
      _beneficiary.length == _amount.length &&
        _beneficiary.length == _vestingSchedule.length &&
        _beneficiary.length == _isCancelable.length,
      "Parameters length mismatch"
    );

    for (uint256 i = 0; i < _beneficiary.length; i++) {
      _createVesting(_beneficiary[i], _amount[i], _vestingSchedule[i], _isCancelable[i], 0);
    }
  }

  function createVesting(
    address _beneficiary,
    uint256 _amount,
    VestingSchedule _vestingSchedule,
    bool _isCancelable
  ) external onlyOwner returns (uint256 vestingId) {
    return _createVesting(_beneficiary, _amount, _vestingSchedule, _isCancelable, 0);
  }

  function _createVesting(
    address _beneficiary,
    uint256 _amount,
    VestingSchedule _vestingSchedule,
    bool _isCancelable,
    uint256 _paidAmount
  ) internal returns (uint256 vestingId) {
    require(_beneficiary != address(0), "Cannot create vesting for zero address");

    uint256 amountToVest = _amount.sub(_paidAmount);
    require(getTokensAvailable() >= amountToVest, "Not enough tokens");
    amountInVestings = amountInVestings.add(amountToVest);

    vestingId = vestings.length;
    vestings.push(
      Vesting({
        isValid: true,
        beneficiary: _beneficiary,
        amount: _amount,
        vestingSchedule: _vestingSchedule,
        paidAmount: _paidAmount,
        isCancelable: _isCancelable
      })
    );

    emit VestingAdded(vestingId, _beneficiary);
  }

  function applyChangesV3() external onlyOwner {

    address[3] memory changeFromBeneficiaries = [
      address(0x7AF83fbc09D40B3e2D496E9405cBe3D5c7070c18),
      address(0xB21576a6cCA2c9b06f367502843B93606e4A17e9),
      address(0xA01FA4AD2872B565E542426d0F132712dfC062a4)
    ];

    address[3] memory changeToBeneficiaries = [
      address(0xb31a7D0fB17336Ad5F1A316F7b25bc7a4CC7efe5),
      address(0xb31a7D0fB17336Ad5F1A316F7b25bc7a4CC7efe5),
      address(0xb31a7D0fB17336Ad5F1A316F7b25bc7a4CC7efe5)
    ];

    uint256[3] memory changeVestingIds = [
      uint256(198),
      uint256(226),
      uint256(158)
    ];

    uint i;
    for (i = 0; i < 3; i++) {
      Vesting storage vesting = getVesting(changeVestingIds[i]);
      require(vesting.isValid, "Vesting is invalid or canceled");
      require(vesting.beneficiary == changeFromBeneficiaries[i], "Vesting beneficiary is incorrect");
      vesting.beneficiary = changeToBeneficiaries[i];
    }

  }

  function cancelVesting(uint256 _vestingId) external onlyOwner {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isCancelable, "Vesting is not cancelable");

    _forceCancelVesting(_vestingId, vesting);
  }

  function _forceCancelVesting(uint256 _vestingId, Vesting storage _vesting) internal {
    require(_vesting.isValid, "Vesting is canceled");
    _vesting.isValid = false;
    uint256 amountReleased = _vesting.amount.sub(_vesting.paidAmount);
    amountInVestings = amountInVestings.sub(amountReleased);

    emit VestingCanceled(_vestingId);
  }

  function withdrawFromVestingBulk(uint256 _offset, uint256 _limit) external {
    uint256 to = (_offset + _limit).min(vestings.length).max(_offset);
    for (uint256 i = _offset; i < to; i++) {
      Vesting storage vesting = getVesting(i);
      if (vesting.isValid) {
        _withdrawFromVesting(vesting, i);
      }
    }
  }

  function withdrawFromVesting(uint256 _vestingId) external {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isValid, "Vesting is canceled");

    _withdrawFromVesting(vesting, _vestingId);
  }

  function _withdrawFromVesting(Vesting storage _vesting, uint256 _vestingId) internal {
    uint256 amountToPay = _getWithdrawableAmount(_vesting);
    if (amountToPay == 0) return;
    _vesting.paidAmount = _vesting.paidAmount.add(amountToPay);
    amountInVestings = amountInVestings.sub(amountToPay);
    token.transfer(_vesting.beneficiary, amountToPay);

    emit VestingWithdraw(_vestingId, amountToPay);
  }

  function getWithdrawableAmount(uint256 _vestingId) external view returns (uint256) {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isValid, "Vesting is canceled");

    return _getWithdrawableAmount(vesting);
  }

  function _getWithdrawableAmount(Vesting storage _vesting) internal view returns (uint256) {
    return calculateAvailableAmount(_vesting).sub(_vesting.paidAmount);
  }

  function calculateAvailableAmount(Vesting storage _vesting) internal view returns (uint256) {
    LinearVestingSchedule[] storage vestingSchedule = vestingSchedules[_vesting.vestingSchedule];
    uint256 amountAvailable = 0;
    for (uint256 i = 0; i < vestingSchedule.length; i++) {
      LinearVestingSchedule storage linearSchedule = vestingSchedule[i];
      if (linearSchedule.startDate > block.timestamp) return amountAvailable;
      uint256 amountThisLinearSchedule = calculateLinearVestingAvailableAmount(linearSchedule, _vesting.amount);
      amountAvailable = amountAvailable.add(amountThisLinearSchedule);
    }
    return amountAvailable;
  }

  function calculateLinearVestingAvailableAmount(LinearVestingSchedule storage _linearVesting, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    uint256 elapsedPeriods = calculateElapsedPeriods(_linearVesting);
    if (elapsedPeriods <= _linearVesting.cliffInPeriods) return 0;
    uint256 amountThisVestingSchedule = _amount.mul(_linearVesting.portionOfTotal).div(PORTION_OF_TOTAL_PRECISION);
    uint256 amountPerPeriod =
      amountThisVestingSchedule.mul(_linearVesting.portionPerPeriod).div(PORTION_PER_PERIOD_PRECISION);
    return amountPerPeriod.mul(elapsedPeriods).min(amountThisVestingSchedule);
  }

  function calculateElapsedPeriods(LinearVestingSchedule storage _linearVesting) private view returns (uint256) {
    return block.timestamp.sub(_linearVesting.startDate).div(_linearVesting.periodInSeconds);
  }

  function getVesting(uint256 _vestingId) internal view returns (Vesting storage) {
    require(_vestingId < vestings.length, "No vesting with such id");
    return vestings[_vestingId];
  }

  function withdrawExcessiveTokens() external onlyOwner {
    token.transfer(owner(), getTokensAvailable());
  }

  function getTokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this)).sub(amountInVestings);
  }

  function getVestingById(uint256 _vestingId)
    public
    view
    returns (
      bool isValid,
      address beneficiary,
      uint256 amount,
      VestingSchedule vestingSchedule,
      uint256 paidAmount,
      bool isCancelable
    )
  {
    Vesting storage vesting = getVesting(_vestingId);
    isValid = vesting.isValid;
    beneficiary = vesting.beneficiary;
    amount = vesting.amount;
    vestingSchedule = vesting.vestingSchedule;
    paidAmount = vesting.paidAmount;
    isCancelable = vesting.isCancelable;
  }

  function getVestingsCount() public view returns (uint256 _vestingsCount) {
    return vestings.length;
  }
}
