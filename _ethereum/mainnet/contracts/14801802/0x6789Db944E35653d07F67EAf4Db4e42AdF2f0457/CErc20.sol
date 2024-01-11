pragma solidity ^0.5.16;

import "./CToken.sol";
import "./EIP20Interface.sol";

interface CompLike {
  function delegate(address delegatee) external;
}

interface RibbonMinter {
  function mint(address gauge_addr) external;
}

interface RewardsDistributor {
  function burn(address cToken, uint256 amount, bool burnStables) external;
}

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @dev This contract should not to be deployed on its own; instead, deploy `CErc20Delegator` (proxy contract) and `CErc20Delegate` (logic/implementation contract).
 * @author Compound
 */
contract CErc20 is CToken, CErc20Interface {
    // Minter contract for rbn gauge emissions
    RibbonMinter constant MINTER = RibbonMinter(0x5B0655F938A72052c46d2e94D206ccB6FF625A3A);
    // RBN token
    EIP20Interface constant RBN = EIP20Interface(0x6123B0049F904d730dB3C36a31167D9d4121fA6B);

    // Rewards distributor
    // https://github.com/Rari-Capital/compound-protocol/blob/fuse-final/contracts/RewardsDistributorDelegate.sol
    RewardsDistributor public rewardsDistributor;

    function initialize() public {
        // CToken initialize does the bulk of the work
        uint256 initialExchangeRateMantissa_ = 0.2e18;
        uint8 decimals_ = EIP20Interface(0x9038403C3F7C6B5Ca361C82448DAa48780D7C8Bd).decimals();
        super.initialize(ComptrollerInterface(0xC1ee062D67e36aBc20D17cF150D81834c129BE44), InterestRateModel(0x4EF29407a8dbcA2F37B7107eAb54d6f2a3f2ad60), initialExchangeRateMantissa_, "Ribbon\'s Birthday Cake Ribbon.fi rETH-THETA Gauge Deposit", "frETH-THETA-gauge-199", decimals_, 100000000000000000, 0);

        // Set underlying (do not sanity check)
        underlying = 0x9038403C3F7C6B5Ca361C82448DAa48780D7C8Bd;
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint) {
        (uint err,) = mintInternal(mintAmount);
        return err;
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(redeemTokens);
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowInternal(repayAmount);
        return err;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint) {
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
        return err;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        _callOptionalReturn(abi.encodeWithSelector(EIP20NonStandardInterface(underlying).transferFrom.selector, from, address(this), amount), "!TOKEN_TRANSFER_IN");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint amount) internal {
        _callOptionalReturn(abi.encodeWithSelector(EIP20NonStandardInterface(underlying).transfer.selector, to, amount), "!TOKEN_TRANSFER_OUT");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param errorMessage The revert string to return on failure.
     */
    function _callOptionalReturn(bytes memory data, string memory errorMessage) internal {
        bytes memory returndata = _functionCall(underlying, data, errorMessage);
        if (returndata.length > 0) require(abi.decode(returndata, (bool)), errorMessage);
    }

    /**
    * @notice Admin call to delegate the votes of the COMP-like underlying
    * @param compLikeDelegatee The address to delegate votes to
    * @dev CTokens whose underlying are not CompLike should revert here
    */
    function _delegateCompLikeTo(address compLikeDelegatee) external {
        require(hasAdminRights(), "!admin");
        CompLike(underlying).delegate(compLikeDelegatee);
    }

    /**
    * @notice Admin call to set rewards distributor
    * @param _rewardsDistributor The rewards contract
    */
    function _setRewardsDistributor(address _rewardsDistributor) external {
        require(hasAdminRights(), "!admin");

        rewardsDistributor = RewardsDistributor(_rewardsDistributor);
    }

    /**
    * @notice Anyone can claim gauge rewards for collateralized gauge tokens.
    */
    function claimGaugeRewards() external {
        // Underlying is the gauge token like rETH-THETA-gauge
        MINTER.mint(underlying);

        uint256 toDistribute = RBN.balanceOf(address(this));

        if (toDistribute == 0) {
          return;
        }

        RBN.approve(address(rewardsDistributor), toDistribute);

        /*
        * Transfer rewards to reward distributor which will distribute rewards
        * to those who supply / borrow. The reason we need to do this way is
        * once individuals transfer the collateral (gauge tokens) to the cToken
        * contract, they forfeit their rewards and now the cToken starts accumulating
        * rewards. We want to redistribute some of it back to those supplying
        * gauge tokens as collateral who 'should' be getting those rewards, and some
        * to DAI / USDC suppliers
        */

        rewardsDistributor.burn(address(this), toDistribute, true);
    }
}
