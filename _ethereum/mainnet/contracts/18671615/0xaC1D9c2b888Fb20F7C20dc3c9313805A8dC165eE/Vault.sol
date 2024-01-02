// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IERC677.sol";
import "./IStaking.sol";
import "./IStakingRewards.sol";

/**
 * @title Vault
 * @notice Base vault contract for depositing LINK collateral into the Chainlink staking controller
 */
abstract contract Vault is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public token;
    address public vaultController;
    IStaking public stakeController;
    IStakingRewards public rewardsController;

    uint256[9] private __gap;

    error OnlyVaultController();

    /**
     * @notice initializes contract
     * @param _token address of LINK token
     * @param _vaultController address of the strategy that controls this vault
     * @param _stakeController address of Chainlink staking contract
     * @param _rewardsController address of Chainlink staking rewards contract
     **/
    function __Vault_init(
        address _token,
        address _vaultController,
        address _stakeController,
        address _rewardsController
    ) public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = IERC20Upgradeable(_token);
        vaultController = _vaultController;
        stakeController = IStaking(_stakeController);
        rewardsController = IStakingRewards(_rewardsController);
    }

    /**
     * @notice reverts if sender is not vaultController
     **/
    modifier onlyVaultController() {
        if (msg.sender != vaultController) revert OnlyVaultController();
        _;
    }

    /**
     * @notice deposits tokens from the vaultController into the Chainlink staking contract
     * @param _amount amount to deposit
     */
    function deposit(uint256 _amount) external virtual onlyVaultController {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        IERC677(address(token)).transferAndCall(address(stakeController), _amount, "");
    }

    /**
     * @notice withdrawals are not yet implemented
     */
    function withdraw(uint256) external view onlyVaultController {
        revert("withdrawals not yet implemented");
    }

    /**
     * @notice returns the total balance of this contract in the Chainlink staking contract
     * @dev includes principal plus any rewards
     * @return total balance
     */
    function getTotalDeposits() public view returns (uint256) {
        return getPrincipalDeposits() + getRewards();
    }

    /**
     * @notice returns the principal balance of this contract in the Chainlink staking contract
     * @return principal balance
     */
    function getPrincipalDeposits() public view virtual returns (uint256) {
        return stakeController.getStakerPrincipal(address(this));
    }

    /**
     * @notice returns the claimable rewards balance of this contract in the Chainlink staking rewards contract
     * @return rewards balance
     */
    function getRewards() public view returns (uint256) {
        return rewardsController.getReward(address(this));
    }

    /**
     * @dev Checks authorization for contract upgrades
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
