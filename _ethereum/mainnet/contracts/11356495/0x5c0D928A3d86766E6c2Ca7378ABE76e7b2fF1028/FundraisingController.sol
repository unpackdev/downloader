pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./BatchedBancorMarketMaker.sol";
import "./ITap.sol";
import "./IFundraisingController.sol";


contract FundraisingController is Ownable {
    using SafeMath  for uint256;




    uint256 public constant TO_RESET_CAP = 10;

    BatchedBancorMarketMaker public marketMaker;
    ITap                     public tap;



    /***** external functions *****/

    /**
     * @notice Initialize Aragon Fundraising controller
     * @param _marketMaker The address of the market maker contract
     * @param _tap         The address of the tap contract
    */
    constructor (
        BatchedBancorMarketMaker _marketMaker,
        ITap _tap
    )
        public
    {
        marketMaker = _marketMaker;
        tap = _tap;
    }

    /* generic settings related function */

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary
    */
    function updateBeneficiary(address _beneficiary) public onlyOwner {
        marketMaker.updateBeneficiary(_beneficiary);
        tap.updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update fees deducted from buy and sell orders to respectively `@formatPct(_buyFeePct)`% and `@formatPct(_sellFeePct)`%
     * @param _buyFeePct  The new fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct The new fee to be deducted from sell orders [in PCT_BASE]
    */
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) public onlyOwner {
        marketMaker.updateFees(_buyFeePct, _sellFeePct);
    }


    /* market making related functions */


    /**
     * @notice Open a buy order worth `@tokenAmount(_collateral, _value)`
     * @param _collateral The address of the collateral token to be spent
     * @param _value      The amount of collateral token to be spent
    */
    function openBuyOrder(address _collateral, uint256 _value) public  {
        marketMaker.openBuyOrder(msg.sender, _collateral, _value);
    }

    /**
     * @notice Open a sell order worth `@tokenAmount(self.token(): address, _amount)` against `_collateral.symbol(): string`
     * @param _collateral The address of the collateral token to be returned
     * @param _amount     The amount of bonded token to be spent
    */
    function openSellOrder(address _collateral, uint256 _amount) public  {
        marketMaker.openSellOrder(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Claim the results of `_collateral.symbol(): string` buy orders from batch #`_batchId`
     * @param _buyer      The address of the user whose buy orders are to be claimed
     * @param _batchId    The id of the batch in which buy orders are to be claimed
     * @param _collateral The address of the collateral token against which buy orders are to be claimed
    */
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) public {
        marketMaker.claimBuyOrder(_buyer, _batchId, _collateral);
    }

    /**
     * @notice Claim the results of `_collateral.symbol(): string` sell orders from batch #`_batchId`
     * @param _seller     The address of the user whose sell orders are to be claimed
     * @param _batchId    The id of the batch in which sell orders are to be claimed
     * @param _collateral The address of the collateral token against which sell orders are to be claimed
    */
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) public {
        marketMaker.claimSellOrder(_seller, _batchId, _collateral);
    }

    /* collateral tokens related functions */

    /**
     * @notice Add `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
     * @param _rate           The rate at which that token is to be tapped [in wei / block]
     * @param _floor          The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage,
        uint256 _rate,
        uint256 _floor
    )
    	public
      onlyOwner
    {
        marketMaker.addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
        if (_rate > 0) {
            tap.addTappedToken(_collateral, _rate, _floor);
        }
    }

    /**
     * @notice Re-add `_collateral.symbol(): string` as a whitelisted collateral token [if it has been un-whitelisted in the past]
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
    */
    function reAddCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
    	public
      onlyOwner
    {
        marketMaker.addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /**
      * @notice Remove `_collateral.symbol(): string` as a whitelisted collateral token
      * @param _collateral The address of the collateral token to be un-whitelisted
    */
    function removeCollateralToken(address _collateral) public onlyOwner {
        marketMaker.removeCollateralToken(_collateral);
        // the token should still be tapped to avoid being locked
        // the token should still be protected to avoid being spent
    }

    /**
     * @notice Update `_collateral.symbol(): string` collateralization settings
     * @param _collateral     The address of the collateral token whose collateralization settings are to be updated
     * @param _virtualSupply  The new virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The new virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The new reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The new price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
    */
    function updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
        public
        onlyOwner
    {
        marketMaker.updateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /* tap related functions */

    /**
     * @notice Update maximum tap rate increase percentage to `@formatPct(_maximumTapRateIncreasePct)`%
     * @param _maximumTapRateIncreasePct The new maximum tap rate increase percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) public onlyOwner {
        tap.updateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    /**
     * @notice Update maximum tap floor decrease percentage to `@formatPct(_maximumTapFloorDecreasePct)`%
     * @param _maximumTapFloorDecreasePct The new maximum tap floor decrease percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) public onlyOwner {
        tap.updateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    /**
     * @notice Add tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token to be tapped
     * @param _rate  The rate at which that token is to be tapped [in wei / block]
     * @param _floor The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addTokenTap(address _token, uint256 _rate, uint256 _floor) public onlyOwner {
        tap.addTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Update tap for `_token.symbol(): string` with a rate of about `@tokenAmount(_token, 4 * 60 * 24 * 30 * _rate)` per month and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token whose tap is to be updated
     * @param _rate  The new rate at which that token is to be tapped [in wei / block]
     * @param _floor The new floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function updateTokenTap(address _token, uint256 _rate, uint256 _floor) public onlyOwner {
        tap.updateTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Update tapped amount for `_token.symbol(): string`
     * @param _token The address of the token whose tapped amount is to be updated
    */
    function updateTappedAmount(address _token) public {
        tap.updateTappedAmount(_token);
    }



    /***** public view functions *****/

    function token() public view returns (address) {
        return address(marketMaker.rewardToken());
    }


    function getMaximumWithdrawal(address _token) public view returns (uint256) {
        return tap.getMaximumWithdrawal(_token);
    }

    function collateralsToBeClaimed(address _collateral) public view  returns (uint256) {
        return marketMaker.collateralsToBeClaimed(_collateral);
    }

}
