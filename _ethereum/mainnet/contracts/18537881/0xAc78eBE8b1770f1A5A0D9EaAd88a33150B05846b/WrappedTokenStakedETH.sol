// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts
import "./DepositWithdrawToken.sol";
import "./SafeTransferLib.sol";
import "./SafeERC20.sol";

// interfaces
import "./IWETH.sol";

import "./errors.sol";

contract WrappedTokenStakedETH is DepositWithdrawToken {
    /// @notice the address of WETH
    IWETH public immutable weth;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _allowlist,
        address _underlying,
        address _weth
    ) DepositWithdrawToken(_name, _symbol, _decimals, _allowlist, _underlying) initializer {
        if (_weth == address(0)) revert BadAddress();

        weth = IWETH(_weth);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/
    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        __DepositWithdrawToken_init(_name, _symbol, _owner);
    }

    /**
     * @notice Stake WETH before depositing to mint wrapped version
     * @param _amount is the amount of coin to deposit
     */
    function deposit(uint256 _amount) external override nonReentrant returns (uint256) {
        uint256 amount = _unwrapWethAndStake(_amount);

        return _depositFor(address(this), msg.sender, amount);
    }

    /**
     * @notice Stake WETH before depositing to mint wrapped version to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of coin to deposit
     */
    function depositFor(address _recipient, uint256 _amount) external override nonReentrant returns (uint256) {
        uint256 amount = _unwrapWethAndStake(_amount);

        return _depositFor(address(this), _recipient, amount);
    }

    /**
     * @notice Stake ETH before depositing to mint wrapped version
     */
    function depositETH() external payable nonReentrant returns (uint256) {
        uint256 amount = _stake(msg.value);

        return _depositFor(address(this), msg.sender, amount);
    }

    /**
     * @notice Stake ETH before depositing to mint wrapped version to a recipient
     * @param _recipient is the address of the recipient
     */
    function depositETHFor(address _recipient) external payable nonReentrant returns (uint256) {
        uint256 amount = _stake(msg.value);

        return _depositFor(address(this), _recipient, amount);
    }

    /**
     * @notice Stake WETH before depositing to mint wrapped version
     * @param _amount is the amount of coin to deposit
     */
    function depositWstETH(uint256 _amount) external nonReentrant returns (uint256) {
        return _depositFor(msg.sender, msg.sender, _amount);
    }

    /**
     * @notice Stake WETH before depositing to mint wrapped version to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of coin to deposit
     */
    function depositWstETHFor(address _recipient, uint256 _amount) external nonReentrant returns (uint256) {
        return _depositFor(msg.sender, _recipient, _amount);
    }

    /**
     * @notice Receive ETH from WETH withdraw
     */
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Unwraps WETH and stakes to underlying, returning the amount received
     */
    function _unwrapWethAndStake(uint256 _amount) internal virtual returns (uint256) {
        SafeERC20.safeTransferFrom(weth, msg.sender, address(this), _amount);
        weth.withdraw(_amount);

        return _stake(_amount);
    }

    /**
     * @notice Stakes to underlying, returning the amount received
     * @param _amount amount of ETH to stake
     */
    function _stake(uint256 _amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));

        SafeTransferLib.safeTransferETH(address(underlying), _amount);

        uint256 balanceAfter = underlying.balanceOf(address(this));

        if (balanceAfter <= balanceBefore) revert BadAmount();

        return balanceAfter - balanceBefore;
    }
}
