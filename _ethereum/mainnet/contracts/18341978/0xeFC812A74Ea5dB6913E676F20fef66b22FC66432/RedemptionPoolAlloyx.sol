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

    uint256 public constant DEADLINE = 1698251639;
    // GRO has 18 decimals
    uint256 internal constant PRECISION = 1e18;
    address internal constant DAO = address(0x359F4fe841f246a095a82cb26F5819E10a91fe0d);

    // TOKENS
    IERC20 public constant GRO = IERC20(0x3Ec8798B81485A254928B70CDA1cf0A2BB0B74D7);
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

    mapping(address => uint256) private _userGROBalance;
    mapping(address => uint256) private _userClaims;
    uint256 public totalGRO;
    uint256 public totalAlloyxDeposited;
    uint256 public totalAlloyxWithdrawn;

    /////////////////////////////////////////////////////////////////////////////
    //                                  Events                                 //
    /////////////////////////////////////////////////////////////////////////////
    event Deposit(address indexed user, uint256 amount);
    event TotalGRODeposited(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event AlloyxDeposit(uint256 amount);

    /////////////////////////////////////////////////////////////////////////////
    //                                  CONSTRUCTOR                            //
    /////////////////////////////////////////////////////////////////////////////

    constructor() {
        transferOwnership(DAO);
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                   VIEWS                                 //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the price per share of the pool in terms of ALLOYX
    function getDURAPerGRO() public view returns (uint256) {
        return (totalAlloyxDeposited * PRECISION) / totalGRO;
    }

    /// @notice Returns user's share of the claims pot
    /// @param user address of the user
    function getDuraAvailable(address user) public view returns (uint256) {
        return (_userGROBalance[user] * totalAlloyxDeposited) / totalGRO - _userClaims[user];
    }

    /// @notice Returns the amount of GRO user has deposited
    /// @param user address of the user
    function getUserBalance(address user) external view returns (uint256) {
        return _userGROBalance[user];
    }

    /// @notice Returns claimed Alloyx for a user
    /// @param user address of the user
    function getUserClaim(address user) external view returns (uint256) {
        return _userClaims[user];
    }

    /// @notice Returns the deadline of the redemption pool
    function getDeadline() external pure returns (uint256) {
        return DEADLINE;
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                  CORE                                   //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice deposit GRO tokens
    /// @param _amount amount of GRO tokens to deposit
    function deposit(uint256 _amount) external onlyBeforeDeadline {
        // Transfers the GRO tokens from the sender to this contract
        GRO.safeTransferFrom(msg.sender, address(this), _amount);
        // Increases the balance of the sender by the amount
        _userGROBalance[msg.sender] += _amount;
        // Increases the total deposited by the amount
        totalGRO += _amount;
        emit Deposit(msg.sender, _amount);
        emit TotalGRODeposited(totalGRO);
    }

    /// @notice withdraw deposited GRO tokens before the deadline
    /// @param _amount amount of GRO tokens to withdraw
    function withdraw(uint256 _amount) external onlyBeforeDeadline {
        if (_userGROBalance[msg.sender] < _amount) {
            revert RedemptionErrors.InsufficientBalance();
        }

        _userGROBalance[msg.sender] -= _amount;
        totalGRO -= _amount;
        GRO.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Allow users to claim their share of Alloyx tokens based on the amount of GRO tokens they have deposited
     * @dev Users must have a positive GRO token balance and a non-zero claim available to make a claim
     * @dev The deadline for making GRO deposits must have passed
     * @dev Redeems the user's Alloyx tokens for an equivalent amount of GRO tokens and transfers them to the user's address
     * @dev Decreases the user's claims and contract accounting by the amount claimed
     */
    function claim(uint256 _amount) external onlyAfterDeadline {
        if (_amount == 0) revert RedemptionErrors.InvalidClaim();
        // Get the amount of ALLOYX tokens available for the user to claim
        uint256 userClaim = getDuraAvailable(msg.sender);
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
        if (_token == address(GRO)) revert RedemptionErrors.NoSweepGro();

        // Transfers the tokens to the owner
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}
