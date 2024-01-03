// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IGradualTokenSwap.sol";
import "./IZLotPool.sol";


/**
 * @title AutoStake
 * @notice The base contract to be inherited by AutoStakeFor{S,Z}Hegic contracts,
 * providing functionalities that control user deposit, refund claims, initial deposit
 * to the GTS contract, and adjustment to fee parameters. Children contracts need
 * to provide constructor, `redeemAndStake`, and `withdraw` functions.
 */
contract AutoStake is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //------------------------------
    // State variables
    //------------------------------

    IERC20 public immutable HEGIC;
    IERC20 public immutable rHEGIC;
    IERC20 public immutable zHEGIC;

    IZLotPool public zLotPool;
    IGradualTokenSwap public GTS;

    uint public feeRate = 100;            // in bases points, e.g. 100 --> 1%
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

    //------------------------------
    // Events
    //------------------------------

    event Deposited(address account, uint amount);
    event Refunded(address account, uint amount);
    event Withdrawn(address account, uint amountAfterFee, uint fee);

    //------------------------------
    // Constructor
    //------------------------------

    constructor(
        IERC20 _HEGIC,
        IERC20 _rHEGIC,
        IERC20 _zHEGIC,
        IZLotPool _zLotPool,
        IGradualTokenSwap _GTS,
        uint _feeRate,
        address _feeRecipient
    ) {
        HEGIC = _HEGIC;
        rHEGIC = _rHEGIC;
        zHEGIC = _zHEGIC;

        GTS = _GTS;
        zLotPool = _zLotPool;

        feeRate = _feeRate;
        feeRecipient = _feeRecipient;
    }

    //------------------------------
    // Setter functions
    //------------------------------

    function setFeeRate(uint _rate) external onlyOwner {
        require(_rate <= 500, "setFeeRate/RATE_TOO_HIGH");
        feeRate = _rate;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setAllowDeposit(bool _allowDeposit) external onlyOwner {
        allowDeposit = _allowDeposit;
    }

    function setGTS(IGradualTokenSwap _GTS) external onlyOwner {
        GTS = _GTS;
    }

    function setZLotPool(IZLotPool _zLotPool) external onlyOwner {
        zLotPool = _zLotPool;
    }

    //------------------------------
    // External functions: users
    //------------------------------

    /**
     * @notice Deposits a given amount of rHEGIC to the contract.
     * @param amount Amount of rHEGIC to be deposited
     */
    function deposit(uint amount) external {
        require(allowDeposit, "deposit/NOT_ALLOWED");
        require(amount > 0, "deposit/AMOUNT_TOO_LOW");

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

        require(allowClaimRefund, "claimRefund/NOT_ALLOWED");
        require(amount > 0, "claimRefund/AMOUNT_TOO_LOW");

        rHEGIC.safeTransfer(msg.sender, amount);

        amountDeposited[msg.sender] = 0;
        totalDeposited = totalDeposited.sub(amount);
        totalDepositors = totalDepositors.sub(1);

        emit Refunded(msg.sender, amount);
    }

    /**
     * @notice Withdraw all available zHEGIC claimable by the user.
     */
    function withdraw() external {
        uint amount = _getUserWithdrawableAmount(msg.sender);
        require(amount > 0, "withdraw/AMOUNT_TOO_LOW");

        uint fee = amount.mul(feeRate).div(10000);
        uint amountAfterFee = amount.sub(fee);

        zHEGIC.safeTransfer(msg.sender, amountAfterFee);
        zHEGIC.safeTransfer(feeRecipient, fee);

        amountWithdrawn[msg.sender] = amountWithdrawn[msg.sender].add(amount);

        totalWithdrawable = totalWithdrawable.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amountAfterFee);
        totalFeeCollected = totalFeeCollected.add(fee);

        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    //------------------------------
    // External functions: owner
    //------------------------------

    /**
     * @notice Deposit all rHEGIC to the redemption contract. Once this is executed,
     * no new deposit will be accepted, and users will not be able to claim rHEGIC refund.
     */
    function provideToGTS() external onlyOwner {
        rHEGIC.approve(address(GTS), totalDeposited);
        GTS.provide(totalDeposited);

        allowDeposit = false;
        allowClaimRefund = false;
    }

    /**
     * @notice Redeem the maximum possible amount of rHEGIC to HEGIC, then stake
     * in the sHEGIC contract. The developer will call this at regular intervals.
     * Anyone can call this as well, albeit no benefit.
     * @return amountRedeemed Amount of HEGIC redeemed
     * @return amountStaked Amount of zHEGIC received from staking HEGIC
     */
    function redeemAndStake() external returns (uint amountRedeemed, uint amountStaked) {
        amountRedeemed = _redeem();
        amountStaked = _stake();
        lastRedemptionTimestamp = block.timestamp;
    }

    /**
     * @notice Drain any ERC20 token held in the contract and transfer to the owner.
     * This is reserved for cases where a hack or a fatal glitch causes user funds
     * to get stuck. The owner can then use this function to recover some of those
     * funds.
     * @param token Address of the ERC20 token to drain
     */
    function recoverERC20(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    //------------------------------
    // Helper functions
    //------------------------------

    /**
     * @notice Get the amount of HEGIC available for redemption.
     */
    function getRedeemableAmount() external view returns (uint amount) {
        amount = GTS.available(address(this));
    }

    /**
     * @notice Wrapper for the `_getUserWithdrawableAmount` function.
     */
    function getUserWithdrawableAmount(address account) external view returns (uint amount) {
        amount = _getUserWithdrawableAmount(account);
    }

    /**
     * @notice Wrapper for the `_redeem` internal function.
     */
    function redeem() external onlyOwner {
        _redeem();
    }

    /**
     * @notice Wrapper for the `_stake` internal function.
     */
    function stake() external onlyOwner {
        _stake();
    }

    //------------------------------
    // Internal functions
    //------------------------------

    /**
     * @notice Redeem the maximum possible amount of HEGIC from GradualTokenSwap
     * contract.
     * @return amount The amount of HEGIC token redeemed
     */
    function _redeem() internal returns (uint amount) {
        amount = GTS.available(address(this));
        GTS.withdraw();
        totalRedeemed = totalRedeemed.add(amount);
    }

    /**
     * @notice Staked all HEGIC tokens held by this contract to zLOT, received zHEGIC.
     * @return amount The amount of zHEGIC received
     */
    function _stake() internal returns (uint amount) {
        uint balance = HEGIC.balanceOf(address(this));

        HEGIC.approve(address(zLotPool), balance);
        amount = zLotPool.deposit(balance);

        totalStaked = totalStaked.add(amount);
        totalWithdrawable = totalWithdrawable.add(amount);
    }

    /**
     * @notice Calculate the maximum amount of zHEGIC token available for withdrawable
     * by a user.
     * @param account The user's account address
     * @return amount The user's withdrawable amount
     */
    function _getUserWithdrawableAmount(address account) internal view returns (uint amount) {
        if (totalDeposited == 0) {
            amount = 0;
        } else {
            amount = totalStaked.mul(amountDeposited[account]).div(totalDeposited);
            amount = amount.sub(amountWithdrawn[account]);
        }

        if (totalWithdrawable < amount) {
            amount = totalWithdrawable;
        }
    }
}
