pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./UniversalERC20.sol";
import "./ISwitchEvent.sol";
import "./IFeeCollector.sol";

contract BaseTrade is Ownable {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    ISwitchEvent public switchEvent;
    address public feeCollector;
    uint256 public maxPartnerFeeRate = 1000; // max partner fee rate is 10%
    uint256 public defaultSwingCut = 1500; // swing takes a cut of 15% from partner fee by default
    uint256 public constant FEE_BASE = 10000;

    event MaxPartnerFeeRateSet(uint256 maxPartnerFeeRate);
    event SwingCutSet(uint256 swingCut);
    event PartnerFeeSet(address partner, uint256 feeRate);
    event SwitchEventSet(ISwitchEvent switchEvent);
    event DefaultSwingCutSet(uint256 defaultSwingCut);

    constructor(
        address _switchEventAddress,
        address _feeCollector
    )
    public
    {
        switchEvent = ISwitchEvent(_switchEventAddress);
        feeCollector = _feeCollector;
    }

    function setMaxPartnerFeeRate(uint256 _maxPartnerFeeRate) external onlyOwner {
        require(_maxPartnerFeeRate <= 5000, "too large");
        maxPartnerFeeRate = _maxPartnerFeeRate;
        emit MaxPartnerFeeRateSet(_maxPartnerFeeRate);
    }

    function setSwitchEvent(ISwitchEvent _switchEvent) external onlyOwner {
        switchEvent = _switchEvent;
        emit SwitchEventSet(_switchEvent);
    }

    function setSwingCut(uint256 _defaultSwingCut) external onlyOwner {
        defaultSwingCut = _defaultSwingCut;
        emit DefaultSwingCutSet(_defaultSwingCut);
    }

    function getFeeInfo(
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
    public
    view
    returns (
        uint256 partnerFee,
        uint256 remainAmount
    )
    {
        partnerFee = partnerFeeRate * amount / FEE_BASE;
        remainAmount = amount - partnerFee;
    }

    function _getAmountAfterFee(
        IERC20 token,
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
    internal
    returns (
        uint256 amountAfterFee
    )
    {
        require(partnerFeeRate <= maxPartnerFeeRate, "partnerFeeRate too large");
        amountAfterFee = amount;
        if (partnerFeeRate > 0) {
            uint256 swingCut = IFeeCollector(feeCollector).getPartnerSwingCut(partner) == 0 ? defaultSwingCut : IFeeCollector(feeCollector).getPartnerSwingCut(partner);
            uint256 swingFee = partnerFeeRate * amount * swingCut / (FEE_BASE * FEE_BASE);
            uint256 partnerFee = partnerFeeRate * amount / FEE_BASE - swingFee;
            if (token.isETH()) {
                IFeeCollector(feeCollector).collectTokenFees{ value: partnerFee + swingFee }(
                    address(token),
                    partnerFee,
                    swingFee,
                    partner
                );
            } else {
                token.safeApprove(feeCollector, 0);
                token.safeApprove(feeCollector, partnerFee + swingFee);
                IFeeCollector(feeCollector).collectTokenFees(address(token), partnerFee, swingFee, partner);
            }
            amountAfterFee = amount - partnerFeeRate * amount / FEE_BASE;
        }
    }
}