//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./console.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IPriceProvider.sol";
import "./IBackedPriceProvider.sol";
import "./console.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract Backed is Ownable {
    using SafeMath for uint256;

    uint256 constant BASE_PERCENT = 100 * 100;
    uint256 constant BASE_PRICE = 1e18;
    address constant BurnerAddress = 0x000000000000000000000000000000000000dEaD;

    enum Status {
        Offer, 
        ActivePolicy,
        CanceledOffer,
        TerminatedPolicy
    }

    enum ParticipantType {
        Insurer,
        Insured
    }

    struct OfferTerms {
        address asset; //Asset to insure. It must be ERC-20 compatible token
        address baseCurrency; //Base currency - Currency in which asset is priced. Usually it is an ERC-20 stablecoin , e.g. USDC
        ParticipantType participantType; // Participant that created an offer
        uint256 insuredAssetAmount; //Amount of funds in the asset currency insured for the loss
        uint256 lossCoverage; // Maximum amount of funds payable by the insurer to the insured to cover losses, in the base currency
        uint256 premiumPercent; //Mutually agreed amount the Insured pays weekly to Insurer in order to maintain the policy. Full percent, e.g. 20% = 2000. 
        //Premium is denominated as a percentage of Coverage amount and is paid in the asset being covered.
        address creator; // insured OR insured, depending on participantType
        uint256 period; //Policy period - Period, in weeks
    }

    struct Policy {
        uint256 acceptedTime;
        OfferTerms offerTerms;
        uint256 totalPremiumDeposited; // total premium deposited by the insured. Can only increase
        Status status;
        address acceptor;   // opposite from participantType of the offer creator
        uint256 platformFee; // fee in BAKT supplied by the insured
        uint256 premiumWithdrawn; // total premium withdrawn by the insurer. Can only increase
        uint256 originalPrice; // asset/base price at the moment of policy creation
    }

    IPriceProvider public priceProvider;
    IBackedPriceProvider public backedPriceProvider;
    uint256 private currentPolicyId; // current policy id to be incremented
    uint256 public feeBalance; // fee balance available for withdrawal by the contract owner

    // policyId => Policy
    mapping(uint256 => Policy) public policies;

    // _asset =>baseERC20=>uniswapPair (Uniswap V3)
    mapping(address => mapping(address => address)) public pairs;

    // events
    event OfferPlaced(uint256 policyId);
    event OfferCanceled(uint256 policyId);
    event OfferAccepted(uint256 policyId, address secondParticipant);
    event PolicyTerminated(
        uint256 policyId,
        address initiator,
        ParticipantType initiatorType
    );
    event PremiumDeposited(
        uint256 policyId,
        address sourceAddress,
        uint256 amount
    );

    event PremiumWithdrawn(uint256 policyId);
    event BurnPercentSet(uint256 percent);
    event PlatformFeePercentSet(uint256 percent);
    event PlatformFeeWithdrawn(uint256 amount);

    IERC20 public platformToken;
    uint256 public platformFeePercent;
    uint256 public BurnPercent;

    bool public IsLocked = false;

    constructor(
        IERC20 _platformToken,
        uint256 _platformFeePercent,
        IPriceProvider _priceProvider,
        IBackedPriceProvider _backedPriceProvider
    ) {
        platformToken = _platformToken;
        platformFeePercent = _platformFeePercent;
        priceProvider = _priceProvider;
        backedPriceProvider = _backedPriceProvider;
        setPlatformFeePercent(_platformFeePercent);
        setBurnPercent(100);
        // 1%
    }

    function setPriceProvider(IPriceProvider _priceProvider) external onlyOwner {
        priceProvider = _priceProvider;
    }
    
    function setBackedPriceProvider(IBackedPriceProvider _backedPriceProvider) external onlyOwner{
        backedPriceProvider = _backedPriceProvider;
    }

    function setPriceProviderAddress(
        IPriceProvider _priceProvider
    ) external onlyOwner {
        priceProvider = _priceProvider;
    }

    function setPairAddress(
        address _uniswapPair,
        address _asset,
        address _baseERC20
    ) external onlyOwner {
        pairs[_asset][_baseERC20] = _uniswapPair;
    }

    function setBurnPercent(uint256 percent) public onlyOwner {
        BurnPercent = percent;
        require(percent / BASE_PERCENT == 0, 'setBurnPercent: wrong value');
        // > 100%: percent / BASE_PERCENT will be more than 1
        emit BurnPercentSet(percent);
    }

    function setPlatformFeePercent(uint256 percent) public onlyOwner {
        platformFeePercent = percent;
        require(percent / BASE_PERCENT == 0, 'setPlatformFeePercent: wrong value');
        emit PlatformFeePercentSet(percent);
    }

    function setLockedState(bool state) external onlyOwner {
        IsLocked = state;
    }

    // external API
    function placeOfferByInsurer(
        address _asset, //Asset to insure. It must be ERC-20 compatible token
        address _baseCurrency, //Base currency - Currency in which asset is priced. Usually it is stablecoin ERC-20, e.g. USDC
        uint256 _insuredAssetAmount, //amount of funds in Asset currency insured for the loss.
        uint256 _lossCoverage, //Maximum loss coverage - Maximum amount of funds payable by the insurer to the insured to cover losses, in base currency
        uint256 _premiumPercent, //Premium is denominated as a percentage of Coverage amount and is paid in the asset being covered.
        uint256 _period // Policy period - Period, in weeks
    ) external returns (uint256) {
        require(!IsLocked, "placeOfferByInsurer: placeOffer locked");
        require(pairs[_asset][_baseCurrency] != address(0), "placeOfferByInsurer: pair does not exist");
        require(_premiumPercent <= BASE_PERCENT, 'placeOfferByInsurer: extra large premiumPercent');

        OfferTerms memory offerTerms;
        offerTerms.asset = _asset;
        offerTerms.baseCurrency = _baseCurrency;
        offerTerms.insuredAssetAmount = _insuredAssetAmount;
        offerTerms.premiumPercent = _premiumPercent;
        offerTerms.lossCoverage = _lossCoverage;
        offerTerms.participantType = ParticipantType.Insurer;
        offerTerms.creator = msg.sender;
        offerTerms.period = _period;

        _insurerOfferTransfers(offerTerms);

        uint256 offerId = _getPolicyId();

        Policy memory policy;
        policy.acceptedTime = block.timestamp;
        policy.offerTerms = offerTerms;
        policy.status = Status.Offer;
        policies[offerId] = policy;

        emit OfferPlaced(offerId);

        return offerId;
    }

    function acceptOfferByInsurer(uint256 _policyId) external {
        Policy memory policy = policies[_policyId];
        require(
            policy.offerTerms.participantType == ParticipantType.Insured,
            'acceptOfferByInsurer: wrong type of offer'
        );
        require(
            policy.offerTerms.creator != msg.sender,
            'acceptOfferByInsurer: acceptor cant be creator'
        );
        require(
            policy.status == Status.Offer,
            'acceptOfferByInsurer: wrong status'
        );
        _insurerOfferTransfers(policy.offerTerms);

        policy.status = Status.ActivePolicy;
        policy.acceptor = msg.sender;
        policy.acceptedTime = block.timestamp;
        policy.originalPrice = assetPrice(policy);
        policies[_policyId] = policy;
        _processFee(policy);

        emit OfferAccepted(_policyId, msg.sender);
    }

    function placeOfferByInsured(
        address _asset, //Asset to insure. It must be ERC-20 compatible token
        address _baseCurrency, //Base currency - Currency in which asset is priced. Usually it is stablecoin ERC-20, e.g. USDC
        uint256 _insuredAssetAmount, //amount of funds in Asset currency insured for the loss.
        uint256 _lossCoverage, //Maximum loss coverage - Maximum amount of funds payable by the insurer to the insured to cover losses, in base currency
        uint256 _premiumPercent, //Premium is denominated as a percentage of Coverage amount and is paid in the asset being covered.
        uint256 _period, //Policy period - Period, in weeks
        uint256 _premiumAmountToDeposit // Premium amount to withdraw from the insured 
    ) external {
        require(!IsLocked, "placeOfferByInsured: placeOffer locked");
        require(pairs[_asset][_baseCurrency] != address(0), "placeOfferByInsured: pair doesnt exist");
        require(_premiumPercent <= BASE_PERCENT, 'placeOfferByInsured: extra large premiumPercent');

        OfferTerms memory offerTerms;
        offerTerms.asset = _asset;
        offerTerms.baseCurrency = _baseCurrency;
        offerTerms.insuredAssetAmount = _insuredAssetAmount;
        offerTerms.premiumPercent = _premiumPercent;
        offerTerms.creator = msg.sender;
        offerTerms.lossCoverage = _lossCoverage;
        offerTerms.participantType = ParticipantType.Insured;
        offerTerms.period = _period;

        uint256 policyId = _getPolicyId();
        uint256 fee = _insuredOfferTransfers(
            policyId,
            _premiumAmountToDeposit,
            0, // total deposit
            offerTerms
        );

        Policy memory policy;
        policy.acceptedTime = block.timestamp;
        policy.offerTerms = offerTerms;
        policy.status = Status.Offer;
        // offer
        policy.platformFee = fee;
        policy.totalPremiumDeposited = _premiumAmountToDeposit;
        policies[policyId] = policy;

        emit OfferPlaced(policyId);
    }

    function acceptOfferByInsured(uint256 _policyId, uint256 _premiumAmountToDeposit)
    public
    {
        Policy memory policy = policies[_policyId];
        require(
            policy.offerTerms.participantType == ParticipantType.Insurer,
            'acceptOfferByInsured: wrong participantType'
        );
        require(
            policy.offerTerms.creator != msg.sender,
            'acceptOfferByInsured: creator == acceptor'
        );
        require(
            policy.status == Status.Offer,
            'acceptOfferByInsured: wrong status'
        );

        uint256 fee = _insuredOfferTransfers(
            _policyId,
            _premiumAmountToDeposit,
            policy.totalPremiumDeposited,
            policy.offerTerms
        );

        policy = policies[_policyId];
        policy.platformFee = fee;
        policy.totalPremiumDeposited = policy.totalPremiumDeposited.add(_premiumAmountToDeposit);
        policy.status = Status.ActivePolicy;
        // Offer becomes Policy
        policy.acceptor = msg.sender;
        policy.acceptedTime = block.timestamp;
        policy.originalPrice = assetPrice(policy);
        // Always 18 decimals
        policies[_policyId] = policy;
        _processFee(policy);

        emit OfferAccepted(_policyId, msg.sender);
    }

    // Insured deposits premium for existing policy
    function premiumDeposit(uint256 _policyId, uint256 _premiumAmount) external {
        Policy memory policy = policies[_policyId];
        require(policy.status == Status.ActivePolicy, 'premiumDeposit: must be active Policy');
        require(isEnoughPremiumUpToCurrentWeek(policy), 'premiumDeposit: Policy terminated due to not enough premium');

        _premiumDepositTransfer(
            _policyId,
            _premiumAmount,
            policy.totalPremiumDeposited,
            policy.offerTerms
        );

        policy.totalPremiumDeposited = policy.totalPremiumDeposited.add(_premiumAmount);
        policies[_policyId] = policy;
    }

    function cancelOffer(uint256 _policyId) external {
        Policy memory policy = policies[_policyId];
        if (policy.offerTerms.participantType == ParticipantType.Insurer) {
            cancelOfferByInsurer(_policyId);
        } else {
            cancelOfferByInsured(_policyId);
        }
    }

    function cancelOfferByInsurer(uint256 _policyId) public {
        Policy memory policy = policies[_policyId];
        require(policy.status == Status.Offer, 'cancelOfferByInsurer: must be active Offer');
        require(
            policy.offerTerms.participantType == ParticipantType.Insurer, 'cancelOfferByInsurer: wrong participant type'
        );
        require(policy.offerTerms.creator == msg.sender, 'cancelOfferByInsurer: not creator');

        IERC20 token = IERC20(policy.offerTerms.baseCurrency);
        token.transfer(msg.sender, policy.offerTerms.lossCoverage);

        policy.status = Status.CanceledOffer;
        policies[_policyId] = policy;
        emit OfferCanceled(_policyId);
    }

    function cancelOfferByInsured(uint256 _policyId) public {
        Policy memory policy = policies[_policyId];
        require(policy.status == Status.Offer, 'cancelOfferByInsured: must be active Offer');
        require(policy.offerTerms.creator == msg.sender, 'cancelOfferByInsured: not creator');
        require(
            policy.offerTerms.participantType == ParticipantType.Insured, 'cancelOfferByInsured: wrong participant type'
        );

        IERC20 token = IERC20(platformToken);
        token.transfer(msg.sender, policy.platformFee);

        IERC20 assetToken = IERC20(policy.offerTerms.asset);
        assetToken.transfer(msg.sender, policy.totalPremiumDeposited);

        policy.status = Status.CanceledOffer;
        policies[_policyId] = policy;
        emit OfferCanceled(_policyId);
    }

    function premiumWithdraval(uint256 _policyId) external {
        Policy memory policy = policies[_policyId];

        address insurer;
        require(policy.status == Status.ActivePolicy, 'premiumWithdraval: must be active Policy');

        if (policy.offerTerms.participantType == ParticipantType.Insurer) {
            insurer = policy.offerTerms.creator;
        } else {
            insurer = policy.acceptor;
        }

        uint256 premium_available_to_insurer_for_withdrawal
        = premiumAvailableInsurerWithdrawal(policy);

        IERC20 assetToken = IERC20(policy.offerTerms.asset);
        assetToken.transfer(
            insurer,
            premium_available_to_insurer_for_withdrawal
        );

        policy.premiumWithdrawn = premium_available_to_insurer_for_withdrawal
        .add(policy.premiumWithdrawn);

        policies[_policyId] = policy;

        emit PremiumWithdrawn(_policyId);
    }

    function transferPlatformFee(address _to) external onlyOwner {
        IERC20 token = IERC20(platformToken);
        token.transfer(_to, feeBalance);

        emit PlatformFeeWithdrawn(feeBalance);
        feeBalance = 0;
    }

    function calculateTerminationResult(uint256 _policyId, address _terminator)
    public
    view
    returns (
        uint256 lossCoverageInsuredWithdraw,
        uint256 lossCoverageInsurerWithdraw,
        uint256 premium_available_to_insured_for_withdrawal,
        uint256 premium_available_to_insurer_for_withdrawal,
        address insurer,
        address insured,
        ParticipantType initiator
    )
    {
        Policy memory policy = policies[_policyId];

        require(policy.status == Status.ActivePolicy, 'terminationResult: must be active Policy');

        if (policy.offerTerms.participantType == ParticipantType.Insurer) {
            insured = policy.acceptor;
            insurer = policy.offerTerms.creator;
        } else {
            insured = policy.offerTerms.creator;
            insurer = policy.acceptor;
        }

        require(_terminator == insurer || _terminator == insured, 'terminationResult: this user cant terminate');

        if (_terminator == insurer)
            initiator = ParticipantType.Insurer;
        else
            initiator = ParticipantType.Insured;


        if (isExpired(policy) || !isEnoughPremiumUpToCurrentWeek(policy)) {
            lossCoverageInsuredWithdraw = 0;
            premium_available_to_insured_for_withdrawal = 0;
            lossCoverageInsurerWithdraw = policy.offerTerms.lossCoverage;
            premium_available_to_insurer_for_withdrawal = policy.totalPremiumDeposited.sub(policy.premiumWithdrawn);
        }
        else {
            uint256 premiumPerWeek = getPremiumPerWeek(policy);

            if (initiator == ParticipantType.Insurer) {

                premium_available_to_insured_for_withdrawal = policy
                .totalPremiumDeposited
                .sub(premiumPerWeek.mul(weekElapsedRoundDown(policy)));

                premium_available_to_insurer_for_withdrawal = premiumPerWeek
                .mul(weekElapsedRoundDown(policy))
                .sub(policy.premiumWithdrawn);

            } else if (initiator == ParticipantType.Insured) {

                premium_available_to_insured_for_withdrawal = policy
                .totalPremiumDeposited
                .sub(premiumPerWeek.mul(weekElapsedRoundUp(policy)));

                premium_available_to_insurer_for_withdrawal = premiumPerWeek
                .mul(weekElapsedRoundUp(policy))
                .sub(policy.premiumWithdrawn);
            }

            uint256 currentPrice = assetPrice(policy);
            if (currentPrice < policy.originalPrice)
            {   
                lossCoverageInsuredWithdraw = (
                policy.originalPrice.sub(currentPrice)
                )
                .mul(policy.offerTerms.insuredAssetAmount)
                .div(BASE_PRICE);
            } else {
                lossCoverageInsuredWithdraw == 0;
            }

            if (lossCoverageInsuredWithdraw > policy.offerTerms.lossCoverage) {
                lossCoverageInsuredWithdraw = policy.offerTerms.lossCoverage;
            }

            lossCoverageInsurerWithdraw = policy.offerTerms.lossCoverage.sub(
                lossCoverageInsuredWithdraw
            );
        }
    }

    function terminate(uint256 _policyId) external {
        uint256 lossCoverageInsuredWithdraw;
        uint256 lossCoverageInsurerWithdraw;
        uint256 premium_available_to_insured_for_withdrawal;
        uint256 premium_available_to_insurer_for_withdrawal;
        address insurer;
        address insured;
        ParticipantType initiator;

        (
        lossCoverageInsuredWithdraw,
        lossCoverageInsurerWithdraw,
        premium_available_to_insured_for_withdrawal,
        premium_available_to_insurer_for_withdrawal,
        insurer,
        insured,
        initiator
        ) = calculateTerminationResult(_policyId, msg.sender);

        Policy memory policy = policies[_policyId];
        IERC20 baseToken = IERC20(policy.offerTerms.baseCurrency);

        if (lossCoverageInsuredWithdraw != 0)
            baseToken.transfer(insured, lossCoverageInsuredWithdraw);

        if (lossCoverageInsurerWithdraw != 0)
            baseToken.transfer(insurer, lossCoverageInsurerWithdraw);

        IERC20 assetToken = IERC20(policy.offerTerms.asset);

        if (premium_available_to_insured_for_withdrawal != 0)
            assetToken.transfer(
                    insured,
                    premium_available_to_insured_for_withdrawal
                );

        if (premium_available_to_insurer_for_withdrawal != 0)
            assetToken.transfer(
                    insurer,
                    premium_available_to_insurer_for_withdrawal
                );

        policy.status = Status.TerminatedPolicy;

        policies[_policyId] = policy;

        emit PolicyTerminated(_policyId, msg.sender, initiator);
    }

    // calculate amount of fee for the insured to pay in the Platform Token
    function calculatePlatformFee(
        address _asset, //Asset to insure. It must be an ERC-20 compatible token
        address _baseCurrency,
        uint256 _premiumPercent,
        uint256 _insuredAssetAmount, //amount of funds in the Asset currency insured for the loss.
        uint256 _period
    ) public view returns (uint256) {
        address assetUniswapPair = pairs[_asset][_baseCurrency];
        IPriceProvider oracle = IPriceProvider(priceProvider);

        uint256 plaformFeeInAssetCurrency = _calculatePlaformFeeInAssetCurrency(
            _premiumPercent,
            _insuredAssetAmount,
            _period
        );

        uint256 feeInBaseCurrency = plaformFeeInAssetCurrency.mul(
            oracle.getPairPrice(assetUniswapPair, _baseCurrency)
        );


        //usdt/get price by usdt
        uint256 feeInPlatformToken = feeInBaseCurrency.div(
            backedPriceProvider.getPrice(_baseCurrency)
        );

        return feeInPlatformToken.div(10 ** (18 - IERC20Extented(_asset).decimals()));
        // adjust to asset decimals
    }

    function _calculatePlaformFeeInAssetCurrency(
        uint256 _premiumPercent,
        uint256 _insuredAssetAmount,
        uint256 _period
    ) private view returns (uint256) {

        uint256 totalPremium = _insuredAssetAmount
        .mul(_premiumPercent)
        .mul(_period)
        .div(
            BASE_PERCENT
        );

        uint256 plaformFeeInAssetCurrency = totalPremium.mul(platformFeePercent).div(
            BASE_PERCENT
        );

        return plaformFeeInAssetCurrency;
    }

    function getCurrentPolicyId() external view returns (uint256) {
        return currentPolicyId;
    }

    function assetPrice(Policy memory policy) public view returns (uint256) {
        address assetUniswapPair = pairs[policy.offerTerms.asset][
        policy.offerTerms.baseCurrency
        ];
        IPriceProvider oracle = IPriceProvider(priceProvider);
        return
        oracle.getPairPrice(
            assetUniswapPair,
            policy.offerTerms.baseCurrency
        );
    }

    function weekElapsed(Policy memory policy) public view returns (uint256) {
        return ((block.timestamp - policy.acceptedTime) / 1 weeks);
    }

    function weekElapsedRoundUp(Policy memory policy)
    public
    view
    returns (uint256)
    {
        uint256 weeksElapsed = weekElapsed(policy) + 1;
        if (weeksElapsed >= policy.offerTerms.period) {
            weeksElapsed = policy.offerTerms.period;
        }
        return weeksElapsed;
    }

    function premiumAvailableInsurerWithdrawal(Policy memory policy)
    public
    view
    returns (uint256)
    {
        return
        getPremiumPerWeek(policy).mul(weekElapsedRoundDown(policy)).sub(
            policy.premiumWithdrawn
        );
    }

    function getPremiumPerWeek(Policy memory policy)
    public
    pure
    returns (uint256)
    {
        return
        policy
        .offerTerms
        .insuredAssetAmount
        .mul(policy.offerTerms.premiumPercent)
        .div(BASE_PERCENT);
    }

    function weekElapsedRoundDown(Policy memory policy)
    public
    view
    returns (uint256)
    {
        uint256 weeksElapsed = weekElapsed(policy);
        if (weeksElapsed >= policy.offerTerms.period) {
            weeksElapsed = policy.offerTerms.period;
        }
        return weeksElapsed;
    }

    function isEnoughPremiumUpToCurrentWeekByPolicyId(uint256 _policyId) external view returns (bool) {
        Policy memory policy = policies[_policyId];
        return isEnoughPremiumUpToCurrentWeek(policy);
    }

    function isEnoughPremiumUpToCurrentWeek(Policy memory policy) internal view returns (bool) {
        uint256 weeksElapsed = weekElapsedRoundUp(policy);
        uint256 premiumRequired = policy
        .offerTerms
        .premiumPercent
        .mul(policy.offerTerms.insuredAssetAmount)
        .mul(weeksElapsed)
        .div(BASE_PERCENT);
        return policy.totalPremiumDeposited >= premiumRequired;
    }

    function isExpiredByPolicyId(uint256 _policyId) external view returns (bool) {
        Policy memory policy = policies[_policyId];
        return isExpired(policy);
    }

    function isExpired(Policy memory policy) internal view returns (bool) {
        uint256 weeksElapsed = weekElapsed(policy);
        return weeksElapsed >= policy.offerTerms.period;
    }

    function getPolicy(uint256 policyId)
    public
    view
    returns (Policy memory policy)
    {
        return policies[policyId];
    }

    function _insurerOfferTransfers(OfferTerms memory _terms) private {
        IERC20 token = IERC20(_terms.baseCurrency);
        token.transferFrom(msg.sender, address(this), _terms.lossCoverage);
    }

    function _processFee(Policy memory policy) private {

        uint256 burnAmount = policy.platformFee.mul(BurnPercent).div(
            BASE_PERCENT
        );

        feeBalance = feeBalance.add(policy.platformFee.sub(burnAmount));

        IERC20 token = IERC20(platformToken);
        if (burnAmount > 0)
            token.transfer(BurnerAddress, burnAmount);
    }

    function _insuredOfferTransfers(
        uint256 policyId,
        uint256 premiumAmount,
        uint256 currentDepositBalance,
        OfferTerms memory _terms
    ) private returns (uint256 fee) {
        fee = calculatePlatformFee(
            _terms.asset,
            _terms.baseCurrency,
            _terms.premiumPercent,
            _terms.insuredAssetAmount,
            _terms.period
        );

        require(fee > 0, 'Extra small fee');

        IERC20 token = IERC20(platformToken);
        token.transferFrom(msg.sender, address(this), fee);

        _premiumDepositTransfer(
            policyId,
            premiumAmount,
            currentDepositBalance,
            _terms
        );
    }

    function _premiumDepositTransfer(
        uint256 policyId,
        uint256 premiumAmount,
        uint256 currentDepositBalance,
        OfferTerms memory terms
    ) private {
        uint256 weeklyPremium = terms
        .premiumPercent
        .mul(terms.insuredAssetAmount)
        .div(BASE_PERCENT);

        require(currentDepositBalance.add(premiumAmount) >= weeklyPremium, '_premiumDepositTransfer: need premium for at least a week');

        IERC20 assetToken = IERC20(terms.asset);
        assetToken.transferFrom(msg.sender, address(this), premiumAmount);

        emit PremiumDeposited(policyId, msg.sender, premiumAmount);
    }

    function _getPolicyId() internal returns (uint256) {
        currentPolicyId = currentPolicyId.add(1);
        return currentPolicyId;
    }
}
