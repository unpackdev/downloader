//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./IFirstDibsMarketSettingsV2.sol";

contract FirstDibsMarketSettingsV2 is Ownable, IFirstDibsMarketSettingsV2 {
    // default buyer's premium (price paid by buyer above winning bid)
    uint32 public override globalBuyerPremium;

    // default commission for auction admin (1stDibs)
    uint32 public override globalMarketCommission;

    // 10% min bid increment
    uint32 public override globalMinimumBidIncrement;

    // default global auction time buffer (if bid is made in last 15 min,
    // extend auction another 15 min)
    uint32 public override globalTimeBuffer;

    // default global auction duration (24 hours)
    uint32 public override globalAuctionDuration;

    // address of the auction admin (1stDibs)
    address public override commissionAddress;

    constructor(address _commissionAddress) {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );
        globalTimeBuffer = 15 * 60;
        globalAuctionDuration = 24 * 60 * 60;
        commissionAddress = _commissionAddress; // receiver address for auction admin (globalMarketplaceCommission gets sent here)
        globalBuyerPremium = 300;
        globalMarketCommission = 500;
        globalMinimumBidIncrement = 1000;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, 'Value must be greater than zero');
        _;
    }

    /**
     * @dev Modifier used to ensure passed value is <= 10000. Handy to validate RBS values.
     * @param _value uint256 to validate
     */
    modifier lte10000(uint256 _value) {
        require(_value <= 10000, 'Value must be <= 10000');
        _;
    }

    /**
     * @dev setter for global auction admin
     * @param _commissionAddress address of the global auction admin (1stDibs wallet)
     */
    function setCommissionAddress(address _commissionAddress) external onlyOwner {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );
        commissionAddress = _commissionAddress;
    }

    /**
     * @dev setter for global time buffer
     * @param _timeBuffer new time buffer in seconds
     */
    function setGlobalTimeBuffer(uint32 _timeBuffer) external onlyOwner nonZero(_timeBuffer) {
        globalTimeBuffer = _timeBuffer;
    }

    /**
     * @dev setter for global auction duration
     * @param _auctionDuration new auction duration in seconds
     */
    function setGlobalAuctionDuration(uint32 _auctionDuration)
        external
        onlyOwner
        nonZero(_auctionDuration)
    {
        globalAuctionDuration = _auctionDuration;
    }

    /**
     * @dev setter for global buyer premium
     * @param _buyerPremium new buyer premium percent
     */
    function setGlobalBuyerPremium(uint32 _buyerPremium) external onlyOwner {
        globalBuyerPremium = _buyerPremium;
    }

    /**
     * @dev setter for global market commission rate
     * @param _marketCommission new market commission rate
     */
    function setGlobalMarketCommission(uint32 _marketCommission)
        external
        onlyOwner
        lte10000(_marketCommission)
    {
        require(_marketCommission >= 300, 'Market commission cannot be lower than 3%');
        globalMarketCommission = _marketCommission;
    }

    /**
     * @dev setter for global minimum bid increment
     * @param _bidIncrement new minimum bid increment
     */
    function setGlobalMinimumBidIncrement(uint32 _bidIncrement)
        external
        onlyOwner
        nonZero(_bidIncrement)
    {
        globalMinimumBidIncrement = _bidIncrement;
    }
}
