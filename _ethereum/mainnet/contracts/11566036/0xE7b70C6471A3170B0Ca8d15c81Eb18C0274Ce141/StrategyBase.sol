// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IVault.sol";
import "./IStrategy.sol";
import "./IController.sol";

/**
 * @notice Base contract of Strategy.
 * 
 * This contact defines common properties and functions shared by all strategies.
 * One strategy is bound to one vault and cannot be changed.
 */
abstract contract StrategyBase is IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event PerformanceFeeUpdated(uint256 oldPerformanceFee, uint256 newPerformanceFee);
    event WithdrawalFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);

    address public override vault;
    uint256 public override performanceFee;
    uint256 public override withdrawalFee;
    uint256 public constant FEE_MAX = 10000;    // 0.01%

    constructor(address _vault) internal {
        require(_vault != address(0x0), "vault not set");
        vault = _vault;
    }

    /**
     * @dev Returns the token that the vault pools to seek yield.
     * Should be the same as Vault.token().
     */
    function token() public override view returns (address) {
        return IVault(vault).token();
    }

    /**
     * @dev Returns the Controller that manages the vault.
     * Should be the same as Vault.controler().
     */
    function controller() public override view returns (address) {
        return IVault(vault).controller();
    }

    /**
     * @dev Returns the governance of the Strategy.
     * Controller and its underlying vaults and strategies should share the same governance.
     */
    function governance() public override view returns (address) {
        return IVault(vault).governance();
    }

    /**
     * @dev Return the strategist which performs daily permissioned operations.
     * Vault and its underlying strategies should share the same strategist.
     */
    function strategist() public override view returns (address) {
        return IVault(vault).strategist();
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "not governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == governance() || msg.sender == strategist(), "not strategist");
        _;
    }

    /**
     * @dev Updates the performance fee. Only governance can update the performance fee.
     */
    function setPerformanceFee(uint256 _performanceFee) public onlyGovernance {
        require(_performanceFee <= FEE_MAX, "overflow");
        uint256 oldPerformanceFee = performanceFee;
        performanceFee = _performanceFee;

        emit PerformanceFeeUpdated(oldPerformanceFee, _performanceFee);
    }

    /**
     * @dev Updates the withdrawal fee. Only governance can update the withdrawal fee.
     */
    function setWithdrawalFee(uint256 _withdrawalFee) public onlyGovernance {
        require(_withdrawalFee <= FEE_MAX, "overflow");
        uint256 oldWithdrawalFee = withdrawalFee;
        withdrawalFee = _withdrawalFee;

        emit WithdrawalFeeUpdated(oldWithdrawalFee, _withdrawalFee);
    }

    /**
     * @dev Used to salvage any ETH deposited into the vault by mistake.
     * Only governance or strategist can salvage ETH from the vault.
     * The salvaged ETH is transferred to treasury for futher operation.
     */
    function salvage() public onlyStrategist {
        uint256 amount = address(this).balance;
        address payable target = payable(IController(controller()).treasury());
        (bool success, ) = target.call{value: amount}(new bytes(0));
        require(success, 'ETH salvage failed');
    }

    /**
     * @dev Used to salvage any token deposited into the vault by mistake.
     * The want token cannot be salvaged.
     * Only governance or strategist can salvage token from the vault.
     * The salvaged token is transferred to treasury for futhuer operation.
     * @param _tokenAddress Token address to salvage.
     */
    function salvageToken(address _tokenAddress) public onlyStrategist {
        address[] memory protected = _getProtectedTokens();
        for (uint256 i = 0; i < protected.length; i++) {
            require(_tokenAddress != protected[i], "cannot salvage");
        }

        IERC20Upgradeable target = IERC20Upgradeable(_tokenAddress);
        target.safeTransfer(IController(controller()).treasury(), target.balanceOf(address(this)));
    }

    /**
     * @dev Return the list of tokens that should not be salvaged.
     */
    function _getProtectedTokens() internal virtual view returns (address[] memory);
}