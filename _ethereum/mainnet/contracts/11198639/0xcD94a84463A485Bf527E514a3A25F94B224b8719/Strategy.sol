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

import "./IWETH.sol";
import "./Bank.sol";


contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant bank = address(0x67B66C99D3Eb37Fa76Aa3Ed1ff33E8e39F0b9c7A);
    uint256 public liquidityCushion = 30 ether; // 30 ether ~ 1000 usd

    constructor(address _vault) public BaseStrategy(_vault) {
        // You can set these parameters on deployment to whatever you want
        // minReportDelay = 6300;
        // profitFactor = 100;
         debtThreshold = 1 gwei;
    }

    receive() external payable {}

    function setLiquidityCushion(uint256 _liquidityCushion) external {
        require(msg.sender == governance() || msg.sender == strategist, "!management"); // dev: not governance or strategist
        liquidityCushion = _liquidityCushion;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external override pure returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "StrategyAlphaHomoWeth";
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
        uint256 underlying = bankBalance();

        return want.balanceOf(address(this)).add(underlying);
    }

     function bankBalance() internal view returns (uint256 _profit) {
        Bank b = Bank(bank);
        return b.balanceOf(address(this)).mul(b.totalETH().add(b.pendingInterest(0))).div(b.totalSupply());
        //return b.debtShareToVal( b.balanceOf(address(this)));
     }

     function withdrawUnderlying(uint256 amount) internal  {
        Bank b = Bank(bank);

        uint256 shares = amount.mul(b.totalSupply()).div(b.totalETH());
        // uint256 shares = b.debtValToShare(amount);
        uint balance = b.balanceOf(address(this));
       if(shares > balance) {
            b.withdraw(balance);
       } else {
           b.withdraw(shares);
       }
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
        Bank(bank).deposit();
        uint256 _bankBalance = bankBalance();

        if (_bankBalance == 0) {
            //no position to harvest
            uint256 WethBalance = IWETH(weth).balanceOf(address(this));
            if(_debtOutstanding > WethBalance){
                setReserve(0);
            }else{
                setReserve(WethBalance.sub(_debtOutstanding));
            }

            return 0;
        }
        if (getReserve() != 0) {
            //reset reserve so it doesnt interfere anywhere else
            setReserve(0);
        }


        uint256 balanceInWeth = IWETH(weth).balanceOf(address(this));
        uint256 total = _bankBalance.add(balanceInWeth);

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if(total > debt){
            uint profit = total-debt;
            uint amountToFree = profit.add(_debtOutstanding);

            //we need to add outstanding to our profit
            if(balanceInWeth >= amountToFree){
                setReserve(IWETH(weth).balanceOf(address(this)) - amountToFree);
            }else{
                //change profit to what we can withdraw
                _withdrawSome(amountToFree.sub(balanceInWeth));
                balanceInWeth = IWETH(weth).balanceOf(address(this));

                if(balanceInWeth > amountToFree){
                    setReserve(balanceInWeth - amountToFree);
                }else{
                    setReserve(0);
                }

            }

        } else {
            uint256 bal = IWETH(weth).balanceOf(address(this));
            if(bal <= _debtOutstanding){
                     setReserve(0);
            }else{
                setReserve(bal - _debtOutstanding);
            }
        }

        return IWETH(weth).balanceOf(address(this)) - getReserve();

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
        uint liquidity = bank.balance;

        if(liquidity == 0){
            return;
        }

        uint wethBalance = IWETH(weth).balanceOf(address(this));

        uint256 toKeep = 0;

        //to keep is the amount we need to hold to make the liqudity cushion full
        if(liquidity < liquidityCushion){
            toKeep = liquidityCushion.sub(liquidity);
        }
        toKeep = toKeep.add(_debtOutstanding);
        //if we have more than enough weth then invest the extra
        if(wethBalance > toKeep){

            uint toInvest = wethBalance.sub(toKeep);

            //turn weth into eth first
            IWETH(weth).withdraw(toInvest);
            //mint
            Bank(bank).deposit{value: toInvest}();

        }else if(wethBalance < toKeep){
            //free up the difference if we can
            uint toWithdraw = toKeep.sub(wethBalance);

            _withdrawSome(toWithdraw);
        }
    }

    function _withdrawSome(uint256 _amount) internal returns(uint256 amountWithdrawn) {

        //state changing
        uint balance = bankBalance();
        if(_amount > balance) {
            //cant withdraw more than we own
            _amount = balance;
        }

        //not state changing but OK because of previous call
        uint liquidity = bank.balance;
        amountWithdrawn = 0;
        if(liquidity == 0) {
            return amountWithdrawn;
        }

        if(_amount <= liquidity) {
            amountWithdrawn = _amount;
            //we can take all
            withdrawUnderlying(amountWithdrawn);
        } else {
            //take all we can
            withdrawUnderlying(amountWithdrawn);
        }

        //in case we get back less than expected
        amountWithdrawn = address(this).balance;

        //remember to turn eth to weth
        IWETH(weth).deposit{value: amountWithdrawn}();
    }

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed, since when this method is called the strategist is no longer receiving
     * their performance fee. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`
     */
    function exitPosition() internal override {
        uint balance = bankBalance();
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
        Bank(bank).transfer(_newStrategy, Bank(bank).balanceOf(address(this)));
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
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(bank);
        return protected;
    }
}
