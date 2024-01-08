// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ManifestTokenConnector.sol";
import "./IMapifestConfigurator.sol";
import "./IMapifest.sol";
import "./UseRouter.sol";
import "./pin.sol";
import "./console.sol";

contract MapifestMarketplace is ManifestTokenConnector, UseRouter, WithPin {
    mapping(address => uint256) private _ownerToAcquisitionPayback;

    mapping(uint256 => uint8) private _pinToValueAmountSplitByPercentage;
    mapping(uint256 => uint8) private _pinToPriceSplitByPercentage;

    IMapifest _nft;
    IMapifestConfigurator _config;

    constructor(address manifestTokenAddress, address routerAddress_)
        ManifestTokenConnector(manifestTokenAddress)
        UseRouter(routerAddress_)
    {}

    function _setupRouter(address routerAddress_) internal virtual override {
        _nft = IMapifest(routerAddress_);
        _config = IMapifestConfigurator(routerAddress_);
    }

    function makePin(
        uint256 _lat,
        uint256 _lng,
        uint256 _decimal,
        string calldata _message,
        uint256 _valueAmount
    ) external returns (uint256) {
        uint256 price = _config.getPinBasePrice(_decimal) + _valueAmount;
        require(_hasAllowedAmount(price), "Not enough allowance");
        _pay(price);

        // Call token mint
        uint256 tokenId = _nft.makePin(
            _lat,
            _lng,
            _decimal,
            _message,
            _valueAmount
        );

        _setSplitPercentages(tokenId);
        return tokenId;
    }

    function setMessage(uint256 _pinId, string calldata _message)
        external
        onlyOwnerOf(_pinId)
    {
        uint256 price = _config.getMessagePrice();
        require(_hasAllowedAmount(price), "Not enough allowance");
        _pay(price);
        _nft.setMessage(_pinId, _message);
    }

    function setImage(uint256 _pinId, string calldata _image)
        external
        onlyOwnerOf(_pinId)
    {
        uint256 price = _config.getImagePrice();
        require(_hasAllowedAmount(price), "Not enough allowance");
        _pay(price);
        _nft.setImage(_pinId, _image);
    }

    function setVideo(uint256 _pinId, string calldata _video)
        external
        onlyOwnerOf(_pinId)
    {
        uint256 price = _config.getVideoPrice();
        require(_hasAllowedAmount(price), "Not enough allowance");
        _pay(price);
        _nft.setVideo(_pinId, _video);
    }

    // TODO: valuamount sideeffect for marketplace?
    function setValueAmount(uint256 _pinId, uint256 _valueAmount)
        external
        onlyOwnerOf(_pinId)
    {
        _nft.setValueAmount(_pinId, _valueAmount);
    }

    // ---------------------------

    function _loadPin(uint256 _pinId)
        internal
        view
        returns (Pin memory, address)
    {
        uint32 _lat;
        uint32 _lng;
        uint8 _resolution;
        uint256 _valueAmount;
        address _owner;

        (_lat, _lng, _resolution, _valueAmount, _owner) = _nft.getPinInfo(
            _pinId
        );

        return (Pin(_lat, _lng, _resolution, "", "", "", _valueAmount), _owner);
    }

    function _split(
        uint256 _pinId,
        uint256 _valueAmount,
        uint256 _pinPrice,
        address previousOwner
    ) internal {
        uint8 valueSplit;
        uint8 priceSplit;

        (valueSplit, priceSplit) = _mySplitPercentages(_pinId);

        uint256 valueAmountForPreviousOwner = (_valueAmount / 100) * valueSplit;
        uint256 pinPriceForPreviousOwner = (_pinPrice / 100) * priceSplit;

        uint256 paybackAmount = valueAmountForPreviousOwner +
            pinPriceForPreviousOwner;

        // Approve and increase payback balance
        _approveTokenBalanceToAddress(previousOwner, paybackAmount);
        _ownerToAcquisitionPayback[previousOwner] += paybackAmount;
    }

    function acquire(
        uint256 _pinId,
        string calldata _message,
        uint256 _extraValueAmount
    ) external notOwnerOf(_pinId) {
        Pin memory target;
        address previousOwner;
        (target, previousOwner) = _loadPin(_pinId);

        uint256 pinPrice = _config.getPinBasePrice(target.resolution);

        uint256 newValueAmount = target.valueAmount + _extraValueAmount;
        uint256 totalAcquisitionCost = pinPrice + newValueAmount;
        require(
            _hasAllowedAmount(totalAcquisitionCost),
            "Not enough amount has been allowed for acquisition!"
        );

        _pay(totalAcquisitionCost);
        _split(_pinId, target.valueAmount, pinPrice, previousOwner);

        uint256 newPinId = _nft.makePin(
            target.lat,
            target.lng,
            target.resolution,
            _message,
            newValueAmount
        );
        _nft.acquire(_pinId, newPinId);
    }

    function _setSplitPercentages(uint256 _pinId) internal {
        _pinToValueAmountSplitByPercentage[_pinId] = _config
            .valueAmountSplitByPercentage();
        _pinToPriceSplitByPercentage[_pinId] = _config
            .pinPriceSplitByPercentage();
    }

    function mySplitPercentages(uint256 _pinId)
        external
        view
        returns (uint8, uint8)
    {
        return _mySplitPercentages(_pinId);
    }

    function _mySplitPercentages(uint256 _pinId)
        internal
        view
        returns (uint8, uint8)
    {
        return (
            _pinToValueAmountSplitByPercentage[_pinId],
            _pinToPriceSplitByPercentage[_pinId]
        );
    }

    modifier onlyOwnerOf(uint256 _pinId) {
        require(
            _nft.ownerOf(_pinId) == msg.sender,
            "Only owners can call this."
        );
        _;
    }

    modifier notOwnerOf(uint256 _pinId) {
        require(_nft.ownerOf(_pinId) != msg.sender, "Owners cannot call this.");
        _;
    }
}
