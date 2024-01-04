pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Crowdsale.sol";
import "./PausableCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./FinalizableCrowdsale.sol";

contract AdonxTokenSale is
    Ownable,
    Crowdsale,
    PausableCrowdsale,
    TimedCrowdsale,
    FinalizableCrowdsale
{
    // Track investor contributions

    mapping(address => uint256) contributions;

    uint256 private investorMinCap = 100000000000000000;

    // Token time lock
    uint256 private changeableRate;

    uint256 private startTime;
    uint256 private endTime;

    constructor(
        uint256 _rate,
        address payable _wallet,
        ERC20 _token,
        uint256 _openingTime, // opening time in unix epoch seconds
        uint256 _closingTime // closing time in unix epoch seconds
    )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_rate > 0);
        require(_wallet != address(0));

        changeableRate = _rate;
        startTime = _openingTime;
        endTime = _closingTime;
    }

    function setRate(uint256 newRate) public onlyOwner {
        changeableRate = newRate;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return changeableRate;
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(changeableRate);
    }

    function getMinPurchaseCap() public view returns (uint256) {
        return investorMinCap;
    }

    function updateMinPurchaseCap(uint256 _newMinCap) public onlyOwner {
        require(_newMinCap != investorMinCap, "");
        investorMinCap = _newMinCap;
    }

    function tokenBalance() public view returns (uint256) {
        return super.token().balanceOf(address(this));
    }

    function updateOpeningTime(uint256 _newOpeningTime) public onlyOwner {
        require(
            startTime != _newOpeningTime,
            "New unlock time should be differnt"
        );
        startTime = _newOpeningTime;
    }

    function updateClosingTime(uint256 _newClosingTime) public onlyOwner {
        require(
            endTime != _newClosingTime,
            "New unlock time should be differnt"
        );
        endTime = _newClosingTime;
    }

    function extendClosingTime(uint256 _newClosingTime) public onlyOwner {
        _extendTime(_newClosingTime);
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return startTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return endTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > endTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > endTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );

        emit TimedCrowdsaleExtended(endTime, newClosingTime);
        endTime = newClosingTime;
    }

    /**
     * @dev Returns the amount contributed so far by a sepecific user.
     * @param _beneficiary Address of contributor
     * @return User contribution so far
     */
    function getUserContribution(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return contributions[_beneficiary];
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(
            _weiAmount >= investorMinCap,
            "AdonxTokenSale: Amount is below minimum purchase requirement"
        );
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
    {
        super._updatePurchasingState(_beneficiary, _weiAmount);
        uint256 _contribution = contributions[_beneficiary];
        contributions[_beneficiary] = _contribution.add(_weiAmount);
    }

    /// @dev This will be invoked by the owner, when owner wants to rescue tokens
    function recoverTokens() public onlyOwner {
        super.token().safeTransfer(owner(), tokenBalance());
    }

    /**
     * @dev enables token transfers, called when owner calls finalize()
     */
    function finalization() public onlyOwner {
        recoverTokens();
        super._finalization();
    }
}
