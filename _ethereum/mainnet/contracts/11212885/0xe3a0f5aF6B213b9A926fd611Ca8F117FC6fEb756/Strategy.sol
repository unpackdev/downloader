// SPDX-License-Identifier: GPL-3.0
// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import "./BaseStrategy.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./ISoloMargin.sol";

contract Strategy is BaseStrategy  {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    uint256 public liquidityCushion;

    constructor(address _vault, uint256 _liquidityCushion) public BaseStrategy(_vault) {
        liquidityCushion = _liquidityCushion;
         want.safeApprove(SOLO, uint256(-1));
    }

    function setLiquidityCushion(uint256 _liquidityCushion) external {
        require(msg.sender == governance() || msg.sender == strategist, "!management"); // dev: not governance or strategist
        liquidityCushion = _liquidityCushion;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external override pure returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "StrategyDyDx";
    }

    /*
     * Provide an accurate estimate for the total amount of assets (principle + return)
     * that this strategy is currently managing, denominated in terms of `want` tokens.
     * This total should be "realizable" e.g. the total value that could *actually* be
     * obtained from this strategy if it were to divest it's entire position based on
     * current on-chain conditions.
     *
     * NOTE: care must be taken in using this function, since it relies on external
     *       systems, which could be manipulated by the attacker to give an inflated
     *       (or reduced) value produced by this function, based on current on-chain
     *       conditions (e.g. this function is possible to influence through flashloan
     *       attacks, oracle manipulations, or other DeFi attack mechanisms).
     *
     * NOTE: It is up to governance to use this function in order to correctly order
     *       this strategy relative to its peers in order to minimize losses for the
     *       Vault based on sudden withdrawals. This value should be higher than the
     *       total debt of the strategy and higher than it's expected value to be "safe".
     */
    function estimatedTotalAssets() public override view returns (uint256) {
        uint256 underlying = dydxBalance();
        return want.balanceOf(address(this)).add(underlying);
    }

     function dydxBalance() public view returns (uint256 _profit) {
        (address[] memory cur,,
            Types.Wei[] memory balance) = ISoloMargin(SOLO).getAccountBalances(_getAccountInfo());

            for(uint i = 0; i < cur.length; i++){
                if(cur[i] == address(want)){
                    return balance[i].value;
                }
            }
     }

     function test_reserve() external view returns (uint256 _profit) {
        return getReserve();
     }

     function dydxLiquidity() internal view returns (uint256 _profit) {
        return want.balanceOf(SOLO);
     }

     function dydxDeposit(uint256 depositAmount) internal  {

        ISoloMargin solo = ISoloMargin(SOLO);
        uint256 marketId = _getMarketIdFromTokenAddress(SOLO, address(want));


        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](1);

        operations[0] = _getDepositAction(marketId, depositAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
     }

     function dydxWithdraw(uint256 amount) internal {
        ISoloMargin solo = ISoloMargin(SOLO);
        uint256 marketId = _getMarketIdFromTokenAddress(SOLO, address(want));

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](1);

        operations[0] = _getWithdrawAction(marketId, amount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);


     }


    /*
     * Perform any strategy unwinding or other calls necessary to capture
     * the "free return" this strategy has generated since the last time it's
     * core position(s) were adusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and should
     * be optimized to minimize losses as much as possible. It is okay to report
     * "no returns", however this will affect the credit limit extended to the
     * strategy and reduce it's overall position if lower than expected returns
     * are sustained for long periods of time.
     */
    function prepareReturn(uint256 _debtOutstanding) internal override returns (uint256 _profit) {
        //this accrues interest
        uint256 _bankBalance = dydxBalance();

        if (_bankBalance == 0) {
            //no position to harvest
            uint256 wantBalance = want.balanceOf(address(this));
            if(_debtOutstanding > wantBalance){
                setReserve(0);
            }else{
                setReserve(wantBalance.sub(_debtOutstanding));
            }

            return 0;
        }

        if (getReserve() != 0) {
            //reset reserve so it doesnt interfere anywhere else
            setReserve(0);
        }


        uint256 balanceInWant = want.balanceOf(address(this));
        uint256 total = _bankBalance.add(balanceInWant);

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if(total > debt){
            uint profit = total-debt;
            uint amountToFree = profit.add(_debtOutstanding);

            //we need to add outstanding to our profit
            if(balanceInWant >= amountToFree){
                setReserve(want.balanceOf(address(this)) - amountToFree);
            }else{
                //change profit to what we can withdraw
                _withdrawSome(amountToFree.sub(balanceInWant));
                balanceInWant = want.balanceOf(address(this));

                if(balanceInWant > amountToFree){
                    setReserve(balanceInWant - amountToFree);
                }else{
                    setReserve(0);
                }

            }

        } else {
            uint256 bal = want.balanceOf(address(this));
            if(bal <= _debtOutstanding){
                     setReserve(0);
            }else{
                setReserve(bal - _debtOutstanding);
            }
        }

        return want.balanceOf(address(this)) - getReserve();

    }

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        //we did state changing call in prepare return so this will be accurate
        uint liquidity = dydxLiquidity();

        if(liquidity == 0){
            return;
        }

        uint wantBalance = want.balanceOf(address(this));

        uint256 toKeep = 0;

        //to keep is the amount we need to hold to make the liqudity cushion full
        if(liquidity < liquidityCushion){
            toKeep = liquidityCushion.sub(liquidity);
        }
        toKeep = toKeep.add(_debtOutstanding);
        //if we have more than enough weth then invest the extra
        if(wantBalance > toKeep){

            uint toInvest = wantBalance.sub(toKeep);

            //mint
            dydxDeposit(toInvest);

        }else if(wantBalance < toKeep){
            //free up the difference if we can
            uint toWithdraw = toKeep.sub(wantBalance);

            _withdrawSome(toWithdraw);
        }
    }

    function _withdrawSome(uint256 _amount) internal returns(uint256 amountWithdrawn) {

        //state changing
        uint balance = dydxBalance();
        if(_amount > balance) {
            //cant withdraw more than we own
            _amount = balance;
        }

        //not state changing but OK because of previous call
        uint liquidity = dydxLiquidity();
        amountWithdrawn = 0;
        if(liquidity == 0) {
            return amountWithdrawn;
        }

        if(_amount <= liquidity) {
            amountWithdrawn = _amount;
            //we can take all
            dydxWithdraw(amountWithdrawn);
        } else {
            //take all we can
            dydxWithdraw(amountWithdrawn);
        }

    }

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed, since when this method is called the strategist is no longer receiving
     * their performance fee. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`
     */
    function exitPosition() internal override {
        uint balance = dydxBalance();
        if(balance > 0){
            _withdrawSome(balance);
        }
        setReserve(0);
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed) {
         uint256 _balance = want.balanceOf(address(this));

        if(_balance >= _amountNeeded){
            //if we don't set reserve here withdrawer will be sent our full balance
            setReserve(_balance.sub(_amountNeeded));
            return _amountNeeded;
        }else{
            uint received = _withdrawSome(_amountNeeded - _balance).add(_balance);
            if(received > _amountNeeded){
                return  _amountNeeded;
            }else{
                return received;
            }

        }
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary

    /*
     * Do anything necesseary to prepare this strategy for migration, such
     * as transfering any reserve or LP tokens, CDPs, or other tokens or stores of value.
     */
    function prepareMigration(address _newStrategy) internal override {
        exitPosition();
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistant* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getMarketIdFromTokenAddress(address _solo, address token) internal view returns (uint256) {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert("No marketId found for provided token");
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 0});
    }
}
