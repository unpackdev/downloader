// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./InitializableAdminUpgradeabilityProxy.sol";
import "./Create2.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./StringHelper.sol";
import "./ICover.sol";
import "./IOwnable.sol";
import "./IClaimManagement.sol";
import "./ICoverPool.sol";
import "./ICoverPoolCallee.sol";
import "./ICoverPoolFactory.sol";

/**
 * @title CoverPool contract, manages risks, and covers for pool, handles adding coverage for user
 * @author crypto-pumpkin
 * CoverPool types:
 * - extendable pool: allowed to add and delete risk
 * - non-extendable pool: NOT allowed to add risk, but allowed to delete risk
 */
contract CoverPool is ICoverPool, Initializable, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

  bytes4 private constant COVER_INIT_SIGNITURE = bytes4(keccak256("initialize(string,uint48,address,uint256,uint256)"));
  bytes32 public constant CALLBACK_SUCCESS = keccak256("ICoverPoolCallee.onFlashMint");

  string public override name;
  bool public override extendablePool;
  Status public override poolStatus; // only Active coverPool status can addCover (aka. minting more covTokens)
  bool public override addingRiskWIP;
  uint256 public override addingRiskIndex; // index of the active cover array to continue adding risk
  uint256 public override claimNonce; // nonce of for the coverPool's accepted claims
  uint256 public override noclaimRedeemDelay; // delay for redeem with only noclaim tokens for expired cover with no accpeted claim

  ClaimDetails[] private claimDetails; // [claimNonce] => accepted ClaimDetails
  address[] public override activeCovers; // reset once claim accepted, may contain expired covers, used mostly for adding new risk to pool for faster deployment
  address[] public override allCovers; // all covers ever created
  uint48[] public override expiries; // all expiries ever added
  address[] public override collaterals; // all collaterals ever added
  bytes32[] public override riskList; // list of active risks in cover pool
  bytes32[] public override deletedRiskList;
  // riskMap is only used to check is a risk is already added or deleted
  mapping(bytes32 => Status) public override riskMap;
  mapping(address => CollateralInfo) public override collateralStatusMap;
  mapping(uint48 => ExpiryInfo) public override expiryInfoMap;
  // collateral => timestamp => coverAddress, most recent (might be expired) cover created for the collateral and timestamp combination
  mapping(address => mapping(uint48 => address)) public override coverMap;

  modifier onlyDev() {
    require(msg.sender == _dev(), "CP: caller not dev");
    _;
  }

  modifier onlyNotAddingRiskWIP() {
    require(!addingRiskWIP, "CP: adding risk WIP");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _coverPoolName,
    bool _extendablePool,
    string[] calldata _riskList,
    address _collateral,
    uint256 _mintRatio,
    uint48 _expiry,
    string calldata _expiryString
  ) external initializer {
    require(_collateral != address(0), "CP: collateral cannot be 0");
    initializeOwner();
    name = _coverPoolName;
    extendablePool = _extendablePool;
    _setCollateral(_collateral, _mintRatio, Status.Active);
    _setExpiry(_expiry, _expiryString, Status.Active);

    for (uint256 j = 0; j < _riskList.length; j++) {
      bytes32 risk = StringHelper.stringToBytes32(_riskList[j]);
      require(riskMap[risk] == Status.Null, "CP: duplicated risks");
      riskList.push(risk);
      riskMap[risk] = Status.Active;
      emit RiskUpdated(risk, true);
    }

    noclaimRedeemDelay = _factory().defaultRedeemDelay(); // Claim manager can set it 10 days when claim filed
    emit NoclaimRedeemDelayUpdated(0, noclaimRedeemDelay);
    poolStatus = Status.Active;
    deployCover(_collateral, _expiry);
  }

  /**
   * @notice add coverage (with expiry) for sender, collateral is transferred here to optimize collateral approve tx for users
   * @param _collateral, collateral for cover, must be supported and active
   * @param _expiry, expiry for cover, must be supported and active
   * @param _receiver, receiver of the covTokens, must have _colAmountIn
   * @param _colAmountIn, the amount of collateral to transfer from msg.sender (must approve pool to transfer), should be > _amountOut for inflationary tokens
   * @param _amountOut, the amount of collateral to use to mint covTokens, equals to _colAmountIn if collateral is standard ERC20
   * @param _data, the data to use to call msg.sender, set to '0x' if normal mint
   */
  function addCover(
    address _collateral,
    uint48 _expiry,
    address _receiver,
    uint256 _colAmountIn,
    uint256 _amountOut,
    bytes calldata _data
  ) external override nonReentrant onlyNotAddingRiskWIP
  {
    require(!_factory().paused(), "CP: paused");
    require(poolStatus == Status.Active, "CP: pool not active");
    require(_colAmountIn > 0, "CP: amount <= 0");
    require(collateralStatusMap[_collateral].status == Status.Active, "CP: invalid collateral");
    require(block.timestamp < _expiry && expiryInfoMap[_expiry].status == Status.Active, "CP: invalid expiry");
    address coverAddr = coverMap[_collateral][_expiry];
    require(coverAddr != address(0), "CP: cover not deployed yet");
    ICover cover = ICover(coverAddr);

    // support flash mint
    cover.mint(_amountOut, _receiver);
    if (_data.length > 0) {
      require(
        ICoverPoolCallee(_receiver).onFlashMint(msg.sender, _collateral, _colAmountIn, _amountOut, _data) == CALLBACK_SUCCESS,
        "CP: Callback failed"
      );
    }

    IERC20 collateral = IERC20(_collateral);
    uint256 coverBalanceBefore = collateral.balanceOf(coverAddr);
    collateral.safeTransferFrom(_receiver, coverAddr, _colAmountIn);
    uint256 received = collateral.balanceOf(coverAddr) - coverBalanceBefore;
    require(received >= _amountOut, "CP: collateral transfer failed");

    emit CoverAdded(coverAddr, _receiver, _amountOut);
  }

  /**
   * @notice add risk to pool, true if add complete; false if incomplete.
   * - previously deleted risk not allowed.
   * - Can be called as much as needed till addingRiskWIP is false
   */
  function addRisk(string calldata _risk) external override onlyDev returns (bool) {
    require(extendablePool, "CP: not extendable pool");
    bytes32 risk = StringHelper.stringToBytes32(_risk);
    require(riskMap[risk] != Status.Disabled, "CP: deleted risk not allowed");

    if (riskMap[risk] == Status.Null) {
      // first time adding the risk, make sure no other risk adding in progress
      require(!addingRiskWIP, "CP: adding risk WIP");
      addingRiskWIP = true;
      riskMap[risk] = Status.Active;
      riskList.push(risk);
    }

    // update all active covers with new risk by deploying claim and new future covTokens for each cover contract
    address[] memory activeCoversCopy = activeCovers;

    uint256 startGas = gasleft();
    for (uint256 i = addingRiskIndex; i < activeCoversCopy.length; i++) {
      addingRiskIndex = i;
      // ensure enough gas left to avoid revert all the previous work
      if (startGas < _factory().deployGasMin()) return false;
      // below call deploys two covToken contracts, if cover already added, call will do nothing
      ICover(activeCoversCopy[i]).addRisk(risk);
      startGas = gasleft();
    }

    addingRiskWIP = false;
    addingRiskIndex = 0;
    emit RiskUpdated(risk, true);
    return true;
  }

  /// @notice delete risk from pool
  function deleteRisk(string calldata _risk) external override onlyDev onlyNotAddingRiskWIP {
    bytes32 risk = StringHelper.stringToBytes32(_risk);
    require(riskMap[risk] == Status.Active, "CP: not active risk");
    bytes32[] memory riskListCopy = riskList; // save gas
    uint256 len = riskListCopy.length;
    require(len > 1, "CP: only 1 risk left");
    IClaimManagement claimManager = IClaimManagement(_factory().claimManager());
    require(!claimManager.hasPendingClaim(address(this), claimNonce), "CP: pending claim");


    for (uint256 i = 0; i < len; i++) {
      if (risk == riskListCopy[i]) {
        riskMap[risk] = Status.Disabled;
        deletedRiskList.push(risk);
        riskList[i] = riskListCopy[len - 1];
        riskList.pop();
        emit RiskUpdated(risk, false);
        break;
      }
    }
  }

  /// @notice update status or add new expiry
  function setExpiry(uint48 _expiry, string calldata _expiryStr, Status _status) public override onlyDev {
    _setExpiry(_expiry, _expiryStr, _status);
  }

  /// @notice update status or add new collateral
  function setCollateral(address _collateral, uint256 _mintRatio, Status _status) public override onlyDev {
    _setCollateral(_collateral, _mintRatio, _status);
  }

  // update status of coverPool, if disabled, will pause new cover creation
  function setPoolStatus(Status _poolStatus) external override onlyDev {
    emit PoolStatusUpdated(poolStatus, _poolStatus);
    poolStatus = _poolStatus;
  }

  function setNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external override {
    ICoverPoolFactory factory = _factory();
    require(msg.sender == _dev() || msg.sender == factory.claimManager(), "CP: caller not gov/claimManager");
    require(_noclaimRedeemDelay >= factory.defaultRedeemDelay(), "CP: < default delay");
    require(_noclaimRedeemDelay <= factory.MAX_REDEEM_DELAY(), "CP: > max delay");
    if (_noclaimRedeemDelay != noclaimRedeemDelay) {
      emit NoclaimRedeemDelayUpdated(noclaimRedeemDelay, _noclaimRedeemDelay);
      noclaimRedeemDelay = _noclaimRedeemDelay;
    }
  }

  /**
   * @dev enact accepted claim, all covers are to be paid out
   *  - increment claimNonce
   *  - delete activeCovers list
   * Emit ClaimEnacted
   */
  function enactClaim(
    bytes32[] calldata _payoutRiskList,
    uint256[] calldata _payoutRates,
    uint48 _incidentTimestamp,
    uint256 _coverPoolNonce
  ) external override {
    require(msg.sender == _factory().claimManager(), "CP: caller not claimManager");
    require(_coverPoolNonce == claimNonce, "CP: nonces do not match");
    require(_payoutRiskList.length == _payoutRates.length, "CP: arrays length don't match");

    uint256 totalPayoutRate;
    for (uint256 i = 0; i < _payoutRiskList.length; i++) {
      require(riskMap[_payoutRiskList[i]] == Status.Active, "CP: has disabled risk");
      totalPayoutRate = totalPayoutRate + _payoutRates[i];
    }
    require(totalPayoutRate <= 1 ether && totalPayoutRate > 0, "CP: payout % not in (0%, 100%]");

    claimNonce = claimNonce + 1;
    delete activeCovers;
    claimDetails.push(ClaimDetails(
      _incidentTimestamp,
      uint48(block.timestamp),
      totalPayoutRate,
      _payoutRiskList,
      _payoutRates
    ));
    emit ClaimEnacted(_coverPoolNonce);
  }

  function getCoverPoolDetails() external view override
    returns (
      address[] memory _collaterals,
      uint48[] memory _expiries,
      bytes32[] memory _riskList,
      bytes32[] memory _deletedRiskList,
      address[] memory _allCovers)
  {
    return (collaterals, expiries, riskList, deletedRiskList, allCovers);
  }

  function getRiskList() external view override returns (bytes32[] memory) {
    return riskList;
  }

  function getClaimDetails(uint256 _nonce) external view override returns (ClaimDetails memory) {
    return claimDetails[_nonce];
  }

  /**
   * @notice deploy Cover contracts with all necessary covTokens
   * Will only deploy or complete existing deployment if necessary.
   * Safe to call by anyone, make it convinient operationally to deploy a new cover for pool
   */
  function deployCover(address _collateral, uint48 _expiry) public override returns (address addr) {
    addr = coverMap[_collateral][_expiry];

    // Deploy new cover contract if not exist or if claim accepted
    if (addr == address(0) || ICover(addr).claimNonce() < claimNonce) {
      require(collateralStatusMap[_collateral].status == Status.Active, "CP: invalid collateral");
      require(block.timestamp < _expiry && expiryInfoMap[_expiry].status == Status.Active, "CP: invalid expiry");

      string memory coverName = _getCoverName(_expiry, IERC20(_collateral).symbol());
      bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
      bytes32 salt = keccak256(abi.encodePacked(name, _expiry, _collateral, claimNonce));
      addr = Create2.deploy(0, salt, bytecode);
      bytes memory initData = abi.encodeWithSelector(COVER_INIT_SIGNITURE, coverName, _expiry, _collateral, collateralStatusMap[_collateral].mintRatio, claimNonce);
      address coverImpl = _factory().coverImpl();
      InitializableAdminUpgradeabilityProxy(payable(addr)).initialize(
        coverImpl,
        IOwnable(owner()).owner(),
        initData
      );
      activeCovers.push(addr);
      allCovers.push(addr);
      coverMap[_collateral][_expiry] = addr;
      emit CoverCreated(addr);
    } else if (!ICover(addr).deployComplete()) {
      ICover(addr).deploy();
    }
  }

  function _factory() private view returns (ICoverPoolFactory) {
    return ICoverPoolFactory(owner());
  }

  // the owner of this contract is CoverPoolFactory, whose owner is dev
  function _dev() private view returns (address) {
    return IOwnable(owner()).owner();
  }

  function _setExpiry(uint48 _expiry, string calldata _expiryStr, Status _status) private {
    require(block.timestamp < _expiry, "CP: expiry in the past");
    require(_status != Status.Null, "CP: status is null");

    if (expiryInfoMap[_expiry].status == Status.Null) {
      expiries.push(_expiry);
    }
    expiryInfoMap[_expiry] = ExpiryInfo(_expiryStr, _status);
    emit ExpiryUpdated(_expiry, _expiryStr, _status);
  }

  function _setCollateral(address _collateral, uint256 _mintRatio, Status _status) private {
    require(_collateral != address(0), "CP: address cannot be 0");
    require(_status != Status.Null, "CP: status is null");

    if (collateralStatusMap[_collateral].status == Status.Null) {
      collaterals.push(_collateral);
    }
    collateralStatusMap[_collateral] = CollateralInfo(_mintRatio, _status);
    emit CollateralUpdated(_collateral, _mintRatio,  _status);
  }

  // generate the cover name. Example: 3POOL_0_DAI_12_31_21
  function _getCoverName(uint48 _expiry, string memory _collateralSymbol)
   private view returns (string memory)
  {
    require(bytes(_collateralSymbol).length > 0, "CP: empty collateral symbol");
    return string(abi.encodePacked(
      name, "_",
      StringHelper.uintToString(claimNonce), "_",
      _collateralSymbol, "_",
      expiryInfoMap[_expiry].name
    ));
  }
}
