// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @dev CoverPoolFactory contract interface. See {CoverPoolFactory}.
 * @author crypto-pumpkin
 */
interface ICoverPoolFactory {
  event CoverPoolCreated(address indexed _addr);
  event IntUpdated(string _type, uint256 _old, uint256 _new);
  event AddressUpdated(string _type, address indexed _old, address indexed _new);
  event PausedStatusUpdated(bool _old, bool _new);

  // state vars
  function MAX_REDEEM_DELAY() external view returns (uint256);
  function defaultRedeemDelay() external view returns (uint256);
  // yearlyFeeRate is scaled 1e18
  function yearlyFeeRate() external view returns (uint256);
  function paused() external view returns (bool);
  function responder() external view returns (address);
  function coverPoolImpl() external view returns (address);
  function coverImpl() external view returns (address);
  function coverERC20Impl() external view returns (address);
  function treasury() external view returns (address);
  function claimManager() external view returns (address);
  /// @notice min gas left requirement before continue deployments (when creating new Cover or adding risks to CoverPool)
  function deployGasMin() external view returns (uint256);
  function coverPoolNames(uint256 _index) external view returns (string memory);
  function coverPools(string calldata _coverPoolName) external view returns (address);

  // extra view
  function getCoverPools() external view returns (address[] memory);
  /// @notice return contract address, the contract may not be deployed yet
  function getCoverPoolAddress(string calldata _name) external view returns (address);
  function getCoverAddress(string calldata _coverPoolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  /// @notice _prefix example: "C_CURVE", "C_FUT1", or "NC_"
  function getCovTokenAddress(string calldata _coverPoolName, uint48 _expiry, address _collateral, uint256 _claimNonce, string memory _prefix) external view returns (address);

  // access restriction - owner (dev) & responder
  function setPaused(bool _paused) external;

  // access restriction - owner (dev)
  function setYearlyFeeRate(uint256 _yearlyFeeRate) external;
  function setDefaultRedeemDelay(uint256 _defaultRedeemDelay) external;
  function setResponder(address _responder) external;
  function setDeployGasMin(uint256 _deployGasMin) external;
  /// @dev update Impl will only affect contracts deployed after
  function setCoverPoolImpl(address _newImpl) external;
  function setCoverImpl(address _newImpl) external;
  function setCoverERC20Impl(address _newImpl) external;
  function setTreasury(address _address) external;
  function setClaimManager(address _address) external;
  /**
   * @notice Create a new Cover Pool
   * @param _name name for pool, e.g. Yearn
   * @param _extendablePool open pools allow adding new risk
   * @param _riskList risk risks that are covered in this pool
   * @param _collateral the collateral of the pool
   * @param _mintRatio 18 decimals, in (0, + infinity) the deposit ratio for the collateral the pool, 1.5 means =  1 collateral mints 1.5 CLAIM/NOCLAIM tokens
   * @param _expiry expiration date supported for the pool
   * @param _expiryString MONTH_DATE_YEAR, used to create covToken symbols only
   * 
   * Emits CoverPoolCreated, add a supported coverPool in COVER
   */
  function createCoverPool(
    string calldata _name,
    bool _extendablePool,
    string[] calldata _riskList,
    address _collateral,
    uint256 _mintRatio,
    uint48 _expiry,
    string calldata _expiryString
  ) external returns (address);
}  