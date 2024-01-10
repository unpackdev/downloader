// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketController.sol";
import "./IMarketConfig.sol";
import "./IMarketClerk.sol";
import "./DiamondLib.sol";
import "./MarketControllerBase.sol";
import "./MarketControllerLib.sol";

/**
 * @title MarketConfigFacet
 *
 * @notice Provides centralized management of various market-related settings.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract MarketConfigFacet is IMarketConfig, MarketControllerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.configFacet, "Initializer: contract is already initialized");
        mci.configFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * @param _staking - Seen.Haus staking contract
     * @param _multisig - Seen.Haus multi-sig wallet
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     * @param _primaryFeePercentage - percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     * @param _secondaryFeePercentage - percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     * @param _maxRoyaltyPercentage - maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     * @param _outBidPercentage - minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     * @param _defaultTicketerType - which ticketer type to use if none has been specified for a given consignment
     */
    function initialize(
        address payable _staking,
        address payable _multisig,
        uint256 _vipStakerAmount,
        uint16 _primaryFeePercentage,
        uint16 _secondaryFeePercentage,
        uint16 _maxRoyaltyPercentage,
        uint16 _outBidPercentage,
        Ticketer _defaultTicketerType
    )
    public
    onlyUnInitialized
    {
        // Register supported interfaces
        DiamondLib.addSupportedInterface(type(IMarketConfig).interfaceId);  // when combined with IMarketClerk ...
        DiamondLib.addSupportedInterface(type(IMarketConfig).interfaceId ^ type(IMarketClerk).interfaceId); // ... supports IMarketController

        // Initialize market config params
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.staking = _staking;
        mcs.multisig = _multisig;
        mcs.vipStakerAmount = _vipStakerAmount;
        mcs.primaryFeePercentage = _primaryFeePercentage;
        mcs.secondaryFeePercentage = _secondaryFeePercentage;
        mcs.maxRoyaltyPercentage = _maxRoyaltyPercentage;
        mcs.outBidPercentage = _outBidPercentage;
        mcs.defaultTicketerType = _defaultTicketerType;
    }

    /**
     * @notice Sets the address of the SEEN NFT contract.
     *
     * Emits a NFTAddressChanged event.
     *
     * @param _nft - the address of the nft contract
     */
    function setNft(address _nft)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.nft = _nft;
        emit NFTAddressChanged(_nft);
    }

    /**
     * @notice The nft getter
     */
    function getNft()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.nft;
    }

    /**
     * @notice Sets the address of the Seen.Haus lots-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _lotsTicketer - the address of the lots-based escrow ticketer contract
     */
    function setLotsTicketer(address _lotsTicketer)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.lotsTicketer = _lotsTicketer;
        emit EscrowTicketerAddressChanged(mcs.lotsTicketer, Ticketer.Lots);
    }

    /**
     * @notice The lots-based escrow ticketer getter
     */
    function getLotsTicketer()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.lotsTicketer;
    }

    /**
     * @notice Sets the address of the Seen.Haus items-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _itemsTicketer - the address of the items-based escrow ticketer contract
     */
    function setItemsTicketer(address _itemsTicketer)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.itemsTicketer = _itemsTicketer;
        emit EscrowTicketerAddressChanged(mcs.itemsTicketer, Ticketer.Items);
    }

    /**
     * @notice The items-based ticketer getter
     */
    function getItemsTicketer()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.itemsTicketer;
    }

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a StakingAddressChanged event.
     *
     * @param _staking - the address of the staking contract
     */
    function setStaking(address payable _staking)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.staking = _staking;
        emit StakingAddressChanged(mcs.staking);
    }

    /**
     * @notice The staking getter
     */
    function getStaking()
    external
    override
    view
    returns (address payable)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.staking;
    }

    /**
     * @notice Sets the address of the Seen.Haus multi-sig wallet.
     *
     * Emits a MultisigAddressChanged event.
     *
     * @param _multisig - the address of the multi-sig wallet
     */
    function setMultisig(address payable _multisig)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.multisig = _multisig;
        emit MultisigAddressChanged(mcs.multisig);
    }

    /**
     * @notice The multisig getter
     */
    function getMultisig()
    external
    override
    view
    returns (address payable)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.multisig;
    }

    /**
     * @notice Sets the VIP staker amount.
     *
     * Emits a VipStakerAmountChanged event.
     *
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     */
    function setVipStakerAmount(uint256 _vipStakerAmount)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.vipStakerAmount = _vipStakerAmount;
        emit VipStakerAmountChanged(mcs.vipStakerAmount);
    }

    /**
     * @notice The vipStakerAmount getter
     */
    function getVipStakerAmount()
    external
    override
    view
    returns (uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.vipStakerAmount;
    }

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a PrimaryFeePercentageChanged event.
     *
     * @param _primaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setPrimaryFeePercentage(uint16 _primaryFeePercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_primaryFeePercentage > 0 && _primaryFeePercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.primaryFeePercentage = _primaryFeePercentage;
        emit PrimaryFeePercentageChanged(mcs.primaryFeePercentage);
    }

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a FeePercentageChanged event.
     *
     * @param _secondaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setSecondaryFeePercentage(uint16 _secondaryFeePercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_secondaryFeePercentage > 0 && _secondaryFeePercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.secondaryFeePercentage = _secondaryFeePercentage;
        emit SecondaryFeePercentageChanged(mcs.secondaryFeePercentage);
    }

    /**
     * @notice The primaryFeePercentage and secondaryFeePercentage getter
     */
    function getFeePercentage(Market _market)
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        if(_market == Market.Primary) {
            return mcs.primaryFeePercentage;
        } else {
            return mcs.secondaryFeePercentage;
        }
    }

    /**
     * @notice Sets the maximum royalty percentage the marketplace will pay.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * @param _maxRoyaltyPercentage - the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setMaxRoyaltyPercentage(uint16 _maxRoyaltyPercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_maxRoyaltyPercentage > 0 && _maxRoyaltyPercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.maxRoyaltyPercentage = _maxRoyaltyPercentage;
        emit MaxRoyaltyPercentageChanged(mcs.maxRoyaltyPercentage);
    }

    /**
     * @notice The maxRoyaltyPercentage getter
     */
    function getMaxRoyaltyPercentage()
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.maxRoyaltyPercentage;
    }

    /**
     * @notice Sets the marketplace auction outbid percentage.
     *
     * Emits a OutBidPercentageChanged event.
     *
     * @param _outBidPercentage - the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setOutBidPercentage(uint16 _outBidPercentage)
    external
    override
    onlyRole(ADMIN)
    {
        require(_outBidPercentage > 0 && _outBidPercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.outBidPercentage = _outBidPercentage;
        emit OutBidPercentageChanged(mcs.outBidPercentage);
    }

    /**
     * @notice The outBidPercentage getter
     */
    function getOutBidPercentage()
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.outBidPercentage;
    }

    /**
     * @notice Sets the default escrow ticketer type.
     *
     * Emits a DefaultTicketerTypeChanged event.
     *
     * Reverts if _ticketerType is Ticketer.Default
     * Reverts if _ticketerType is already the defaultTicketerType
     *
     * @param _ticketerType - the new default escrow ticketer type.
     */
    function setDefaultTicketerType(Ticketer _ticketerType)
    external
    override
    onlyRole(ADMIN)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        require(_ticketerType != Ticketer.Default, "Invalid ticketer type.");
        require(_ticketerType != mcs.defaultTicketerType, "Type is already default.");
        mcs.defaultTicketerType = _ticketerType;
        emit DefaultTicketerTypeChanged(mcs.defaultTicketerType);
    }

    /**
     * @notice The defaultTicketerType getter
     */
    function getDefaultTicketerType()
    external
    override
    view
    returns (Ticketer)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.defaultTicketerType;
    }

    /**
     * @notice Get the Escrow Ticketer to be used for a given consignment
     *
     * If a specific ticketer has not been set for the consignment,
     * the default escrow ticketer will be returned.
     *
     * Reverts if consignment doesn't exist
     *     *
     * @param _consignmentId - the id of the consignment
     * @return ticketer = the address of the escrow ticketer to use
     */
    function getEscrowTicketer(uint256 _consignmentId)
    external
    override
    view
    consignmentExists(_consignmentId)
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        Ticketer specified = mcs.consignmentTicketers[_consignmentId];
        Ticketer ticketerType = (specified == Ticketer.Default) ? mcs.defaultTicketerType : specified;
        return (ticketerType == Ticketer.Lots) ? mcs.lotsTicketer : mcs.itemsTicketer;
    }
}