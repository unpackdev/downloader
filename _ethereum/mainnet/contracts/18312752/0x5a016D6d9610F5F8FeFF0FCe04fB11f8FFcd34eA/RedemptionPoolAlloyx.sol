// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "Ownable.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {RedemptionErrors} from "Errors.sol";

/////////////////////////////////////////////////////////////////////////////
//                                  Interfaces                             //
/////////////////////////////////////////////////////////////////////////////

contract RedemptionPoolAlloyX is Ownable {
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////////
    //                                  Constants                              //
    /////////////////////////////////////////////////////////////////////////////

    uint256 public constant DURATION = 14 days;
    uint256 public immutable DEADLINE;
    // USDC has 6 decimals
    uint256 internal constant PRECISION = 1e6;
    address internal constant DAO = address(0x359F4fe841f246a095a82cb26F5819E10a91fe0d);

    // TOKENS
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant ALLOYX = IERC20(0x4562724cAa90d866c35855b9baF71E5125CAD5B6);

    /////////////////////////////////////////////////////////////////////////////
    //                                  Modifiers                              //
    /////////////////////////////////////////////////////////////////////////////

    modifier onlyBeforeDeadline() {
        if (block.timestamp > DEADLINE) {
            revert RedemptionErrors.DeadlineExceeded();
        }
        _;
    }

    modifier onlyAfterDeadline() {
        if (block.timestamp <= DEADLINE) {
            revert RedemptionErrors.ClaimsPeriodNotStarted();
        }
        _;
    }
    /////////////////////////////////////////////////////////////////////////////
    //                                  Storage                                //
    /////////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _userUSDCBalance;
    mapping(address => uint256) private _userClaims;
    uint256 public totalUSDC;
    uint256 public totalAlloyxDeposited;
    uint256 public totalAlloyxWithdrawn;

    /////////////////////////////////////////////////////////////////////////////
    //                                  Events                                 //
    /////////////////////////////////////////////////////////////////////////////
    event Deposit(address indexed user, uint256 amount);
    event TotalUSDCDeposited(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event AlloyxDeposit(uint256 amount);

    /////////////////////////////////////////////////////////////////////////////
    //                                  CONSTRUCTOR                            //
    /////////////////////////////////////////////////////////////////////////////

    constructor() {
        transferOwnership(DAO);
        // Sets the DEADLINE to 28 days from now
        DEADLINE = block.timestamp + DURATION;
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                   VIEWS                                 //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the price per share of the pool in terms of ALLOYX
    function getPricePerShare() public view returns (uint256) {
        return (totalAlloyxDeposited * PRECISION) / totalUSDC;
    }

    /// @notice Returns user's share of the claims pot
    /// @param user address of the user
    function getSharesAvailable(address user) public view returns (uint256) {
        return (_userUSDCBalance[user] * totalAlloyxDeposited) / totalUSDC - _userClaims[user];
    }

    /// @notice Returns the amount of USDC user has deposited
    /// @param user address of the user
    function getUserBalance(address user) external view returns (uint256) {
        return _userUSDCBalance[user];
    }

    /// @notice Returns claimed Alloyx for a user
    /// @param user address of the user
    function getUserClaim(address user) external view returns (uint256) {
        return _userClaims[user];
    }

    /// @notice Returns the deadline of the redemption pool
    function getDeadline() external view returns (uint256) {
        return DEADLINE;
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                  CORE                                   //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice deposit USDC tokens
    /// @param _amount amount of USDC tokens to deposit
    function deposit(uint256 _amount) external onlyBeforeDeadline {
        // Transfers the USDC tokens from the sender to this contract
        USDC.safeTransferFrom(msg.sender, address(this), _amount);
        // Increases the balance of the sender by the amount
        _userUSDCBalance[msg.sender] += _amount;
        // Increases the total deposited by the amount
        totalUSDC += _amount;
        emit Deposit(msg.sender, _amount);
        emit TotalUSDCDeposited(totalUSDC);
    }

    /// @notice withdraw deposited USDC tokens before the deadline
    /// @param _amount amount of USDC tokens to withdraw
    function withdraw(uint256 _amount) external onlyBeforeDeadline {
        if (_userUSDCBalance[msg.sender] < _amount) {
            revert RedemptionErrors.InsufficientBalance();
        }

        _userUSDCBalance[msg.sender] -= _amount;
        totalUSDC -= _amount;
        USDC.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Allow users to claim their share of Alloyx tokens based on the amount of USDC tokens they have deposited
     * @dev Users must have a positive USDC token balance and a non-zero claim available to make a claim
     * @dev The deadline for making USDC deposits must have passed
     * @dev Redeems the user's Alloyx tokens for an equivalent amount of USDC tokens and transfers them to the user's address
     * @dev Decreases the user's claims and contract accounting by the amount claimed
     */
    function claim(uint256 _amount) external onlyAfterDeadline {
        if (_amount == 0) revert RedemptionErrors.InvalidClaim();
        // Get the amount of ALLOYX tokens available for the user to claim
        uint256 userClaim = getSharesAvailable(msg.sender);
        // Check that _amount is greater than 0 and smaller (or equal to) than userClaim
        if (_amount > userClaim) {
            revert RedemptionErrors.InvalidClaim();
        }

        // Adjust the user's and the cumulative tally of claimed ALLOYX tokens
        _userClaims[msg.sender] += _amount;
        totalAlloyxWithdrawn += _amount;
        ALLOYX.safeTransfer(msg.sender, _amount);
        emit Claim(msg.sender, _amount);
    }

    /////////////////////////////////////////////////////////////////////////////
    //                              Permissioned funcs                         //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice Pulls assets from the DAO msig
    /// @param _amount amount of assets to pull
    function depositAlloy(uint256 _amount) external onlyOwner {
        // Transfer alloyx from the caller to this contract
        ALLOYX.safeTransferFrom(msg.sender, address(this), _amount);

        totalAlloyxDeposited += _amount;
        emit AlloyxDeposit(totalAlloyxDeposited);
    }

    /// @notice Allow to withdraw any tokens except Alloyx back to the owner, as long as the deadline has not passed
    /// @param _token address of the token to sweep
    function sweep(address _token) external onlyOwner onlyBeforeDeadline {
        // Do not allow to sweep ALLOYX tokens
        if (_token == address(USDC)) revert RedemptionErrors.NoSweepUSDC();

        // Transfers the tokens to the owner
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Allow DAO to withdraw USDC tokens after the deadline
    /// @param _amount amount of USDC to withdraw
    function withdrawUSDC(uint256 _amount) external onlyOwner onlyAfterDeadline {
        USDC.safeTransfer(owner(), _amount);
    }
}
