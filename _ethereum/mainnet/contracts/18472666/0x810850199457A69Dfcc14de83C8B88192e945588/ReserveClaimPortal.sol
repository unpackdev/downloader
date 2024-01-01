// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract ReserveClaimPortal is Ownable, ReentrancyGuard {
  using Address for address payable;
  using SafeMath for uint;

  IERC20 public token;
  address payable private dev;

  uint public startTimestamp;
  uint public percentageOnTge = 40;
  uint public vestingPeriod = 1 weeks;

  mapping (address => uint) public allocation;
  mapping (address => uint) public tokensReleased;

  event Claimed(
    address indexed _beneficiary,
    uint _tokenAmount
  );

  constructor (
    uint _startTimestamp
  ) {
    startTimestamp = _startTimestamp;
    dev = payable(_msgSender());
  }

  /** PUBLIC FUNCTIONS */

  function getUserInfo(address beneficiary) external view returns (uint tokenAmount, uint claimedAmount, uint vestedAmount) {
    tokenAmount = _getTokenAmount(beneficiary);
    claimedAmount = tokensReleased[beneficiary];
    vestedAmount = _getUserVested(beneficiary, tokenAmount);
  }

  function claim() external nonReentrant {
    require (address(token) != address(0), "Token has not been set yet");
    require (allocation[_msgSender()] > 0, "Can only claim if you have allocation");
    require (block.timestamp >= startTimestamp, "Can only claim if open");

    uint vestedAmount = _getUserVested(_msgSender(), _getTokenAmount(_msgSender()));
    if (vestedAmount > 0) {
      tokensReleased[_msgSender()] += vestedAmount;
      SafeERC20.safeTransfer(token, _msgSender(), vestedAmount);
      emit Claimed(_msgSender(), vestedAmount);
    }
  }

  /** INTERNAL FUNCTIONS */

  function _getTokenAmount(address beneficiary) internal view returns (uint) {
    return allocation[beneficiary];
  }

  function _getUserVested(address beneficiary, uint tokenAmount) internal view returns (uint releasableAmount) {
    if (tokenAmount > 0) {
      uint tokensOnTge = tokenAmount * percentageOnTge / 100;
      uint tokensToVest = tokenAmount - tokensOnTge;
      uint alreadyReleased = tokensReleased[beneficiary];
      if (tokensToVest > 0) {
        uint vestedAmount = _getVestedAmount(tokensToVest, block.timestamp);
        releasableAmount = tokensOnTge + vestedAmount - alreadyReleased;
      } else {
        if (alreadyReleased == 0) {
          releasableAmount = tokensOnTge;
        } else {
          releasableAmount = 0;
        }
      }
    } else {
      releasableAmount = 0;
    }
  }

  function _getVestedAmount(uint _totalAmount, uint _timestamp) internal view returns (uint) {
    if (_timestamp < startTimestamp) {
      return 0;
    } else if (_timestamp > startTimestamp + vestingPeriod) {
      return _totalAmount;
    } else {
      return (_totalAmount * (_timestamp - startTimestamp)) / vestingPeriod;
    }
  }

  /** RESTRICTED FUNCTIONS */

  function setAllocation(address[] calldata beneficiaries, uint[] calldata amounts) external onlyOwner {
    require (beneficiaries.length == amounts.length, "Invalid array length");
    for (uint index = 0; index < beneficiaries.length; index++) {
      address beneficiary = beneficiaries[index];
      uint amount = amounts[index];
      allocation[beneficiary] = amount;
    }
  }

  function setToken(
    address _token
  ) external onlyOwner {
    token = IERC20(_token);
  }

  function withdrawEth() external {
    require (_msgSender() == dev, "Not authorized");
    Address.sendValue(dev, address(this).balance);
  }

  function withdrawTokens(address _token) external {
    require (_msgSender() == dev, "Not authorized");
    SafeERC20.safeTransfer(IERC20(_token), dev, IERC20(_token).balanceOf(address(this)));
  }

  /** FALLBACK */

  receive() external payable {}
}