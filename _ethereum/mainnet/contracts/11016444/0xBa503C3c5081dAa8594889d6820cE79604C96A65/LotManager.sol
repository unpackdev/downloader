// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IHegicPool.sol";
import "./IHegicLots.sol";

/** LotManager
  *  Should not hold ANY tokens
  *  It should act as a proxy contract from/to HegicPool to v888 lot contract
  *
  */
contract LotManager {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 FEE_PRECISION = 10000;
  uint256 MAX_FEE = 100 * FEE_PRECISION;

  uint256 fee = 10 * FEE_PRECISION;


  address public governance;
  address public pendingGovernance;

  IHegicPool public pool = IHegicPool(0x584bC13c7D411c00c01A62e8019472dE68768430); // TODO Add hardcoded HegicPool address here (needs to be deployed by us)
  IHegicLots public lotsContract = IHegicLots(0x584bC13c7D411c00c01A62e8019472dE68768430); // TODO Add hardcoded lots v888 contract here
  uint256 public lotPrice = 888888 * 1e18;

  mapping(address => address) public hegicTokenSwapper;

  EnumerableSet.AddressSet private protocolTokens;

  // constructor() public {
  constructor(address _pool) public { // TODO REMOVE
    pool = IHegicPool(_pool); // TODO REMOVE
    // lotsContract = IHegicLots(_lotsContract); // TODO REMOVE

    governance = msg.sender;
  }

  function getName() external pure returns (string memory) {
    return "LotManager";
  }

  function isLotManager() external pure returns (bool) {
    return true;
  }


  /** Governance Control
   *  Set fee
   *  Set lotCost
   *
   */
  function setFee(uint256 _fee) external onlyGovernance {
    require(fee <= MAX_FEE, "!fee");
    fee = _fee;
  }

  /** BuyLot
   *  Pools calls stake to invest underlying
   *
   */
  function buyLot() public onlyPool returns (bool) {
    // Check underlying
    IERC20 token = IERC20(pool.getToken());
    // Get allowance
    uint256 allowance = token.allowance(address(pool), address(this));
    // Check if Allowance exceeds lot contract cost
    // Buy lot by transfering tokens
    token.transferFrom(address(pool), address(this), allowance);
    // Allow lotsContract to spend allowance ?
    // token.approve(address(lotsContract), token.balanceOf(address(this)));
    // Buys Lot(s)
    // lotsContract.buyLot();
    // Transfer unused token(underlying) back to the pool
    token.transfer(address(pool), token.balanceOf(address(this)).sub(lotPrice));

    return true;
  }

  function buyETHLot() internal returns (bool) {

  }
  function buyBTCLot() internal returns (bool) {

  }

  /** Underlying getters and checks
   *
   */
  function balaceOfUnderlying() public view returns (uint256 _underlyingBalance) {
    return 100 * 1e18;
  }


  /** SellLot
   *  Pools calls to withdraw stake on investment
   *
   */
  function sellLot() public onlyPool returns (bool) {
    // TODO
    return true;
  }

  function sellETHLot() internal returns (bool) {

  }
  function sellBTCLot() internal returns (bool) {

  }

  function claimRewards() public onlyPool returns (bool) {
    // Claim x888 Lot Rewards in both WETH and WBTC
    // Swaps them to HEGIC
    // Take fee in HEGIC
    // Deposit fee in Pool
    // Transfer zHegic to strategist
    // Transfer HEGIC to pool (do this last)
    return true;
  }

  /** Swap [Not sure if needed, might be better to give rewards in ETH/WBTC ?]
   *  Swaps rewards for more HEGIC
   *
   */
  function swap(address _sell, uint256 _amount) internal {
    address swapper = hegicTokenSwapper[_sell];
    // Check amount of _sell
    // Approve amount to swapper on _sell
    // Swap _sell for token
  }

 // Governance setters
  function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
    pendingGovernance = _pendingGovernance;
  }
  function acceptGovernance() external onlyPendingGovernance {
    governance = msg.sender;
  }

  modifier onlyGovernance {
    require(msg.sender == governance, "Only governance can call this function.");
    _;
  }
  modifier onlyPendingGovernance {
    require(msg.sender == pendingGovernance, "Only pendingGovernance can call this function.");
    _;
  }

 // Pool modifier
  modifier onlyPool {
    require(msg.sender == address(pool), "Only pool can call this function.");
    _;
  }

  /** Util
   *  Governance Dust Collection
   *
   */
  function collectDust(address _token, uint256 _amount) public onlyGovernance {
    // Check if token is not part of the protocol
    require(!protocolTokens.contains(_token), "Token is part of the protocol");
    if (_token == address(0)) {
      payable(governance).transfer(_amount);
    } else {
      IERC20(_token).transfer(governance, _amount);
    }
  }
}
