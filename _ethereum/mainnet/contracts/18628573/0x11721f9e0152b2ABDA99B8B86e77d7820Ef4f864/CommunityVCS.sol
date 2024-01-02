// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./VaultControllerStrategy.sol";
import "./ICommunityVault.sol";

/**
 * @title Community Vault Controller Strategy
 * @notice Implemented strategy for managing multiple Chainlink community staking vaults
 */
contract CommunityVCS is VaultControllerStrategy {
    uint128 public vaultDeploymentThreshold;
    uint128 public vaultDeploymentAmount;

    event SetVaultDeploymentParams(uint128 vaultDeploymentThreshold, uint128 vaultDeploymentAmount);

    error VaultsAboveThreshold();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice initializes contract
     * @param _token address of LINK token
     * @param _stakingPool address of the staking pool that controls this strategy
     * @param _stakeController address of Chainlink staking contract
     * @param _vaultImplementation address of the implementation contract to use when deploying new vaults
     * @param _fees list of fees to be paid on rewards
     * @param _maxDepositSizeBP basis point amount of the remaing deposit room in the Chainlink staking contract
     * that can be deposited at once
     * @param _vaultDeploymentThreshold the min number of non-full vaults before a new batch is deployed
     * @param _vaultDeploymentAmount amount of vaults to deploy when threshold is met
     **/
    function initialize(
        address _token,
        address _stakingPool,
        address _stakeController,
        address _vaultImplementation,
        Fee[] memory _fees,
        uint256 _maxDepositSizeBP,
        uint128 _vaultDeploymentThreshold,
        uint128 _vaultDeploymentAmount
    ) public initializer {
        __VaultControllerStrategy_init(
            _token,
            _stakingPool,
            _stakeController,
            _vaultImplementation,
            _fees,
            _maxDepositSizeBP
        );
        vaultDeploymentThreshold = _vaultDeploymentThreshold;
        vaultDeploymentAmount = _vaultDeploymentAmount;
        _deployVaults(_vaultDeploymentAmount);
    }

    /**
     * @notice claims Chanlink staking rewards from vaults
     * @param _startIndex index of first vault to claim from
     * @param _numVaults number of vaults to claim from starting at _startIndex
     * @param _minRewards min amount of rewards required to claim
     */
    function claimRewards(
        uint256 _startIndex,
        uint256 _numVaults,
        uint256 _minRewards
    ) external {
        address receiver = address(this);
        for (uint256 i = _startIndex; i < _startIndex + _numVaults; ++i) {
            ICommunityVault(address(vaults[i])).claimRewards(_minRewards, receiver);
        }
    }

    /**
     * @notice returns the maximum that can be deposited into this strategy
     * @return maximum deposits
     */
    function getMaxDeposits() public view virtual override returns (uint256) {
        return stakeController.getMerkleRoot() == bytes32(0) ? super.getMaxDeposits() : 0;
    }

    /**
     * @notice returns whether a new batch of vaults should be deployed
     * @dev used by chainlink keepers
     */
    function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
        return ((vaults.length - 1 - indexOfLastFullVault) < vaultDeploymentThreshold, bytes(""));
    }

    /**
     * @notice deploys a new batch of vaults
     * @dev will revert if the number of non-full vaults is not less than vaultDeploymentThreshold
     * @dev used by chainlink keepers
     */
    function performUpkeep(bytes calldata) external {
        if ((vaults.length - 1 - indexOfLastFullVault) >= vaultDeploymentThreshold) revert VaultsAboveThreshold();
        _deployVaults(vaultDeploymentAmount);
    }

    /**
     * @notice deploys a new batch of vaults
     * @param _numVaults number of vaults to deploy
     */
    function addVaults(uint256 _numVaults) external onlyOwner {
        _deployVaults(_numVaults);
    }

    /**
     * @notice sets the vault deployment parameters
     * @param _vaultDeploymentThreshold the min number of non-full vaults before a new batch is deployed
     * @param _vaultDeploymentAmount amount of vaults to deploy when threshold is met
     */
    function setVaultDeploymentParams(uint128 _vaultDeploymentThreshold, uint128 _vaultDeploymentAmount) external onlyOwner {
        vaultDeploymentThreshold = _vaultDeploymentThreshold;
        vaultDeploymentAmount = _vaultDeploymentAmount;
        emit SetVaultDeploymentParams(_vaultDeploymentThreshold, _vaultDeploymentAmount);
    }

    /**
     * @notice deploys new vaults
     * @param _numVaults number of vaults to deploy
     */
    function _deployVaults(uint256 _numVaults) internal {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address,address)",
            address(token),
            address(this),
            address(stakeController),
            stakeController.getRewardVault()
        );
        for (uint256 i = 0; i < _numVaults; i++) {
            _deployVault(data);
        }
    }
}
