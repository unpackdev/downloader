// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./DiscounterRole.sol";
import "./IYLD.sol";


interface IDiscountManager
{
  event Enroll(address indexed account, uint256 amount);
  event Exit(address indexed account);


  function isDiscounted(address account) external view returns (bool);

  function updateUnlockTime(address lender, address borrower, uint256 duration) external;
}


contract DiscountManager is IDiscountManager, DiscounterRole, ReentrancyGuard
{
  using SafeMath for uint256;


  address private immutable _YLD;

  uint256 private _requiredAmount = 50 * 1e18; // 50 YLD
  bool private _discountsActivated = true;

  mapping(address => uint256) private _balanceOf;
  mapping(address => uint256) private _unlockTimeOf;


  constructor()
  {
    _YLD = address(0xDcB01cc464238396E213a6fDd933E36796eAfF9f);
  }

  function requiredAmount () public view returns (uint256)
  {
    return _requiredAmount;
  }

  function discountsActivated () public view returns (bool)
  {
    return _discountsActivated;
  }

  function balanceOf (address account) public view returns (uint256)
  {
    return _balanceOf[account];
  }

  function unlockTimeOf (address account) public view returns (uint256)
  {
    return _unlockTimeOf[account];
  }

  function isDiscounted(address account) public view override returns (bool)
  {
    return _discountsActivated ? _balanceOf[account] >= _requiredAmount : false;
  }


  function enroll() external nonReentrant
  {
    require(_discountsActivated, "Discounts off");
    require(!isDiscounted(msg.sender), "In");

    require(IERC20(_YLD).transferFrom(msg.sender, address(this), _requiredAmount));

    _balanceOf[msg.sender] = _requiredAmount;
    _unlockTimeOf[msg.sender] = block.timestamp.add(4 weeks);

    emit Enroll(msg.sender, _requiredAmount);
  }

  function exit() external nonReentrant
  {
    require(_balanceOf[msg.sender] >= _requiredAmount, "!in");
    require(block.timestamp > _unlockTimeOf[msg.sender], "Discounting");

    require(IERC20(_YLD).transfer(msg.sender, _balanceOf[msg.sender]));

    _balanceOf[msg.sender] = 0;
    _unlockTimeOf[msg.sender] = 0;

    emit Exit(msg.sender);
  }


  function updateUnlockTime(address lender, address borrower, uint256 duration) external override onlyDiscounter
  {
    uint256 lenderUnlockTime = _unlockTimeOf[lender];
    uint256 borrowerUnlockTime = _unlockTimeOf[borrower];

    if (isDiscounted(lender))
    {
      _unlockTimeOf[lender] = (block.timestamp >= lenderUnlockTime || lenderUnlockTime.sub(block.timestamp) < duration) ? lenderUnlockTime.add(duration.add(4 weeks)) : lenderUnlockTime;
    }
    else if (isDiscounted(borrower))
    {
      _unlockTimeOf[borrower] = (block.timestamp >= borrowerUnlockTime || borrowerUnlockTime.sub(block.timestamp) < duration) ? borrowerUnlockTime.add(duration.add(4 weeks)) : borrowerUnlockTime;
    }
  }

  function activateDiscounts() external onlyDiscounter
  {
    require(!_discountsActivated, "Activated");

    _discountsActivated = true;
  }

  function deactivateDiscounts() external onlyDiscounter
  {
    require(_discountsActivated, "Deactivated");

    _discountsActivated = false;
  }

  function setRequiredAmount(uint256 newAmount) external onlyDiscounter
  {
    require(newAmount > (0.75 * 1e18) && newAmount < type(uint256).max, "Invalid val");

    _requiredAmount = newAmount;
  }
}
