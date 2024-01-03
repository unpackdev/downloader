// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IController.sol";
import "./IVault.sol";

/**
 * @notice Controller for all vaults.
 *
 * Controller maintains the list of vaults, manages vaults' shared
 * properties, e.g. governance and treasury address, and performs
 * reward allocation to vaults.
 */
contract Controller is IController, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event RewardTokenUpdated(address indexed oldRewardToken, address indexed newRewardToken);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event VaultUpdated(uint256 indexed vaultId, address indexed oldVault, address indexed newVault, uint256 numVaults);
    event RewardAdded(uint256 indexed vaultId, address indexed rewardToken, uint256 rewardAmount);

    address public override governance;
    address public override rewardToken;
    address public override treasury;
    uint256 public override numVaults;
    // Vault ID ==> Vault
    mapping(uint256 => address) public override vaults;

    uint256[50] private __gap;

    /**
     * @dev Initializes the Controller contract. Can be invoked only once.
     * @param _rewardToken Additional reward token (i.e. ACoconut) to the vault users.
     * @param _treasury ACoconut treasury that holds fees collected from vaults.
     */
    function initialize(address _rewardToken, address _treasury) public initializer {
        require(_rewardToken != address(0x0), "reward token not set");
        require(_treasury != address(0x0), "treasury not set");
        
        governance = msg.sender;
        treasury = _treasury;
        rewardToken = _rewardToken;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "not governance");
        _;
    }

    /**
     * @dev Updates the govenance address.
     * Only governance can set a new governance. The governance can be renounced
     * by setting a zero address.
     */
    function setGovernance(address _governance) public onlyGovernance {
        address oldGovernance = governance;
        governance = _governance;
        emit GovernanceUpdated(oldGovernance, _governance);
    }

    /**
     * @dev Updates the rewards token.
     * Only governance can set a new reward token.
     */
    function setRewardToken(address _rewardToken) public onlyGovernance {
        require(_rewardToken != address(0x0), "reward token not set");

        address oldRewardToken = rewardToken;
        rewardToken = _rewardToken;
        emit RewardTokenUpdated(oldRewardToken, _rewardToken);
    }

    /**
     * @dev Updates the treasury address.
     * Only governance can set a new treasury address.
     */
    function setTreasury(address _treasury) public onlyGovernance {
        require(_treasury != address(0x0), "treasury not set");

        address oldTreasury = _treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @dev Set a vault to the controller. Only governance can add new vault.
     * @param _vaultId ID of the target vault.
     * @param _vault Address of the target vault. Can be zero address in order to remove a vault from controller.
     */
    function setVault(uint256 _vaultId, address _vault) public onlyGovernance returns (uint256) {
        address oldVault = vaults[_vaultId];
        require(_vault != oldVault, "duplicate");

        // Check if we are going to set or remove a vault.
        if (_vault != address(0x0)) {
            // Going to set a vault. If old vault is empty,
            // this is adding a new vault.
            if (oldVault == address(0x0)) {
                numVaults++;
            }
        } else {
            // Going to remove a vault since _vault = address(0x0)
            // Old vault can't be address(0x0) since the oldVault != _vault check
            numVaults--;
        }

        vaults[_vaultId] = _vault;
        emit VaultUpdated(_vaultId, oldVault, _vault, numVaults);
    }

    /**
     * @dev Add new rewards to a rewarded vault. Only governance can add rewards to vaults.
     * Governance should grant sufficient allowance to Controller in order to add reward.
     * @param _vaultId ID of the vault to have reward.
     * @param _rewardAmount Amount of the reward token to add.
     */
    function addRewards(uint256 _vaultId, uint256 _rewardAmount) public onlyGovernance {
        require(vaults[_vaultId] != address(0x0), "vault not exist");
        require(_rewardAmount > 0, "zero amount");

        address vault = vaults[_vaultId];
        IERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, vault, _rewardAmount);
        IVault(vault).notifyRewardAmount(_rewardAmount);
        emit RewardAdded(_vaultId, rewardToken, _rewardAmount);
    }
    
}