// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IYieldAggregator.sol";

/**
 * @title Vault
 * @dev Contract in charge of holding usdc tokens and depositing them to Yield Aggregator
 *
 */
contract Vault is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public constant BACKEND_ADMIN_ROLE =
        keccak256("BACKEND_ADMIN_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private usdcToken;

    /**
     * @notice Emitted when USDC tokens are moved to Yield Aggregator contract
     * @param amount_usdc is the amount of tokens being moved
     */
    event FundsMovedToAggregator(uint256 amount_usdc);

    /**
     * @notice Emitted when USDC tokens are moved to Yield Aggregator contract
     * @param _depositant: account that is transferring usdc tokens to addres(this)
     * @param _amount: amount of usdc tokens to be transferred
     */
    event DepositToVault(address _depositant, uint256 _amount);

    /**
     * @dev address of the Chainlink Defender
     */
    address private backendAddress;
    /**
     * @dev address of the contract responsible for yielding
     */
    address private yieldSourceAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @notice initialize init the contract with the following parameters
     * @dev this function is called only once during the contract initialization
     * @param _usdcTokenAddress USDC token contract address
     * @param _backendAddress address of the Chainlink Defender
     */
    function initialize(address _usdcTokenAddress, address _backendAddress)
        external
        initializer
    {
        require(
            _usdcTokenAddress != address(0),
            "Vault: USDC token address cannot be address 0!"
        );

        usdcToken = IERC20Upgradeable(_usdcTokenAddress);
        backendAddress = _backendAddress;

        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BACKEND_ADMIN_ROLE, _backendAddress);

        __Pausable_init();
    }

    /**
     * @notice Transfers "_amount" of USDC tokens to Vault Smart Contract
     * @param _amount is the amount of USDC tokens to be transferred by a caller
     */
    function deposit(uint256 _amount) public whenNotPaused {
        // user approves Vault to transfer usdc tokens
        require(
            usdcToken.balanceOf(_msgSender()) >= _amount,
            "Vault: Not enough balance."
        );

        // transfer usdc from user to vault
        usdcToken.safeTransferFrom(_msgSender(), address(this), _amount);
        emit DepositToVault(_msgSender(), _amount);
    }

    /**
     * @notice Transfers "amount_usdc" of tokens to Yield Aggregator contract
     * @param amount_usdc: Amount of USDC tokens to be transferred to Yield Aggregator
     */
    function moveFundsToAggregator(uint256 amount_usdc)
        external
        onlyRole(BACKEND_ADMIN_ROLE)
        whenNotPaused
    {
        require(
            usdcToken.balanceOf(address(this)) >= amount_usdc,
            "Vault: Contract does not have enough balance."
        );

        // approve to Yield Aggregator
        usdcToken.approve(yieldSourceAddress, amount_usdc);

        // call deposit from Yield Aggregator Contract
        IYieldAggregator(yieldSourceAddress).deposit(amount_usdc);

        emit FundsMovedToAggregator(amount_usdc);
    }

    /**
     * @notice used to change the address of the Chainnlink Defnder
     * @param _backendAddress new address of the Chainlink Defender
     */
    function setBackendAddress(address _backendAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _backendAddress != address(0),
            "Vault: Backend contract address cannot be address 0!"
        );
        revokeRole(BACKEND_ADMIN_ROLE, backendAddress);
        backendAddress = _backendAddress;
        grantRole(BACKEND_ADMIN_ROLE, backendAddress);
    }

    /**
     * @notice used to change the address of the contract responsible with yielding
     * @param _yieldSourceAddress new address of the contract responsible with yielding
     */
    function setYieldSourceAddress(address _yieldSourceAddress)
        external
        onlyRole(BACKEND_ADMIN_ROLE)
    {
        require(
            _yieldSourceAddress != address(0),
            "Vault: Yield Source contract address cannot be address 0!"
        );
        yieldSourceAddress = _yieldSourceAddress;
    }

    function _testWithdrawAllTokens() external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdcToken.transfer(_msgSender(), usdcToken.balanceOf(address(this)));
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
