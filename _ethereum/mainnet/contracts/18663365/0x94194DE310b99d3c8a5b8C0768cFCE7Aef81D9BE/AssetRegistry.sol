// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Structs.sol";
import "./AddressRegistry.sol";
import "./ProtocolState.sol";
import "./Ownable.sol";
import "./BaseChecker.sol";
import "./IERC20Metadata.sol";
import {IUniswapV3PoolImmutables} from
  "lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";

import "./IRelayer.sol";

///@title AssetRegistry contract
///@notice Handle logic and state for logging informations regarding the assets
abstract contract AssetRegistry is Ownable, BaseChecker, AddressRegistry, ProtocolState {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice Asset list;
  address[] public assetsList;

  ///@notice last block incentiveFactor was updated, safety measure
  uint128 public lastIncentiveUpdateBlock;
  int128 public incentiveCap;

  ///@notice Map asset address to struct containing info
  mapping(address => AssetInfo) public assetInfo;

  /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/

  error PoolNotValid();
  error AssetSupported(address asset);
  error NotNormalized();
  error NotZero();
  error CoolDownPeriodActive();

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event AssetAdded(address _asset);
  event IncentiveFactorUpdated(address indexed asset, int72 incentiveFactor);
  event TargetConcentrationsUpdated();
  event UniswapPoolUpdated(address indexed asset, address uniswapPool);
  event AssetRemoved(address indexed asset);

  /*//////////////////////////////////////////////////////////////
                                 ADD ASSETS
    //////////////////////////////////////////////////////////////*/

  ///@notice Add assets in batch
  ///@param _assets Array of assets to add
  ///@param _uniswapPools Array of address of uniswap Pool
  ///@dev   only uniswap pool and incentive factor are relevant in assetsInfo, the rest is retrieved
  /// on-chain
  function addAssets(address[] calldata _assets, address[] calldata _uniswapPools)
    external
    onlyOwner
  {
    if (_assets.length != _uniswapPools.length) revert InconsistentLengths();

    for (uint256 i; i < _assets.length; ++i) {
      _addAsset(_assets[i], _uniswapPools[i]);
    }
  }

  function _addAsset(address _asset, address _uniswapPool) private {
    if (assetInfo[_asset].isSupported) revert AssetSupported(_asset);

    assetInfo[_asset].isSupported = true;
    assetInfo[_asset].assetDecimals = IERC20Metadata(_asset).decimals();

    setUniswapPool(_asset, _uniswapPool);

    assetsList.push(_asset);

    emit AssetAdded(_asset);
  }

  ///@notice Removes asset from the protocol whitelist
  ///@param _assetIdx index of the asset in the assets array
  ///@dev only possible if there are no tokens of the asset held by the protocol anymore
  function removeAsset(uint256 _assetIdx) external onlyOwner {
    address asset = assetsList[_assetIdx];
    if (totalAssetAccounting[asset] != 0) revert NotZero();
    if (assetInfo[asset].targetConcentration != 0) revert NotZero();
    delete assetInfo[asset];
    assetsList[_assetIdx] = assetsList[assetsList.length - 1];
    assetsList.pop();
    emit AssetRemoved(asset);
  }
  /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/

  ///@notice Set target concentration for all asset
  ///@param _targetConcentrations Target concentration (1e18 -> 1%)
  ///@dev 1e18 = 1%
  ///@dev targetConcentrations must have same length as assetsList -> can only update all conc at
  // once to enforce normalization
  function setTargetConcentrations(uint72[] calldata _targetConcentrations) external onlyOwner {
    if (_targetConcentrations.length != assetsList.length) revert InconsistentLengths();
    uint72 sum;
    for (uint256 i; i < _targetConcentrations.length; i++) {
      sum += _targetConcentrations[i];
    }
    if (sum > (1e20 + 1e10) || sum < (1e20 - 1e10)) revert NotNormalized();

    for (uint256 i; i < _targetConcentrations.length; i++) {
      assetInfo[assetsList[i]].targetConcentration = _targetConcentrations[i];
    }
    emit TargetConcentrationsUpdated();
  }

  ///@notice Set target concentration for an asset
  ///@param _asset Asset address
  ///@param _incentiveFactor IncentiveFactor (1e18 -> 1%)
  ///@dev 1e18 = 1%, max incentiveCap
  ///@dev Can only be called every 5 blocks, safety measure in case of compromised IncentiveManager
  function setIncentiveFactor(address _asset, int72 _incentiveFactor) external onlyIncentiveManager {
    if (int128(_incentiveFactor) > incentiveCap) revert ValueOutOfBounds();
    if (block.number < uint256(lastIncentiveUpdateBlock) + 5) revert CoolDownPeriodActive();
    lastIncentiveUpdateBlock = uint128(block.number);
    assetInfo[_asset].incentiveFactor = _incentiveFactor;
    emit IncentiveFactorUpdated(_asset, _incentiveFactor);
  }

  ///@notice Set maximum incentive factor
  ///@param _incentiveCap maximum incentive factor
  ///@dev Capped at 1e20 == 100%
  function setIncentiveCap(int128 _incentiveCap) external onlyOwner {
    if (_incentiveCap > 1e20) revert ValueOutOfBounds();
    incentiveCap = _incentiveCap;
  }

  ///@notice Set uniswap pool for an asset
  ///@param _asset Asset address
  ///@param _uniswapPool Uniswap pool address
  function setUniswapPool(address _asset, address _uniswapPool) public onlyOwner {
    if (_uniswapPool == address(0x0)) {
      assetInfo[_asset].uniswapPool = _uniswapPool;
    } else {
      address token0 = IUniswapV3PoolImmutables(_uniswapPool).token0();
      address token1 = IUniswapV3PoolImmutables(_uniswapPool).token1();
      address quoteToken;

      if (token0 == _asset) quoteToken = token1;
      else if (token1 == _asset) quoteToken = token0;
      else revert PoolNotValid();

      assetInfo[_asset].uniswapPool = _uniswapPool;
      assetInfo[_asset].uniswapQuoteToken = quoteToken;
      assetInfo[_asset].quoteTokenDecimals = IERC20Metadata(quoteToken).decimals();
    }
    emit UniswapPoolUpdated(_asset, _uniswapPool);
  }

  /*//////////////////////////////////////////////////////////////
                                GETTER
    //////////////////////////////////////////////////////////////*/

  ///@notice Get isSupported for an asset
  ///@param _assets asset addresses
  ///@return address of first not supported asset or address(0x0) if all supported
  function isAnyNotSupported(address[] memory _assets) public view returns (address) {
    for (uint256 i; i < _assets.length; i++) {
      if (!assetInfo[_assets[i]].isSupported) return _assets[i];
    }
    return address(0x0);
  }

  ///@notice Get isSwapAllowed for an asset array
  ///@param _assets asset addresses
  ///@return address of first not supported asset or address(0x0) if all supported
  function isSwapAllowed(address[] memory _assets) public view returns (address) {
    for (uint256 i; i < _assets.length; i++) {
      if (assetInfo[_assets[i]].incentiveFactor == -100e18) return _assets[i];
    }
    return address(0x0);
  }

  ///@notice Get number of asset decimals
  ///@param _asset Asset address
  ///@return number of decimals
  function getAssetDecimals(address _asset) external view returns (uint8) {
    return assetInfo[_asset].assetDecimals;
  }

  ///@notice Get number of assets in protocol
  function getAssetsListLength() public view returns (uint256) {
    return assetsList.length;
  }

  ///@dev caller has to be whitelisted manager on relayer
  modifier onlyIncentiveManager() {
    if (!IRelayer(RELAYER).isIncentiveManager(msg.sender)) revert Unauthorized();
    _;
  }
}
