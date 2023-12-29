// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IBooster.sol";
import "./IDepositor.sol";
import "./ILiquidityGauge.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @title vsdToken
/// @notice Contract that accepts tokens, sdTokens, and sdTokens gauges, against vsdToken.
/// @author StakeDAO
/// @custom:contact contact@stakedao.org
contract vsdToken is ERC20 {
    using SafeTransferLib for ERC20;

    /// @notice Address of the locker token.
    address immutable token;

    /// @notice Address of the sdToken corresponding to the token.
    address immutable sdToken;

    /// @notice Address of the veSDT booster contract.
    address immutable booster;

    /// @notice Address of the gauge contract where sdToken is deposited.
    address public gauge;

    /// @notice Address of the depositor contract.
    address public depositor;

    /// @notice Address of the governance.
    address public governance;

    /// @notice Address of the future governance contract.
    address public futureGovernance;

    /// @notice Throws if caller is not the governance.
    error GOVERNANCE();

    /// @notice Event emitted when governance is changed.
    /// @param newGovernance Address of the new governance.
    event GovernanceChanged(address indexed newGovernance);

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert GOVERNANCE();
        _;
    }

    constructor(address _token, address _depositor, address _booster, address _sdToken, address _gauge) {
        token = _token;
        gauge = _gauge;
        booster = _booster;
        sdToken = _sdToken;
        depositor = _depositor;

        governance = msg.sender;

        SafeTransferLib.safeApprove(_sdToken, _gauge, type(uint256).max);
        SafeTransferLib.safeApprove(_token, _depositor, type(uint256).max);
    }

    /// @notice Deposit token through the depositor contract and stake the tokens in the gauge on behalf of the booster contract.
    /// @param _amount Amount of tokens to deposit.
    function deposit(uint256 _amount) external {
        /// Transfer the tokens to this contract.
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), _amount);

        /// Check for any incentive tokens sitting in the depositor contract.
        uint256 _incentiveToken = IDepositor(depositor).incentiveToken();

        /// Deposit and stake the tokens on behalf the booster contract.
        IDepositor(depositor).deposit(_amount, true, true, booster);

        /// Mint vsdTokens to the user + any incentive tokens.
        _mint(msg.sender, _amount + _incentiveToken);
    }

    /// @notice Deposit sdToken Gauge to the booster contract.
    /// @param _amount Amount of sdToken to deposit.
    function depositGauge(uint256 _amount) external {
        /// Transfer the tokens directly to the booster contract.
        SafeTransferLib.safeTransferFrom(gauge, msg.sender, booster, _amount);

        /// Mint vsdTokens to the user.
        _mint(msg.sender, _amount);
    }

    /// @notice Deposit sdToken, stake them in the gauge on behalf of the booster contract.
    function depositSdToken(uint256 _amount) external {

        /// Transfer the tokens to this contract.
        SafeTransferLib.safeTransferFrom(sdToken, msg.sender, address(this), _amount);

        /// Stake sdToken in the gauge on behalf of the booster contract.
        ILiquidityGauge(gauge).deposit(_amount, booster);

        /// Mint vsdTokens to the user.
        _mint(msg.sender, _amount);
    }

    /// @notice Withdraw sdToken from the booster contract.
    /// @param _amount Amount of sdToken to withdraw.
    /// @param _unstake Boolean indicating whether to unstake the tokens from the gauge and receive sdToken.
    function withdraw(uint256 _amount, bool _unstake) external {
        /// Burn vsdTokens from the user.
        _burn(msg.sender, _amount);

        /// Withdraw the tokens from the gauge.
        IBooster(booster).withdraw(gauge, _amount);

        /// Unstake the tokens from the gauge.
        if (_unstake) {
            ILiquidityGauge(gauge).withdraw(_amount);

            /// Transfer the tokens to the user.
            SafeTransferLib.safeTransfer(sdToken, msg.sender, _amount);
        } else {
            /// Transfer the tokens to the user.
            SafeTransferLib.safeTransfer(gauge, msg.sender, _amount);
        }
    }

    /// @notice Returns the name of the contract. (ERC20)
    function name() public view override returns (string memory) {
        return string(abi.encodePacked("Vote Boosted ", ERC20(sdToken).symbol()));
    }

    /// @notice Returns the symbol of the contract. (ERC20)
    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked("v", ERC20(sdToken).symbol()));
    }

    /// @notice Returns the decimals of the contract. (ERC20)
    function decimals() public view override returns (uint8) {
        return ERC20(sdToken).decimals();
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE
    ///////////////////////////////////////////////////////////////

    /// @notice Sets the depositor address.
    function setDepositor(address _depositor) external onlyGovernance {
        /// Remove the approval from the old depositor.
        SafeTransferLib.safeApprove(token, depositor, 0);

        /// Update the depositor address.
        depositor = _depositor;

        /// Approve the new depositor to spend the token.
        SafeTransferLib.safeApprove(token, _depositor, type(uint256).max);
    }

    /// @notice Sets the gauge address.
    /// @param _gauge Address of the gauge contract.
    /// @dev In order to update the gauge address, we need to migrate from the old gauge to the new one by withdrawing.
    function setGauge(address _gauge) external onlyGovernance {
        uint256 _totalSupply = totalSupply();

        /// Withdraw the tokens from the booster contract.
        IBooster(booster).withdraw(gauge, _totalSupply);

        /// Unstake the tokens from the gauge.
        ILiquidityGauge(gauge).withdraw(_totalSupply);

        /// Remove the approval from the old gauge.
        SafeTransferLib.safeApprove(sdToken, gauge, 0);

        /// Set the new gauge address.
        gauge = _gauge;

        /// Approve the new gauge to spend the sdToken.
        SafeTransferLib.safeApprove(sdToken, _gauge, type(uint256).max);

        /// Stake the tokens in the new gauge on behalf of the booster contract.
        ILiquidityGauge(_gauge).deposit(_totalSupply, booster);
    }

    /// @notice Transfer the governance to a new address.
    /// @param _governance Address of the new governance.
    function transferGovernance(address _governance) external onlyGovernance {
        futureGovernance = _governance;
    }

    /// @notice Accept the governance transfer.
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) revert GOVERNANCE();

        governance = msg.sender;

        futureGovernance = address(0);

        emit GovernanceChanged(msg.sender);
    }
}