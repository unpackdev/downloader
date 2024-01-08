// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @dev CoverPool contract interface. See {CoverPool}.
 * @author crypto-pumpkin
 */
interface ICoverPool {
  event CoverCreated(address indexed);
  event CoverAdded(address indexed _cover, address _acount, uint256 _amount);
  event NoclaimRedeemDelayUpdated(uint256 _oldDelay, uint256 _newDelay);
  event ClaimEnacted(uint256 _enactedClaimNonce);
  event RiskUpdated(bytes32 _risk, bool _isAddRisk);
  event PoolStatusUpdated(Status _old, Status _new);
  event ExpiryUpdated(uint48 _expiry, string _expiryStr,  Status _status);
  event CollateralUpdated(address indexed _collateral, uint256 _mintRatio,  Status _status);

  enum Status { Null, Active, Disabled }

  struct ExpiryInfo {
    string name;
    Status status;
  }
  struct CollateralInfo {
    uint256 mintRatio;
    Status status;
  }
  struct ClaimDetails {
    uint48 incidentTimestamp;
    uint48 claimEnactedTimestamp;
    uint256 totalPayoutRate;
    bytes32[] payoutRiskList;
    uint256[] payoutRates;
  }

  // state vars
  function name() external view returns (string memory);
  function extendablePool() external view returns (bool);
  function poolStatus() external view returns (Status _status);
  /// @notice only active (true) coverPool allows adding more covers (aka. minting more CLAIM and NOCLAIM tokens)
  function claimNonce() external view returns (uint256);
  function noclaimRedeemDelay() external view returns (uint256);
  function addingRiskWIP() external view returns (bool);
  function addingRiskIndex() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function allCovers(uint256 _index) external view returns (address);
  function expiries(uint256 _index) external view returns (uint48);
  function collaterals(uint256 _index) external view returns (address);
  function riskList(uint256 _index) external view returns (bytes32);
  function deletedRiskList(uint256 _index) external view returns (bytes32);
  function riskMap(bytes32 _risk) external view returns (Status);
  function collateralStatusMap(address _collateral) external view returns (uint256 _mintRatio, Status _status);
  function expiryInfoMap(uint48 _expiry) external view returns (string memory _name, Status _status);
  function coverMap(address _collateral, uint48 _expiry) external view returns (address);

  // extra view
  function getRiskList() external view returns (bytes32[] memory _riskList);
  function getClaimDetails(uint256 _claimNonce) external view returns (ClaimDetails memory);
  function getCoverPoolDetails()
    external view returns (
      address[] memory _collaterals,
      uint48[] memory _expiries,
      bytes32[] memory _riskList,
      bytes32[] memory _deletedRiskList,
      address[] memory _allCovers
    );

  // user action
  /// @notice cover must be deployed first
  function addCover(
    address _collateral,
    uint48 _expiry,
    address _receiver,
    uint256 _colAmountIn,
    uint256 _amountOut,
    bytes calldata _data
  ) external;
  function deployCover(address _collateral, uint48 _expiry) external returns (address _coverAddress);

  // access restriction - claimManager
  function enactClaim(
    bytes32[] calldata _payoutRiskList,
    uint256[] calldata _payoutRates,
    uint48 _incidentTimestamp,
    uint256 _coverPoolNonce
  ) external;

  // CM and dev only
  function setNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external;

  // access restriction - dev
  function addRisk(string calldata _risk) external returns (bool);
  function deleteRisk(string calldata _risk) external;
  function setExpiry(uint48 _expiry, string calldata _expiryName, Status _status) external;
  function setCollateral(address _collateral, uint256 _mintRatio, Status _status) external;
  function setPoolStatus(Status _poolStatus) external;
}