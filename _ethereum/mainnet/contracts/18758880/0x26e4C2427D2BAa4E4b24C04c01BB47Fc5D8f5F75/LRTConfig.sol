// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./LRTConstants.sol";
import "./ILRTConfig.sol";

import "./AccessControlUpgradeable.sol";

/// @title LRTConfig - LRT Config Contract
/// @notice Handles LRT configuration
contract LRTConfig is ILRTConfig, AccessControlUpgradeable {
    mapping(bytes32 tokenKey => address tokenAddress) public tokenMap;
    mapping(bytes32 contractKey => address contractAddress) public contractMap;
    mapping(address token => bool isSupported) public isSupportedAsset;
    mapping(address token => uint256 amount) public depositLimitByAsset;
    mapping(address token => address strategy) public override assetStrategy;

    address[] public supportedAssetList;

    address public rsETH;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlySupportedAsset(address asset) {
        if (!isSupportedAsset[asset]) {
            revert AssetNotSupported();
        }
        _;
    }

    /// @dev Initializes the contract
    /// @param admin Admin address
    /// @param stETH stETH address
    /// @param ethX ETHX address
    /// @param rsETH_ rsETH address
    function initialize(address admin, address stETH, address ethX, address rsETH_) external initializer {
        UtilLib.checkNonZeroAddress(admin);
        UtilLib.checkNonZeroAddress(rsETH_);

        __AccessControl_init();
        _setToken(LRTConstants.ST_ETH_TOKEN, stETH);
        _setToken(LRTConstants.ETHX_TOKEN, ethX);
        _addNewSupportedAsset(stETH, 100_000 ether);
        _addNewSupportedAsset(ethX, 100_000 ether);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        rsETH = rsETH_;
    }

    /// @dev Adds a new supported asset
    /// @param asset Asset address
    /// @param depositLimit Deposit limit for the asset
    function addNewSupportedAsset(address asset, uint256 depositLimit) external onlyRole(LRTConstants.MANAGER) {
        _addNewSupportedAsset(asset, depositLimit);
    }

    /// @dev private function to add a new supported asset
    /// @param asset Asset address
    /// @param depositLimit Deposit limit for the asset
    function _addNewSupportedAsset(address asset, uint256 depositLimit) private {
        UtilLib.checkNonZeroAddress(asset);
        if (isSupportedAsset[asset]) {
            revert AssetAlreadySupported();
        }
        isSupportedAsset[asset] = true;
        supportedAssetList.push(asset);
        depositLimitByAsset[asset] = depositLimit;
        emit AddedNewSupportedAsset(asset, depositLimit);
    }

    /// @dev Updates the deposit limit for an asset
    /// @param asset Asset address
    /// @param depositLimit New deposit limit
    function updateAssetDepositLimit(
        address asset,
        uint256 depositLimit
    )
        external
        onlyRole(LRTConstants.MANAGER)
        onlySupportedAsset(asset)
    {
        depositLimitByAsset[asset] = depositLimit;
        emit AssetDepositLimitUpdate(asset, depositLimit);
    }

    /// @dev Updates the strategy for an asset
    /// @param asset Asset address
    /// @param strategy New strategy address
    function updateAssetStrategy(
        address asset,
        address strategy
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlySupportedAsset(asset)
    {
        UtilLib.checkNonZeroAddress(strategy);
        if (assetStrategy[asset] == strategy) {
            revert ValueAlreadyInUse();
        }
        assetStrategy[asset] = strategy;
        emit AssetStrategyUpdate(asset, strategy);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/
    function getLSTToken(bytes32 tokenKey) external view override returns (address) {
        return tokenMap[tokenKey];
    }

    function getContract(bytes32 contractKey) external view override returns (address) {
        return contractMap[contractKey];
    }

    function getSupportedAssetList() external view override returns (address[] memory) {
        return supportedAssetList;
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @dev Sets the rsETH contract address. Only callable by the admin
    /// @param rsETH_ rsETH contract address
    function setRSETH(address rsETH_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(rsETH_);
        rsETH = rsETH_;
        emit SetRSETH(rsETH_);
    }

    function setToken(bytes32 tokenKey, address assetAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setToken(tokenKey, assetAddress);
    }

    /// @dev private function to set a token
    /// @param key Token key
    /// @param val Token address
    function _setToken(bytes32 key, address val) private {
        UtilLib.checkNonZeroAddress(val);
        if (tokenMap[key] == val) {
            revert ValueAlreadyInUse();
        }
        tokenMap[key] = val;
        emit SetToken(key, val);
    }

    function setContract(bytes32 contractKey, address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setContract(contractKey, contractAddress);
    }

    /// @dev private function to set a contract
    /// @param key Contract key
    /// @param val Contract address
    function _setContract(bytes32 key, address val) private {
        UtilLib.checkNonZeroAddress(val);
        if (contractMap[key] == val) {
            revert ValueAlreadyInUse();
        }
        contractMap[key] = val;
        emit SetContract(key, val);
    }
}
