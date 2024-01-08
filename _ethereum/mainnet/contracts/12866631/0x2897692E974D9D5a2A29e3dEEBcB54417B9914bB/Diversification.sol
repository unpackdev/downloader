// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./Clones.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";

import "./TokenTimelock.sol";

import "./SafeDecimalMath.sol";
import "./IEthUsdOracle.sol";

// All times are > 1 day so we shouldn't be vulnerable to small manipulations.
// solhint-disable not-rely-on-time

contract Diversification {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address payable;

  struct Partner {
    // If funds have been committed or not.
    bool pending;
    // Partner address to receive tokens to.
    address partner;
    // Price X USD [e18] = 1 Treasury Token
    uint256 price;
    // Allowance in Treasury Tokens [e18]
    uint256 allowance;
    // Deadline to commit
    uint256 deadline;
  }

  /* ============ Events ============ */

  event NewPartner(
    address indexed partner,
    uint256 price,
    uint256 allowance,
    uint256 deadline
  );
  event Commitment(
    address indexed partner,
    address timelock,
    uint256 ethAmount,
    uint256 treasuryAmount
  );
  event Recovered(address to, address tokenAddress, uint256 amount);

  /* ========== CONSTANTS ========== */
  uint256 public constant DELAY_TO_RECOVERY = 31 days;
  uint256 public constant CLIFF_DELAY = 365 days;

  /// WETH address
  IERC20 public immutable weth;

  /// The address of the base token timelock implementation
  address public immutable tokenTimelockImplementation;

  /// The treasury to send proceeds to.
  address public immutable treasury;

  /// Governance (decides who is a partner and allowances).
  address public immutable governance;

  /// Treasury token (what is being diversified from)
  address public immutable treasuryToken;

  /// ETH-USD Oracle
  IEthUsdOracle public immutable ethUsdOracle;

  /// When we started diversification
  uint256 public immutable startTime;

  /* ========== STATE VARIABLES ========== */
  mapping(address => Partner) public partners;

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _tokenTimelockImplementation,
    address _treasury,
    address _governance,
    address _treasuryToken,
    address _weth,
    address _ethUsdOracle
  ) {
    require(_tokenTimelockImplementation != address(0), "Diverse/ZeroAddr");
    require(_treasury != address(0), "Diverse/ZeroAddr");
    require(_governance != address(0), "Diverse/ZeroAddr");
    require(_treasuryToken != address(0), "Diverse/ZeroAddr");
    require(_weth != address(0), "Diverse/ZeroAddr");
    require(_ethUsdOracle != address(0), "Diverse/ZeroAddr");

    tokenTimelockImplementation = _tokenTimelockImplementation;
    treasury = _treasury;
    governance = _governance;
    treasuryToken = _treasuryToken;
    weth = IERC20(_weth);
    ethUsdOracle = IEthUsdOracle(_ethUsdOracle);
    startTime = block.timestamp;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(msg.sender == governance, "Diverse/Governance");
    _;
  }

  modifier onceDelayed {
    require(
      block.timestamp > startTime.add(DELAY_TO_RECOVERY),
      "Diverse/WaitLonger"
    );
    _;
  }

  modifier onlyPendingPartner {
    Partner memory p = partners[msg.sender];
    require(p.pending, "Diverse/OnlyPartners");
    require(p.deadline >= block.timestamp, "Diverse/TooLate");
    _;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /**
   * @notice Add a new partner
   * @param _partner The address that will commit funds, and will retrieve treasury tokens
   * @param _price The USD token price [e18]
   * @param _allowance The maximum amount of treasury tokens [e18]
   */
  function addPartner(
    address _partner,
    uint256 _price,
    uint256 _allowance,
    uint256 _deadline
  ) external onlyGovernance {
    require(_partner != address(0), "Diverse/InvalidPartner");
    // <1$ is assumed to be an unreasonable price.
    require(_price >= SafeDecimalMath.UNIT, "Diverse/InvalidPrice");
    // >10% total Supply is assumed to be unreasonable.
    require(
      _allowance <= IERC20(treasuryToken).totalSupply().div(10),
      "Diverse/TooMuchAllowed"
    );
    require(_deadline > block.timestamp, "Diverse/InvalidDeadline");

    partners[_partner] = Partner({
      pending: true,
      partner: _partner,
      price: _price,
      allowance: _allowance,
      deadline: _deadline
    });

    emit NewPartner(_partner, _price, _allowance, _deadline);
  }

  /* ----- onlyGovernance, onceDelayed ----- */

  /**
   * @notice Provide recovery mechanism for any funds not diversified.
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount)
    external
    onlyGovernance
    onceDelayed
  {
    emit Recovered(treasury, tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(treasury, tokenAmount);
  }

  /**
   * @notice Provide recovery mechanism for any mistakenly sent funds.
   */
  function recoverETH() external onlyGovernance onceDelayed {
    uint256 contractBalance = address(this).balance;

    emit Recovered(treasury, address(0), contractBalance);

    payable(treasury).sendValue(contractBalance);
  }

  /* ----- onlyPartner ---- */

  /**
   * @notice Allows a pending partner to commit eth for an "expected treasury amount"
   * This is a one-use function, if amount is undercommitted
   * (i.e. acquired less than desired) then you can request
   * `governance` to re-add the partner.
   * @param minTreasuryAmount [e18] Amount of treasury token expected
   */
  function commitMinTreasuryWithETH(uint256 minTreasuryAmount)
    external
    payable
    onlyPendingPartner
    returns (address _timelock)
  {
    address _partner = msg.sender;
    Partner memory partner = partners[_partner];

    // Mark as being paid (prevents double commitments)
    partners[_partner].pending = false;

    // Calculate amounts [e18]
    uint256 ethAmount = msg.value;
    uint256 usdAmount = _toUsd(ethAmount);
    uint256 treasuryAmountByValue = usdAmount.divideDecimal(partner.price);
    uint256 treasuryAmount = Math.min(treasuryAmountByValue, partner.allowance);

    require(treasuryAmount >= minTreasuryAmount, "Diverse/ExpectedMore");

    address timelock =
      _deployAndFillTimelock(_partner, treasuryAmount, ethAmount);

    // Send given ETH to treasury
    payable(treasury).sendValue(ethAmount);

    return timelock;
  }

  /**
   * @notice Allows a pending partner to commit weth for an exact amount of treasury.
   * This is a one use function.
   * @param treasuryAmount [e18] Amount of treasury token desired
   * @param maxEthAmount [e18] The maximum amount of WETH to withdraw - you likely want to
   * approve at least this amount.
   */
  function commitExactTreasuryWithWETH(
    uint256 treasuryAmount,
    uint256 maxEthAmount
  ) external onlyPendingPartner returns (address _timelock) {
    address _partner = msg.sender;
    Partner memory partner = partners[_partner];

    // Mark as being paid (prevents double commitments)
    partners[_partner].pending = false;

    require(treasuryAmount <= partner.allowance, "Diverse/Overdesired");

    // Calculate amounts [e18], safe transferFrom will check approval has been given.
    uint256 neededUsd = partner.price.multiplyDecimal(treasuryAmount);
    uint256 neededEth = _toEth(neededUsd);

    require(neededEth <= maxEthAmount, "Diverse/Expensive");

    address timelock =
      _deployAndFillTimelock(_partner, treasuryAmount, neededEth);

    // Send given WETH to treasury
    weth.safeTransferFrom(_partner, treasury, neededEth);

    return timelock;
  }

  function _deployAndFillTimelock(
    address partnerAddress,
    uint256 treasuryAmount,
    uint256 ethAmount
  ) internal returns (address timelock) {
    // Deploy new Token TimeLock Contract
    bytes32 salt = _newSalt(partnerAddress, treasuryAmount);
    timelock = Clones.cloneDeterministic(tokenTimelockImplementation, salt);
    _initTimelock(TokenTimelock(timelock), partnerAddress);

    emit Commitment(partnerAddress, timelock, ethAmount, treasuryAmount);

    // Send treasury tokens to timelock, note that this assumes the contract owns sufficient tokens.
    IERC20(treasuryToken).safeTransfer(timelock, treasuryAmount);

    return timelock;
  }

  /**
   * @dev Converts [e18] ETH amount to a [e18] USD amount using the ETH-USD Oracle
   */
  function _toUsd(uint256 ethAmount) internal view returns (uint256) {
    // [e27]
    uint256 ethInUsd = ethUsdOracle.consult();
    return ethAmount.multiplyDecimalRoundPrecise(ethInUsd);
  }

  /**
   * @dev Converts [e18] USD amount to a [e18] ETH amount using the ETH-USD Oracle
   */
  function _toEth(uint256 usdAmount) internal view returns (uint256) {
    // [e27]
    uint256 ethInUsd = ethUsdOracle.consult();
    return usdAmount.divideDecimalRoundPrecise(ethInUsd);
  }

  /**
   * @dev Initialise the timelock with the CLIFF_DELAY & correct partner
   */
  function _initTimelock(TokenTimelock _timelock, address _partner) internal {
    _timelock.initialize(
      IERC20Upgradeable(treasuryToken),
      _partner,
      block.timestamp.add(CLIFF_DELAY)
    );
  }

  /**
   * @dev Create a basic salt based of amount and partner.
   */
  function _newSalt(address _partner, uint256 _amount)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_partner, _amount));
  }
}
