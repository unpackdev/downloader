//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IFirstDibsMarketSettings.sol";

contract FirstDibsMarketSettings is Ownable, IFirstDibsMarketSettings {
    // default buyer's premium (price paid by buyer above winning bid)
    uint32 public override globalBuyerPremium = 0;

    // default commission for auction admin (1stDibs)
    uint32 public override globalMarketCommission = 5;

    // default royalties to creators
    uint32 public override globalCreatorRoyaltyRate = 5;

    // 10% min bid increment
    uint32 public override globalMinimumBidIncrement = 10;

    // default global auction time buffer (if bid is made in last 15 min,
    // extend auction another 15 min)
    uint32 public override globalTimeBuffer = 15 * 60;

    // default global auction duration (24 hours)
    uint32 public override globalAuctionDuration = 24 * 60 * 60;

    // address of the auction admin (1stDibs)
    address public override commissionAddress;

    constructor(address _commissionAddress) public {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );

        commissionAddress = _commissionAddress; // receiver address for auction admin (globalMarketplaceCommission gets sent here)
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, 'Value must be greater than zero');
        _;
    }

    /**
     * @dev Modifier used to ensure passed value is <= 100. Handy to validate percent values.
     * @param _value uint256 to validate
     */
    modifier lte100(uint256 _value) {
        require(_value <= 100, 'Value must be <= 100');
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
        lte100(_marketCommission)
    {
        require(_marketCommission >= 3, 'Market commission cannot be lower than 3%');
        globalMarketCommission = _marketCommission;
    }

    /**5
     * @dev setter for global creator royalty rate
     * @param _royaltyRate new creator royalty rate
     */
    function setGlobalCreatorRoyaltyRate(uint32 _royaltyRate)
        external
        onlyOwner
        lte100(_royaltyRate)
    {
        require(_royaltyRate >= 2, 'Creator royalty cannot be lower than 2%');
        globalCreatorRoyaltyRate = _royaltyRate;
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
