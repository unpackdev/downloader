// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./Pausable.sol";
import "./ProxyFactory.sol";
import "./VersionManager.sol";

import "./Loan.sol";
import "./Offer.sol";
import "./Request.sol";
import "./LoanFactory.sol";

import "./TokenManager.sol";
import "./FeeBurnManager.sol";

import "./Oracle.sol";


interface IMainFactory
{
  event NewOffer(address indexed lender, address offer);
  event NewRequest(address indexed borrower, address request);
}


contract MainFactory is IMainFactory, Pausable, ReentrancyGuard, VersionManager
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private constant _DECIMALS = 1e18;
  uint256 private constant _MIN_INTEREST = 200; // 2%,
  uint256 private constant _MAX_INTEREST = 1250; // 12.5%
  uint256 private constant _MAX_DURATION = 60 days;
  uint256 private constant _MIN_DURATION = 10 days;

  address[] private _offers;
  address[] private _requests;

  mapping(address => address[]) private _offersOf;
  mapping(address => address[]) private _requestsOf;


  function getOffers() external view returns (address[] memory)
  {
    return _offers;
  }

  function getRequests() external view returns (address[] memory)
  {
    return _requests;
  }

  function getOffersOf(address account) external view returns (address[] memory)
  {
    return _offersOf[account];
  }

  function getRequestsOf(address account) external view returns (address[] memory)
  {
    return _requestsOf[account];
  }


  function createOffer(address lendingToken, uint256 principal, uint256 interest, uint256 duration) external nonReentrant
  {
    Pausable._isNotPaused();
    require(ITokenManager(VersionManager._tokenMgr()).isWhitelisted(lendingToken), "Bad token");

     _isValid(lendingToken, principal, interest, duration);

    uint256 feeOnInterest = IFeeBurnManager(VersionManager._feeBurnMgr()).getFeeOnInterest(msg.sender, lendingToken, principal, interest);

    bytes memory initData = abi.encodeWithSelector(IOffer.__Offer_init.selector, msg.sender, lendingToken, principal, interest, duration, feeOnInterest);

    address offer = ProxyFactory._deployMinimal(VersionManager._offerImplementation(), initData);

    IERC20(lendingToken).safeTransferFrom(msg.sender, offer, principal.add(feeOnInterest));

    _offers.push(offer);
    ILoanFactory(VersionManager._loanFactory()).addLoaner(offer);
    _offersOf[msg.sender].push(offer);

    emit NewOffer(msg.sender, offer);
  }

  function createRequest(address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral) external nonReentrant
  {
    Pausable._isNotPaused();
    _isValid(lendingToken, principal, interest, duration);

    uint256 feeOnPrincipal = IFeeBurnManager(VersionManager._feeBurnMgr()).getFeeOnPrincipal(msg.sender, lendingToken, principal, collateralToken);

    bytes memory initData = abi.encodeWithSelector(IRequest.__Request_init.selector, msg.sender, lendingToken, principal, interest, duration, collateralToken, collateral, feeOnPrincipal);

    address request = ProxyFactory._deployMinimal(VersionManager._requestImplementation(), initData);

    IERC20(collateralToken).safeTransferFrom(msg.sender, request, collateral.add(feeOnPrincipal));

    _requests.push(request);
    ILoanFactory(VersionManager._loanFactory()).addLoaner(request);
    _requestsOf[msg.sender].push(request);

    emit NewRequest(msg.sender, request);
  }


  function _isValid(address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view
  {
    require(_hasValidTerms(lendingToken, principal, interest, duration), "Bad terms");
  }

  function _hasValidTerms(address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view returns (bool)
  {
    uint256 principalInUSD = IOracle(VersionManager._oracle()).convertToUSD(lendingToken, principal);

    // $1000; ~1000 DAI tokens i.e. 1000 * 10^18 && < $50K
    return principalInUSD >= (1000 * _DECIMALS) && principalInUSD <= (50000 * _DECIMALS) && interest >= _MIN_INTEREST && interest <= _MAX_INTEREST && duration >= _MIN_DURATION && duration <= _MAX_DURATION;
  }
}
