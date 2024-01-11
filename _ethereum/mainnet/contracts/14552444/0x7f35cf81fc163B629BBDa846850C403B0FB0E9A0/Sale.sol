// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./FLYBYAccessControls.sol";
import "./SafeTransfer.sol";
import "./BoringBatchable.sol";
import "./BoringMath.sol";
import "./IPointList.sol";
import "./IFlybyMarket.sol";
import "./RedeemToken.sol";
import "./Ownable.sol";

// solhint-disable not-rely-on-time

contract Sale is IFlybyMarket, FLYBYAccessControls, BoringBatchable, SafeTransfer, Ownable, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using SafeERC20 for IERC20;

    /**
     * @notice FLYBYMarket template id for the factory contract.
     * @dev For different marketplace types, this must be incremented.
     */ 
    uint256 public constant override marketTemplate = 4;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant AUCTION_TOKEN_DECIMALS = 1e18;

    struct MarketPrice {
        uint128 rate;
        uint128 goal; 
    }
    MarketPrice public marketPrice;

    struct MarketInfo {
        uint256 startTime;
        uint256 endTime; 
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }
    MarketStatus public marketStatus;

    address public auctionToken;
    address payable public wallet;
    address public paymentCurrency;
    address public pointList;

    mapping(address => uint256) public commitments;
    mapping(address => uint256) public claimed;

    event AuctionTimeUpdated(uint256 startTime, uint256 endTime); 
    event AuctionPriceUpdated(uint256 rate, uint256 goal); 
    event AuctionWalletUpdated(address wallet); 
    event AddedCommitment(address addr, uint256 commitment);
    event AuctionFinalized();
    event AuctionCancelled();

    function initCrowdsale(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_startTime < 10000000000);
        require(_endTime < 10000000000);
        require(_startTime >= block.timestamp);
        require(_endTime > _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_admin != address(0));
        require(_totalTokens > 0);
        require(_goal > 0);
        require(IERC20(_token).decimals() == 18);
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0);
        }

        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);

        marketInfo.startTime = BoringMath.to128(_startTime);
        marketInfo.endTime = BoringMath.to128(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;

        initAccessControls(_admin);
        _setList(_pointList);
        _safeTransferFrom(_token, _funder, _totalTokens);
    }

    receive() external payable {
    }

    function commitEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    ) 
        public payable nonReentrant
    {
        require(paymentCurrency == ETH_ADDRESS, "Crowdsale: Payment currency is not ETH"); 
        require(readAndAgreedToMarketParticipationAgreement);
        
        uint256 ethToTransfer = calculateCommitment(msg.value);
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }
        
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }
    }

    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(_msgSender(), _amount, readAndAgreedToMarketParticipationAgreement);
    }

    function _getMinCommit() internal view returns (uint256) {
        uint8 decimalPaymentCurrency = IERC20(paymentCurrency).decimals();
        return 300 * 10 ** decimalPaymentCurrency;
    }

    function _getMaxCommit() internal view returns (uint256) {
        uint8 decimalPaymentCurrency = IERC20(paymentCurrency).decimals();
        return 9999 * 10 ** decimalPaymentCurrency;
    }
    
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) 
        public nonReentrant
    {
        require(_getMinCommit() <= _amount && _amount <= _getMaxCommit());
        require(readAndAgreedToMarketParticipationAgreement);
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, _msgSender(), tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
            if (marketInfo.totalTokens == _getTokenAmount(uint256(marketStatus.commitmentsTotal))) {
                marketInfo.endTime = block.timestamp;
            }
        }
    }

    function calculateCommitment(uint256 _commitment)
        public
        view
        returns (uint256 committed)
    {
        uint256 tokens = _getTokenAmount(_commitment);
        uint256 tokensCommited =_getTokenAmount(uint256(marketStatus.commitmentsTotal));
        if (tokensCommited.add(tokens) > uint256(marketInfo.totalTokens)) {
            return _getTokenPrice(uint256(marketInfo.totalTokens).sub(tokensCommited));
        }
        return _commitment;
    }

    /**
     * @notice Updates commitment of the buyer and the amount raised, emits an event.
     * @param _addr Recipient of the token purchase.
     * @param _commitment Value in wei or token involved in the purchase.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime));
        require(_addr != address(0));

        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (marketStatus.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }

        commitments[_addr] = newCommitment;        
        marketStatus.commitmentsTotal = BoringMath.to128(uint256(marketStatus.commitmentsTotal).add(_commitment));
        emit AddedCommitment(_addr, _commitment);
    }

    function withdrawTokens() public {
        withdrawTokens(payable(_msgSender()));
    }

    /**
     * @notice Approve tokens
     * @param addressToApprove Address approved
     * @param token Token Address
     * @param amount Amount of token
     */
    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), addressToApprove) < amount) {
            IERC20(token).approve(addressToApprove, amount);
        }
    }

    /**
     * @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address payable beneficiary) public nonReentrant {    
        if (auctionSuccessful()) {
            require(marketStatus.finalized);
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0); 
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
            commitments[beneficiary] = 0; 
            
            uint256 firstRedeemToken = tokensToClaim.mul(3).div(10);
            uint256 secondRedeemToken = tokensToClaim.mul(3).div(10);
            uint256 thirdRedeemToken = tokensToClaim.mul(2).div(10);
            uint256 fourthRedeemToken = tokensToClaim.mul(2).div(10);

            _safeTokenPayment(auctionToken, beneficiary, firstRedeemToken);
            approve(0x69Beb13BB6CF25F62b0cdbE91aaE2d3a7458559F, auctionToken, tokensToClaim - firstRedeemToken);
            
            RedeemToken(0x69Beb13BB6CF25F62b0cdbE91aaE2d3a7458559F).lockTokens(auctionToken, address(this), secondRedeemToken, marketInfo.endTime + 86400 * 30, beneficiary);
            RedeemToken(0x69Beb13BB6CF25F62b0cdbE91aaE2d3a7458559F).lockTokens(auctionToken, address(this), thirdRedeemToken, marketInfo.endTime + 86400 * 60, beneficiary);
            RedeemToken(0x69Beb13BB6CF25F62b0cdbE91aaE2d3a7458559F).lockTokens(auctionToken, address(this), fourthRedeemToken, marketInfo.endTime + 86400 * 90, beneficiary);
        } else {
            require(block.timestamp > uint256(marketInfo.endTime));
            uint256 accountBalance = commitments[beneficiary];
            commitments[beneficiary] = 0;
            _safeTokenPayment(paymentCurrency, beneficiary, accountBalance);
        }
    }

    /**
     * @notice Adjusts users commitment depending on amount already claimed and unclaimed tokens left.
     * @return claimerCommitment How many tokens the user is able to claim.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    /********************************
     *       Finalize Auction
     ********************************/
    
    /**
     * @notice Manually finalizes the Crowdsale.
     * @dev Must be called after crowdsale ends, to do some extra finalization work.
     * Calls the contracts finalization function.
     */
    function finalize() public nonReentrant {
        require(            
            hasAdminRole(_msgSender()) 
            || wallet == _msgSender()
            || hasSmartContractRole(_msgSender()) 
            || finalizeTimeExpired()
        );
        MarketStatus storage status = marketStatus;
        require(!status.finalized);
        MarketInfo storage info = marketInfo;
        require(auctionEnded()); 

        if (auctionSuccessful()) {
            _safeTokenPayment(paymentCurrency, wallet, uint256(status.commitmentsTotal));
            uint256 soldTokens = _getTokenAmount(uint256(status.commitmentsTotal));
            uint256 unsoldTokens = uint256(info.totalTokens).sub(soldTokens);

            if(unsoldTokens > 0) {
                _safeTokenPayment(auctionToken, wallet, unsoldTokens);
            }
        } else {
            _safeTokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        }

        status.finalized = true;
        emit AuctionFinalized();
    }

    /**********************************
     *     Other useful functions 
     **********************************/
    
    function tokenPrice() public view returns (uint256) {
        return uint256(marketPrice.rate); 
    }

    function _getTokenPrice(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(uint256(marketPrice.rate)).div(AUCTION_TOKEN_DECIMALS);   
    }

    function getTokenAmount(uint256 _amount) public view returns (uint256) {
        _getTokenAmount(_amount);
    }

    /**
     * @notice Calculates the number of tokens to purchase.
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _amount Value in wei or token to be converted into tokens.
     * @return tokenAmount Number of tokens that can be purchased with the specified amount.
     */
    function _getTokenAmount(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(AUCTION_TOKEN_DECIMALS).div(uint256(marketPrice.rate));
    }

    /**
     * @notice Checks if the sale is open.
     * @return isOpen True if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime);
    }

    /**
     * @notice Checks if the sale minimum amount was raised.
     * @return auctionSuccessful True if the commitmentsTotal is equal or higher than goal.
     */
    function auctionSuccessful() public view returns (bool) {
        return uint256(marketStatus.commitmentsTotal) >= uint256(marketPrice.goal);
    }

    /**
     * @notice Checks if the sale has ended.
     * @return auctionEnded True if sold out or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        return block.timestamp > uint256(marketInfo.endTime) || 
        _getTokenAmount(uint256(marketStatus.commitmentsTotal) + 1) >= uint256(marketInfo.totalTokens);
    }

    /**
     * @notice Checks if the sale has been finalised.
     * @return bool True if sale has been finalised.
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return True if 7 days have passed since the end of the auction
     */
    function finalizeTimeExpired() public view returns (bool) {
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    /******************************
     *        Point Lists
     ******************************/
    
    function setList(address _list) external {
        require(hasAdminRole(_msgSender()));
        _setList(_list);
    }

    function enableList(bool _status) external {
        require(hasAdminRole(_msgSender()));
        marketStatus.usePointList = _status;
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }
    }

    /******************************
     *       Setter Auction
     ******************************/

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(_msgSender()));
        require(_startTime < 10000000000);
        require(_endTime < 10000000000);
        require(_startTime >= block.timestamp);
        require(_endTime > _startTime);

        require(marketStatus.commitmentsTotal == 0);

        marketInfo.startTime = BoringMath.to128(_startTime);
        marketInfo.endTime = BoringMath.to128(_endTime);
        
        emit AuctionTimeUpdated(_startTime,_endTime);
    }

    /**
     * @notice Admin can set auction price through this function.
     * @param _rate Price per token.
     * @param _goal Minimum amount raised and goal for the auction.
     */
    function setAuctionPrice(uint256 _rate, uint256 _goal) external {
        require(hasAdminRole(_msgSender()));
        require(_goal > 0);
        require(_rate > 0);
        require(marketStatus.commitmentsTotal == 0);
        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);
        require(_getTokenAmount(_goal) <= uint256(marketInfo.totalTokens));

        emit AuctionPriceUpdated(_rate,_goal);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external onlyOwner {
        require(hasAdminRole(_msgSender()));
        require(_wallet != address(0));
        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    /*******************************
     *      Market Launchers
     *******************************/
    
    function init(bytes calldata _data) external override payable {}
    
    /**
     * @notice Decodes and hands Crowdsale data to the initCrowdsale function.
     * @param _data Encoded data for initialization.
     */
    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            address _paymentCurrency,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            uint256 _goal,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(_data, (
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            address
        ));

        initCrowdsale(_funder, _token, _paymentCurrency, _totalTokens, _startTime, _endTime, _rate, _goal, _admin, _pointList, _wallet);
    }

    function getCrowdsaleInitData(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    )
        external pure returns (bytes memory _data)
    {
        return abi.encode(
            _funder,
            _token,
            _paymentCurrency,
            _totalTokens,
            _startTime,
            _endTime,
            _rate,
            _goal,
            _admin,
            _pointList,
            _wallet
        );
    }

    function getBaseInformation() external view returns(
        address, 
        uint256,
        uint256,
        bool 
    ) {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

    function getTotalTokens() external view returns(uint256) {
        return uint256(marketInfo.totalTokens);
    }
}
