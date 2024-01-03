// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IGradualTokenSwap.sol";


/**
 * @title AutoStake
 * @notice The base contract to be inherited by AutoStakeFor{S,Z}Hegic contracts,
 * providing functionalities that control user deposit, refund claims, initial deposit
 * to the GTS contract, and adjustment to fee parameters. Children contracts need
 * to provide constructor, `redeemAndStake`, and `withdraw` functions.
 */
abstract contract AutoStake is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable HEGIC;
    IERC20 public immutable rHEGIC;
    IGradualTokenSwap public immutable GTS;

    uint public feeRate = 100;  // in bases points, e.g. 100 --> 1%
    address public feeRecipient;

    bool public allowDeposit = true;
    bool public allowClaimRefund = true;

    uint public totalDepositors = 0;      // number of depositors
    uint public totalDeposited = 0;       // amount of rHEGIC deposit received
    uint public totalRedeemed = 0;        // amount of HEGIC redeemed from rHEGIC
    uint public totalStaked = 0;          // amount of s/zHEGIC received from staking pools
    uint public totalWithdrawable = 0;    // amount of s/zHEGIC currently held by the contract & withdrawable by users
    uint public totalWithdrawn = 0;       // amount of s/zHEGIC already withdrawn by users (excl. fees)
    uint public totalFeeCollected = 0;    // amount of fees collected
    uint public lastRedemptionTimestamp;  // timestamp of the last time `redeemAndStake` is performed

    mapping(address => uint) public amountDeposited;  // amount of rHEGIC the user has deposited
    mapping(address => uint) public amountWithdrawn;  // amount of s/zHEGIC the user has withdrawn (incl. fee)

    event Deposited(address account, uint amount);
    event Refunded(address account, uint amount);
    event Withdrawn(address account, uint amountAfterFee, uint fee);

    constructor(IERC20 _HEGIC, IERC20 _rHEGIC, IGradualTokenSwap _GTS) {
        HEGIC = _HEGIC;
        rHEGIC = _rHEGIC;
        GTS = _GTS;
    }

    /**
     * @notice Set the fee rate users are charged upon withdrawal.
     * @param _rate The new rate in basis points. E.g. 200 = 2%
     */
    function setFeeRate(uint _rate) external onlyOwner {
        require(_rate >= 0, "Rate too low!");
        require(_rate <= 500, "Rate too high!");
        feeRate = _rate;
    }

    /**
     * @notice Set the recipient address to fees generated.
     * @param _recipient The new recipient address
     */
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Cannot set recipient to zero address");
        feeRecipient = _recipient;
    }

    /**
     * @notice Set to accept or reject new deposits. May be called if the project
     * fails to attract enough deposits that justify the work. In this case the
     * developer will inform depositors to withdraw their rHEGIC by calling the
     * `claimRefund` function.
     * @param _allowDeposit Whether new deposits are accepted
     */
    function setAllowDeposit(bool _allowDeposit) external onlyOwner {
        allowDeposit = _allowDeposit;
    }

    /**
     * @notice Deposits a given amount of rHEGIC to the contract.
     * @param amount Amount of rHEGIC to be deposited
     */
    function deposit(uint amount) external {
        require(allowDeposit, "New deposits no longer accepted");
        require(amount > 0, "Amount must be greater than zero");

        rHEGIC.safeTransferFrom(msg.sender, address(this), amount);

        amountDeposited[msg.sender] = amountDeposited[msg.sender].add(amount);
        totalDeposited = totalDeposited.add(amount);
        if (amountDeposited[msg.sender] == amount) {
            totalDepositors = totalDepositors.add(1);
        }

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Claim a refund of rHEGIC before they are deposited to the redemption
     * contract. The developer will notify users to do this if the project fails
     * to attract enough deposit.
     */
    function claimRefund() external {
        uint amount = amountDeposited[msg.sender];

        require(amount > 0, "User has not deposited any fund");
        require(allowClaimRefund, "Funds already transferred to the redemption contract");

        rHEGIC.safeTransfer(msg.sender, amount);

        amountDeposited[msg.sender] = 0;
        totalDeposited = totalDeposited.sub(amount);
        totalDepositors = totalDepositors.sub(1);

        emit Refunded(msg.sender, amount);
    }

    /**
     * @notice Deposit all rHEGIC to the redemption contract. Once this is executed,
     * no new deposit will be accepted, and users will not be able to claim rHEGIC refund.
     */
    function provideToGTS() external onlyOwner {
        require(totalDeposited > 0, "No rHEGIC token to deposit");

        rHEGIC.approve(address(GTS), totalDeposited);
        GTS.provide(totalDeposited);

        allowDeposit = false;
        allowClaimRefund = false;
    }

    /**
     * @notice Helper function. Get the amount of HEGIC currently redeemable from
     * the GTS contract.
     */
    function getRedeemableAmount() external view returns (uint amount) {
        amount = GTS.available(address(this));
    }

    // Functions to be overriden
    function redeemAndStake() virtual external returns (uint, uint) {}
    function withdraw() virtual external {}
}
