// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibBidderQueue.sol";
import "./LibGetters.sol";
import "./LibRoundToken.sol";
import "./LibTradingFee.sol";
import "./Modifiers.sol";
import "./IPilgrimMetaNFT.sol";

import "./INonfungiblePositionManager.sol";

import "./IERC20.sol";
import "./IERC721.sol";

import "./console.sol";

/// @title  Listing Facet
///
/// @author Test-in-Prod.
///
/// @notice The facet contract for the core to trade NFTs and MetaNFTs.
///
contract ListingFacet is Modifiers {
    AppStorage internal s;

    /// @notice The List NFT Event.
    ///
    /// @param  _nftAddress ERC-721 contract address.
    /// @param  _tokenId    NFT Identifier.
    /// @param  _version    The version of the NFT pair.
    /// @param  _metaNftId  Meta NFT Identifier.
    /// @param  _tags       A string array of NFT tags.
    ///
    event List(address _nftAddress, uint256 _tokenId, uint256 _version, uint256 _metaNftId, string[] _tags);

    /// @notice The Delist NFT Event.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _sender     The address of the sender.
    /// @param  _amountIn   The amount of base tokens into the pool.
    ///
    event Delist(uint256 _metaNftId, address indexed _sender, uint128 _amountIn);

    /// @notice The Refund Round Token Event.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _sender     The address of the sender.
    /// @param  _amountIn   The amount of round tokens into the pool.
    /// @param  _amountOut  The amount of base tokens out from the pool.
    ///
    event Refund(uint256 _metaNftId, address indexed _sender, uint128 _amountIn, uint128 _amountOut);

    /// @notice The Bid NFT Event.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _sender     The address of the sender.
    /// @param  _amountIn   The amount of base tokens into the pool
    /// @param  _expiry     The expiry time in epoch.
    /// @param  _isNft      True if the bid is for NFT buyout.
    ///
    event Bid(uint256 _metaNftId, address indexed _sender, uint128 _amountIn, uint64 _expiry, bool _isNft);

    /// @notice The Unbid NFT Event.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _sender     The address of the sender.
    /// @param  _amountOut  The amount of base tokens out from the pool.
    /// @param  _isNft      True if the bid is for NFT buyout.
    ///
    event Unbid(uint256 _metaNftId, address indexed _sender, uint128 _amountOut, bool _isNft);

    /// @notice The Accept Event.
    ///
    /// @param  _metaNftId          The pair identifier.
    /// @param  _sender             The address of the sender.
    /// @param  _amountOut          The amount of base tokens out from the pool.
    /// @param  _amountToRHolderPR  The amount of base tokens to receive per round token.
    /// @param  _bidder             The address of the bidder.
    ///
    event Accept(uint256 _metaNftId, address indexed _sender, uint128 _amountOut, uint128 _amountToRHolderPR, address _bidder);

    function _getBaseReserve(PairInfo storage _pairInfo) private view returns (uint256 _baseReserve) {
        _baseReserve = uint256(_pairInfo.actualBaseReserve + _pairInfo.initBaseReserve + _pairInfo.mintBaseReserve);
    }

    function _quoteNft(uint256 _metaNftId) private view returns (
        uint128 _amountIn,
        uint128 _amountToMNftHolder,
        uint128 _amountToRHolderPR
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);

        /// f_m(y_init)
        uint128 actualBaseReserve = pairInfo.actualBaseReserve;

        /// g_m(y_init)
        uint128 baseReserve = actualBaseReserve + pairInfo.initBaseReserve + pairInfo.mintBaseReserve;

        /// x + nk
        uint128 totalSupply = pairInfo.roundTotalSupply;

        /// n * k
        uint128 amountRoundMinted = totalSupply - INITIAL_ROUNDS;

        /// E_T = (x + nk) * g_m(y_init) / x
        _amountIn = uint128(uint256(totalSupply) * baseReserve / INITIAL_ROUNDS);

        /// C_n = (E_T - g_m(y_init)) / nk
        uint256 pricePerRound;
        if (amountRoundMinted == 0) {
            pricePerRound = uint256(baseReserve) * 1 ether / INITIAL_ROUNDS;
        }
        else {
            pricePerRound = uint256(_amountIn - baseReserve) * 1 ether / amountRoundMinted;
        }
        _amountToRHolderPR = uint128(pricePerRound);

        /// E_B = E_T + f_m(y_init) - C_n * nk
        _amountToMNftHolder = uint128(_amountIn + actualBaseReserve - pricePerRound * amountRoundMinted / 1 ether);
    }

    /// @notice Quotes the NFT and the refund to relevant stakeholders.
    ///
    /// @param  _metaNftId          The pair identifier.
    ///
    /// @return _amountIn           The amount of base tokens needed to purchase.
    /// @return _amountToMNftHolder The amount of base tokens the Meta NFT holder may receive.
    /// @return _amountToRHolderPR  The amount of base tokens a round token holder may receive.
    ///
    function quoteNft(
        uint256 _metaNftId
    ) public view listed(_metaNftId) returns (
        uint128 _amountIn,
        uint128 _amountToMNftHolder,
        uint128 _amountToRHolderPR
    ) {
        (_amountIn, _amountToMNftHolder, _amountToRHolderPR) = _quoteNft(_metaNftId);
        _amountIn += LibTradingFee._calculateNftFeeInverse(_amountIn);
    }

    /// @notice Quotes the Meta NFT.
    ///
    /// @param  _metaNftId  The pair identifier.
    ///
    /// @return _amountIn   The amount of base tokens needed to purchase.
    ///
    function quoteMetaNft(uint256 _metaNftId) public view listed(_metaNftId) returns (uint128 _amountIn) {
        (, _amountIn,) = _quoteNft(_metaNftId);
        _amountIn += LibTradingFee._calculateNftFeeInverse(_amountIn);
    }

    /// @notice Quotes the cost of delisting the Pair.
    ///
    /// @param  _metaNftId  The pair identifier.
    ///
    /// @return _amountIn   The amount of base tokens needed to delist.
    ///
    function quoteDelist(uint256 _metaNftId) public view listed(_metaNftId) returns (uint128 _amountIn) {
        (uint128 nftPrice, uint128 amountToMNftHolder,) = _quoteNft(_metaNftId);
        _amountIn = nftPrice - amountToMNftHolder;
        _amountIn += LibTradingFee._calculateNftFeeInverse(_amountIn);
    }

    /// @notice Quotes the delisted round tokens.
    ///
    /// @param  _metaNftId The pair identifier.
    ///
    /// @return _price  The price of a single round token.
    ///
    function quoteRefundRoundTokens(uint256 _metaNftId) public view delisted(_metaNftId) returns (uint128 _price) {
        (, , _price) = _quoteNft(_metaNftId);
    }

    /// @notice List a new NFT (Pilgrim Pair).
    ///
    /// @param  _nftAddress         ERC-721 contract address.
    /// @param  _tokenId            NFT Identifier.
    /// @param  _initPrice          The initial price of a signle round token.
    /// @param  _baseToken          Base token address.
    /// @param  _tags               A string of NFT tags.
    /// @param  _descriptionHash    An IPFS hash of the pair decription text
    ///
    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice,
        address _baseToken,
        string[] calldata _tags,
        bytes32 _descriptionHash
    ) external {
        require(_initPrice > 0, "Pilgrim: ZERO_INIT_PRICE");
        require(_nftAddress != address(0), "Pilgrim: ZERO_ADDRESS");
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        /// Valid base token must have a distribution pool with positive rewardParameter.
        require(s.distPools[_baseToken].rewardParameter > 0, "Pilgrim: INVALID_BASE_TOKEN");

        IPilgrimMetaNFT metaNFT = IPilgrimMetaNFT(s.metaNFT);
        uint256 metaNftId = metaNFT.safeMint(msg.sender);

        uint256[] storage pairVersions = s.metaNftIds[_nftAddress][_tokenId];
        pairVersions.push(metaNftId);
        uint32 version = uint32(pairVersions.length - 1);

        PairInfo storage pairInfo = s.pairs[metaNftId];
        pairInfo.nftAddress = _nftAddress;
        pairInfo.tokenId = _tokenId;
        pairInfo.version = version;
        pairInfo.metaNftId = metaNftId;
        pairInfo.baseToken = _baseToken;
        pairInfo.descriptionHash = _descriptionHash;
        pairInfo.initBaseReserve = _initPrice * (INITIAL_ROUNDS / 1 ether);

        pairInfo.roundTotalSupply += INITIAL_ROUNDS;
        pairInfo.roundBalanceOf[address(this)] += INITIAL_ROUNDS;

        pairInfo.activated = true;

        LibBidderQueue._init(pairInfo.nftQueue);
        LibBidderQueue._init(pairInfo.metaNftQueue);

        if (_nftAddress == s.uniV3Pos) {
            (,,address token0, address token1,,,,,,,,) = INonfungiblePositionManager(s.uniV3Pos).positions(_tokenId);
            pairInfo.extraRewardParameter = LibGetters._getUniV3ExtraRewardParam(token0, token1);
        }
        if (pairInfo.extraRewardParameter == 0) {
            pairInfo.extraRewardParameter = 1;
        }

        for (uint256 i = 0; i < _tags.length; i++) {
            pairInfo.tags.push(_tags[i]);
        }

        emit List(_nftAddress, _tokenId, version, metaNftId, _tags);
    }

    /// @notice Delists the Pair by the Meta NFT holder. The holder has to pay back the round holders and receives the
    ///         NFT back.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _maxAmountIn    The amount of base tokens willing to pay.
    /// @param  _deadline       The Unix timestamp that this transaction needs to complete. The transaction reverts
    ///                         past this time.
    ///
    /// @return _amountInFinal  The final amount of base tokens spent for the transaction.
    ///
    function delist(
        uint256 _metaNftId,
        uint128 _maxAmountIn,
        uint64 _deadline
    ) external ensure(_deadline) lockOuter(_metaNftId) listed(_metaNftId) onlyOneBlock returns (
        uint128 _amountInFinal
    ) {
        IPilgrimMetaNFT metaNft = IPilgrimMetaNFT(s.metaNFT);
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);

        require(msg.sender == metaNft.ownerOf(pairInfo.metaNftId));
        _amountInFinal = quoteDelist(_metaNftId);
        uint128 fee = LibTradingFee._calculateNftFee(_amountInFinal);

        /// It's caller's requirement
        require(_amountInFinal <= _maxAmountIn);

        uint256 beforeBalance = IERC20(pairInfo.baseToken).balanceOf(address(this));

        /// Transfer the base tokens from the caller to the contract
        require(IERC20(pairInfo.baseToken).transferFrom(msg.sender, address(this), _amountInFinal));

        /// Check whether balance is as expected.
        require(beforeBalance + _amountInFinal == IERC20(pairInfo.baseToken).balanceOf(address(this)));

        /// Transfer trading fee to the staking contract
        s.cumulativeFees[pairInfo.baseToken] += fee;

        /// Deactivate the pair
        pairInfo.activated = false;

        /// Burn the MetaNFT token
        metaNft.burn(pairInfo.metaNftId);

        /// Transfer the ownership of the NFT token
        IERC721(pairInfo.nftAddress).safeTransferFrom(address(this), msg.sender, pairInfo.tokenId);

        /// Emit the event
        emit Delist(pairInfo.metaNftId, msg.sender, _amountInFinal);
    }

    /// @notice Receives base tokens in return for round tokens (when the Pair is deactivated).
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _deadline       The Unix timestamp that this transaction needs to complete. The transaction reverts
    ///                         past this time.
    ///
    /// @return _amountOutFinal The final amount of base tokens refunded.
    ///
    function refundRoundTokens(
        uint256 _metaNftId,
        uint64 _deadline
    ) external ensure(_deadline) lockOuter(_metaNftId) delisted(_metaNftId) onlyOneBlock returns (
        uint128 _amountOutFinal
    ) {
        /// Compute the amount out
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        uint128 roundsMinted = pairInfo.roundTotalSupply - INITIAL_ROUNDS;
        uint128 userRounds = pairInfo.roundBalanceOf[msg.sender];

        require(roundsMinted > 0);
        _amountOutFinal =  uint128(quoteRefundRoundTokens(_metaNftId) * userRounds / 1 ether);
        require(_amountOutFinal > 0);

        /// Burn the amount in
        LibRoundToken._burn(_metaNftId, msg.sender, userRounds);

        /// Refund the caller
        require(IERC20(pairInfo.baseToken).transfer(msg.sender, _amountOutFinal));

        /// Emit the event
        emit Refund(pairInfo.metaNftId, msg.sender, userRounds, _amountOutFinal);
    }

    function _getValidBidder(
        uint256 _metaNftId,
        uint128 _minAmountValid,
        bool _isNft
    ) internal view returns (
        address _bidder
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        BidderQueue storage queue = _isNft ? pairInfo.nftQueue : pairInfo.metaNftQueue;
        mapping(address => BidInfo) storage bidInfo = _isNft ? pairInfo.nftInfo : pairInfo.metaNftInfo;
        for(uint128 i = 0; i < LibBidderQueue._size(queue); i++) {
            (address bidder, uint256 timeout) = LibBidderQueue._get(queue, i);
            if(timeout >= block.timestamp && _minAmountValid <= bidInfo[bidder].amount && bidInfo[bidder].bidded) {
                _bidder = bidder;
                break;
            }
        }
    }

    function _poll(
        uint256 _metaNftId,
        bool _isNft
    ) private view listed(_metaNftId) returns (
        address _bidder,
        uint128 _amountIn
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        uint128 validAmountIn;
        mapping(address => BidInfo) storage bidInfo = _isNft ? pairInfo.nftInfo : pairInfo.metaNftInfo;
        if(_isNft) {
            (validAmountIn, ,) = quoteNft(_metaNftId);
        } else {
            validAmountIn = quoteMetaNft(_metaNftId);
        }
        _bidder = _getValidBidder(_metaNftId, validAmountIn, _isNft);
        _amountIn = bidInfo[_bidder].amount;
    }

    /// @notice Polls the first valid NFT bid.
    ///
    /// @param  _metaNftId     The pair identifier.
    ///
    /// @return _bidder     The address of the bidder.
    /// @return _amountIn   The amount of base tokens bidded.
    ///
    function pollNftBid(uint256 _metaNftId) external view returns (address _bidder, uint128 _amountIn) {
        return _poll(_metaNftId, true);
    }

    /// @notice Polls the first valid Meta NFT bid.
    ///
    /// @param  _metaNftId     The pair identifier.
    ///
    /// @return _bidder     The address of the bidder.
    /// @return _amountIn   The amount of base tokens bidded.
    ///
    function pollMetaNftBid(uint256 _metaNftId) external view returns (address _bidder, uint128 _amountIn) {
        return _poll(_metaNftId, false);
    }

    struct _BidArgs {
        uint256 _metaNftId;
        uint128 _amountIn;
        uint64 _deadline;
        bool _isNft;
    }

    function _bid(
        _BidArgs memory _bidArgs
    ) private ensure(_bidArgs._deadline) lockOuter(_bidArgs._metaNftId) listed(_bidArgs._metaNftId) returns (
        uint64 _expiry
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_bidArgs._metaNftId);
        require(msg.sender != IPilgrimMetaNFT(s.metaNFT).ownerOf(pairInfo.metaNftId));

        mapping(address => BidInfo) storage bidInfo = _bidArgs._isNft ? pairInfo.nftInfo : pairInfo.metaNftInfo;

        if(_bidArgs._isNft) {
            uint128 minAmountIn;
            (minAmountIn,,) = quoteNft(_bidArgs._metaNftId);
            require(minAmountIn <= _bidArgs._amountIn);
            _expiry = LibBidderQueue._enqueue(pairInfo.nftQueue, msg.sender);
        } else {
            uint128 minAmountIn;
            minAmountIn = quoteMetaNft(_bidArgs._metaNftId);
            require(minAmountIn <= _bidArgs._amountIn);
            _expiry = LibBidderQueue._enqueue(pairInfo.metaNftQueue, msg.sender);
        }

        require(!bidInfo[msg.sender].bidded);
        uint256 beforeBalance = IERC20(pairInfo.baseToken).balanceOf(address(this));
        require(IERC20(pairInfo.baseToken).transferFrom(msg.sender, address(this), _bidArgs._amountIn));
        require(beforeBalance + _bidArgs._amountIn == IERC20(pairInfo.baseToken).balanceOf(address(this)));

        bidInfo[msg.sender] = BidInfo(true, bidInfo[msg.sender].amount + _bidArgs._amountIn);
        pairInfo.bidBaseReserve += _bidArgs._amountIn;

        /// Emit the event
        emit Bid(pairInfo.metaNftId, msg.sender, _bidArgs._amountIn, _expiry, _bidArgs._isNft);
    }

    /// @notice Bids for the NFT the Pair represents. The bidder can unbid and retrieve bidded tokens back once the bid
    ///         has expired.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _amountIn   The amount of base tokens to bid.
    /// @param  _deadline   The Unix timestamp that this transaction needs to complete. The transaction reverts past
    ///                     this time.
    ///
    /// @return _expiry     The expiry of the bid in Unix timestamp.
    ///
    function bidNft(uint256 _metaNftId, uint128 _amountIn, uint64 _deadline) external onlyOneBlock returns (uint64 _expiry) {
        _expiry = _bid(_BidArgs(_metaNftId, _amountIn, _deadline, true));
    }

    /// @notice Bids for the Meta NFT the Pair represents. The bidder can unbid and retrieve bidded tokens back once
    ///         the bid has expired.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _amountIn   The amount of base tokens to bid.
    /// @param  _deadline   The Unix timestamp that this transaction needs to complete. The transaction reverts past
    ///                     this time.
    ///
    /// @return _expiry     The expiry of the bid in Unix timestamp.
    ///
    function bidMetaNft(uint256 _metaNftId, uint128 _amountIn, uint64 _deadline) external onlyOneBlock returns (uint64 _expiry) {
        _expiry = _bid(_BidArgs(_metaNftId, _amountIn, _deadline, false));
    }

    function _dequeueExpired(uint256 _metaNftId, bool _isNft) internal {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        BidderQueue storage queue = _isNft ? pairInfo.nftQueue : pairInfo.metaNftQueue;
        mapping(address => BidInfo) storage bidInfo = _isNft ? pairInfo.nftInfo : pairInfo.metaNftInfo;

        while(!LibBidderQueue._isEmpty(queue)) {
            (address bidder, uint256 timeOut) = LibBidderQueue._peek(queue);
            if(timeOut >= block.timestamp) {
                break;
            }
            LibBidderQueue._dequeue(queue);
            bidInfo[bidder].bidded = false;
        }
    }

    function _unbid(
        uint256 _metaNftId,
        uint64 _deadline,
        bool _isNft
    ) private ensure(_deadline) lockOuter(_metaNftId) returns (uint128 _amountOut) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        mapping(address => BidInfo) storage bidInfo = _isNft ? pairInfo.nftInfo : pairInfo.metaNftInfo;
        _amountOut = bidInfo[msg.sender].amount;

        _dequeueExpired(_metaNftId, _isNft);
        require(!pairInfo.activated || (!bidInfo[msg.sender].bidded && _amountOut > 0));
        delete bidInfo[msg.sender];
        pairInfo.bidBaseReserve -= _amountOut;
        require(IERC20(pairInfo.baseToken).transfer(msg.sender, _amountOut));

        /// Emit the event
        emit Unbid(pairInfo.metaNftId, msg.sender, _amountOut, _isNft);
    }

    /// @notice Unbids sender's expired NFT bid to receive refund.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _deadline   The Unix timestamp that this transaction needs to complete. The transaction reverts past
    ///                     this time.
    ///
    /// @return _amountOut  The amount of base tokens refunded.
    ///
    function unbidNft(uint256 _metaNftId, uint64 _deadline) external returns (uint128 _amountOut) {
        _amountOut = _unbid(_metaNftId, _deadline, true);
    }

    /// @notice Unbids sender's expired Meta NFT bid to receive refund.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _deadline   The Unix timestamp that this transaction needs to complete. The transaction reverts past
    ///                     this time.
    ///
    /// @return _amountOut  The amount of base tokens refunded.
    ///
    function unbidMetaNft(uint256 _metaNftId, uint64 _deadline) external returns (uint128 _amountOut) {
        _amountOut = _unbid(_metaNftId, _deadline, false);
    }

    struct _AcceptVars {
        address bidder;
        uint128 amountIn;
        uint128 minAmountIn;
        uint128 amountToMNftHolder;
    }

    function _accept(
        uint256 _metaNftId,
        uint128 _minAmountOut,
        uint64 _deadline,
        bool _isNft
    ) private ensure(_deadline) lockOuter(_metaNftId) listed(_metaNftId) returns (
        uint128 _amountOut,
        uint128 _amountToRHolderPR
    ) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        _AcceptVars memory acceptVars;
        require(msg.sender == IPilgrimMetaNFT(s.metaNFT).ownerOf(pairInfo.metaNftId));

        _dequeueExpired(_metaNftId, _isNft);
        (acceptVars.bidder, acceptVars.amountIn) = _poll(_metaNftId, _isNft);
        require(acceptVars.bidder != address(0));

        uint128 fee;
        if(_isNft) {
            (acceptVars.minAmountIn, acceptVars.amountToMNftHolder, _amountToRHolderPR) = quoteNft(_metaNftId);
            fee = LibTradingFee._calculateNftFee(acceptVars.minAmountIn);
            _amountOut = acceptVars.amountToMNftHolder;
        } else {
            acceptVars.minAmountIn = quoteMetaNft(_metaNftId);
            fee = LibTradingFee._calculateNftFee(acceptVars.minAmountIn);
            _amountOut = acceptVars.minAmountIn - fee;
        }

        /// It's caller's requirment
        require(acceptVars.minAmountIn <= acceptVars.amountIn);
        require(_amountOut >= _minAmountOut);

        if(_isNft) {
            /// Unbid the bidder
            pairInfo.nftInfo[acceptVars.bidder].bidded = false;
            pairInfo.nftInfo[acceptVars.bidder].amount -= acceptVars.minAmountIn;

            /// Deactivate the pair
            pairInfo.activated = false;

            /// Burn the MetaNFT token
            IPilgrimMetaNFT metaNft = IPilgrimMetaNFT(s.metaNFT);
            metaNft.transferFrom(msg.sender, address(this), pairInfo.metaNftId);
            metaNft.burn(pairInfo.metaNftId);

            /// Transfer the ownership of the NFT token
            IERC721(pairInfo.nftAddress).safeTransferFrom(address(this), acceptVars.bidder, pairInfo.tokenId);
        } else {
            /// Unbid the bidder
            pairInfo.metaNftInfo[acceptVars.bidder].bidded = false;
            pairInfo.metaNftInfo[acceptVars.bidder].amount -= acceptVars.minAmountIn;

            /// Transfer the ownership of the Meta NFT token
            IPilgrimMetaNFT(s.metaNFT).safeTransferFrom(
                IPilgrimMetaNFT(s.metaNFT).ownerOf(pairInfo.metaNftId),
                acceptVars.bidder,
                pairInfo.metaNftId
            );
        }

        /// Transfer the base tokens from the contract to the Meta NFT holder
        pairInfo.bidBaseReserve -= acceptVars.amountIn;
        require(IERC20(pairInfo.baseToken).transfer(msg.sender, _amountOut));
        s.cumulativeFees[pairInfo.baseToken] += fee;

        /// Emit the event
        emit Accept(pairInfo.metaNftId, msg.sender, _amountOut, _amountToRHolderPR, acceptVars.bidder);
    }

    /// @notice Accepts the first valid NFT bid.
    ///
    /// @param  _metaNftId          The pair identifier.
    /// @param  _minAmountOut       The minimum amount of base tokens desired.
    /// @param  _deadline           The Unix timestamp that this transaction needs to complete. The transaction reverts
    ///                             past this time.
    ///
    /// @return _amountOut          The amount of base tokens received.
    /// @return _amountToRHolderPR  The amount of base tokens a round token holder will receive per round token.
    ///
    function acceptNftBid(
        uint256 _metaNftId,
        uint128 _minAmountOut,
        uint64 _deadline
    ) external returns (
        uint128 _amountOut,
        uint128 _amountToRHolderPR
    ) {
        return _accept(_metaNftId, _minAmountOut, _deadline, true);
    }

    /// @notice Accepts the first valid Meta NFT bid.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _minAmountOut   The minimum amount of base tokens desired.
    /// @param  _deadline       The Unix timestamp that this transaction needs to complete. The transaction reverts
    ///                         past this time.
    ///
    /// @return _amountOut      The amount of base tokens received.
    ///
    function acceptMetaNftBid(
        uint256 _metaNftId,
        uint128 _minAmountOut,
        uint64 _deadline
    ) external returns (
        uint128 _amountOut
    ) {
        (_amountOut,) = _accept(_metaNftId, _minAmountOut, _deadline, false);
    }

    /// @notice Update the pair description IPFS hash
    ///
    /// @param _metaNftId       The pair identifier
    /// @param _descriptionHash The pair description IPFS hash
    ///
    function updateDescriptionHash(
        uint256 _metaNftId,
        bytes32 _descriptionHash
    ) external {
        IPilgrimMetaNFT metaNft = IPilgrimMetaNFT(s.metaNFT);
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        require(msg.sender == metaNft.ownerOf(pairInfo.metaNftId), "Pilgrim: Must be pair owner");
        pairInfo.descriptionHash = _descriptionHash;
    }
}
