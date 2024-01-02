// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./LRTConstants.sol";

import "./LRTConfigRoleChecker.sol";
import "./IRSETH.sol";
import "./ILRTOracle.sol";
import "./INodeDelegator.sol";
import "./ILRTDepositPool.sol";

import "./IERC20.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/// @title LRTDepositPool - Deposit Pool Contract for LSTs
/// @notice Handles LST asset deposits
contract LRTDepositPool is ILRTDepositPool, LRTConfigRoleChecker, PausableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public maxNodeDelegatorLimit;
    uint256 public minAmountToDeposit;

    mapping(address => uint256) public isNodeDelegator; // 0: not a node delegator, 1: is a node delegator
    address[] public nodeDelegatorQueue;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param lrtConfigAddr LRT config address
    function initialize(address lrtConfigAddr) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);
        __Pausable_init();
        __ReentrancyGuard_init();
        maxNodeDelegatorLimit = 10;
        lrtConfig = ILRTConfig(lrtConfigAddr);
        emit UpdatedLRTConfig(lrtConfigAddr);
    }

    /*//////////////////////////////////////////////////////////////
                            view functions
    //////////////////////////////////////////////////////////////*/

    /// @notice gets the total asset present in protocol
    /// @param asset Asset address
    /// @return totalAssetDeposit total asset present in protocol
    function getTotalAssetDeposits(address asset) public view override returns (uint256 totalAssetDeposit) {
        (uint256 assetLyingInDepositPool, uint256 assetLyingInNDCs, uint256 assetStakedInEigenLayer) =
            getAssetDistributionData(asset);
        return (assetLyingInDepositPool + assetLyingInNDCs + assetStakedInEigenLayer);
    }

    /// @notice gets the current limit of asset deposit
    /// @param asset Asset address
    /// @return currentLimit Current limit of asset deposit
    function getAssetCurrentLimit(address asset) public view override returns (uint256) {
        return lrtConfig.depositLimitByAsset(asset) - getTotalAssetDeposits(asset);
    }

    /// @dev get node delegator queue
    /// @return nodeDelegatorQueue Array of node delegator contract addresses
    function getNodeDelegatorQueue() external view override returns (address[] memory) {
        return nodeDelegatorQueue;
    }

    /// @dev provides asset amount distribution data among depositPool, NDCs and eigenLayer
    /// @param asset the asset to get the total amount of
    /// @return assetLyingInDepositPool asset amount lying in this LRTDepositPool contract
    /// @return assetLyingInNDCs asset amount sum lying in all NDC contract
    /// @return assetStakedInEigenLayer asset amount deposited in eigen layer strategies through all NDCs
    function getAssetDistributionData(address asset)
        public
        view
        override
        onlySupportedAsset(asset)
        returns (uint256 assetLyingInDepositPool, uint256 assetLyingInNDCs, uint256 assetStakedInEigenLayer)
    {
        assetLyingInDepositPool = IERC20(asset).balanceOf(address(this));

        uint256 ndcsCount = nodeDelegatorQueue.length;
        for (uint256 i; i < ndcsCount;) {
            assetLyingInNDCs += IERC20(asset).balanceOf(nodeDelegatorQueue[i]);
            assetStakedInEigenLayer += INodeDelegator(nodeDelegatorQueue[i]).getAssetBalance(asset);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice View amount of rsETH to mint for given asset amount
    /// @param asset Asset address
    /// @param amount Asset amount
    /// @return rsethAmountToMint Amount of rseth to mint
    function getRsETHAmountToMint(
        address asset,
        uint256 amount
    )
        public
        view
        override
        returns (uint256 rsethAmountToMint)
    {
        // setup oracle contract
        address lrtOracleAddress = lrtConfig.getContract(LRTConstants.LRT_ORACLE);
        ILRTOracle lrtOracle = ILRTOracle(lrtOracleAddress);

        // calculate rseth amount to mint based on asset amount and asset exchange rate
        rsethAmountToMint = (amount * lrtOracle.getAssetPrice(asset)) / lrtOracle.rsETHPrice();
    }

    /*//////////////////////////////////////////////////////////////
                            write functions
    //////////////////////////////////////////////////////////////*/

    /// @notice helps user stake LST to the protocol
    /// @param asset LST asset address to stake
    /// @param depositAmount LST asset amount to stake
    /// @param minRSETHAmountToReceive Minimum amount of rseth to receive
    function depositAsset(
        address asset,
        uint256 depositAmount,
        uint256 minRSETHAmountToReceive,
        string calldata referralId
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedAsset(asset)
    {
        // checks
        if (depositAmount == 0 || depositAmount < minAmountToDeposit) {
            revert InvalidAmountToDeposit();
        }

        if (depositAmount > getAssetCurrentLimit(asset)) {
            revert MaximumDepositLimitReached();
        }

        if (!IERC20(asset).transferFrom(msg.sender, address(this), depositAmount)) {
            revert TokenTransferFailed();
        }

        // interactions
        uint256 rsethAmountMinted = _mintRsETH(asset, depositAmount);

        if (rsethAmountMinted < minRSETHAmountToReceive) {
            revert MinimumAmountToReceiveNotMet();
        }

        emit AssetDeposit(msg.sender, asset, depositAmount, rsethAmountMinted, referralId);
    }

    /// @dev private function to mint rseth. It calculates rseth amount to mint based on asset amount and asset exchange
    /// rates from oracle
    /// @param _asset Asset address
    /// @param _amount Asset amount to mint rseth
    /// @return rsethAmountToMint Amount of rseth minted
    function _mintRsETH(address _asset, uint256 _amount) private returns (uint256 rsethAmountToMint) {
        (rsethAmountToMint) = getRsETHAmountToMint(_asset, _amount);

        address rsethToken = lrtConfig.rsETH();
        // mint rseth for user
        IRSETH(rsethToken).mint(msg.sender, rsethAmountToMint);
    }

    /// @notice add new node delegator contract addresses
    /// @dev only callable by LRT admin
    /// @param nodeDelegatorContracts Array of NodeDelegator contract addresses
    function addNodeDelegatorContractToQueue(address[] calldata nodeDelegatorContracts) external onlyLRTAdmin {
        uint256 length = nodeDelegatorContracts.length;
        if (nodeDelegatorQueue.length + length > maxNodeDelegatorLimit) {
            revert MaximumNodeDelegatorLimitReached();
        }

        for (uint256 i; i < length;) {
            UtilLib.checkNonZeroAddress(nodeDelegatorContracts[i]);

            // check if node delegator contract is already added and add it if not
            if (isNodeDelegator[nodeDelegatorContracts[i]] == 0) {
                nodeDelegatorQueue.push(nodeDelegatorContracts[i]);
            }

            isNodeDelegator[nodeDelegatorContracts[i]] = 1;

            unchecked {
                ++i;
            }
        }

        emit NodeDelegatorAddedinQueue(nodeDelegatorContracts);
    }

    /// @notice transfers asset lying in this DepositPool to node delegator contract
    /// @dev only callable by LRT manager
    /// @param ndcIndex Index of NodeDelegator contract address in nodeDelegatorQueue
    /// @param asset Asset address
    /// @param amount Asset amount to transfer
    function transferAssetToNodeDelegator(
        uint256 ndcIndex,
        address asset,
        uint256 amount
    )
        external
        nonReentrant
        onlyLRTManager
        onlySupportedAsset(asset)
    {
        address nodeDelegator = nodeDelegatorQueue[ndcIndex];
        if (!IERC20(asset).transfer(nodeDelegator, amount)) {
            revert TokenTransferFailed();
        }
    }

    /// @notice update max node delegator count
    /// @dev only callable by LRT admin
    /// @param maxNodeDelegatorLimit_ Maximum count of node delegator
    function updateMaxNodeDelegatorLimit(uint256 maxNodeDelegatorLimit_) external onlyLRTAdmin {
        if (maxNodeDelegatorLimit_ < nodeDelegatorQueue.length) {
            revert InvalidMaximumNodeDelegatorLimit();
        }

        maxNodeDelegatorLimit = maxNodeDelegatorLimit_;
        emit MaxNodeDelegatorLimitUpdated(maxNodeDelegatorLimit);
    }

    /// @notice update min amount to deposit
    /// @dev only callable by LRT admin
    /// @param minAmountToDeposit_ Minimum amount to deposit
    function setMinAmountToDeposit(uint256 minAmountToDeposit_) external onlyLRTAdmin {
        minAmountToDeposit = minAmountToDeposit_;
        emit MinAmountToDepositUpdated(minAmountToDeposit_);
    }

    /// @dev Triggers stopped state. Contract must not be paused.
    function pause() external onlyLRTManager {
        _pause();
    }

    /// @dev Returns to normal state. Contract must be paused
    function unpause() external onlyLRTAdmin {
        _unpause();
    }
}
