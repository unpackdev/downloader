// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

import "./ICheckouter.sol";
import "./IERC20Checkouter.sol";
import "./IETHCheckouter.sol";
import "./IERC721WithAutoId.sol";
import "./MetacityLandBoxerZone.sol";

import "./LibSeedGenerator.sol";
import "./LibArrayHelper.sol";

import "./console.sol";

contract MetacityLandBoxer is Context, Ownable {
    using SafeMath for uint256;

    event LandPurchased (
        address indexed to,
        address token,
        uint256 scale,
        uint256 price,
        uint256 amount,
        string zoneIdentifier,
        uint256[] tokenIds,
        uint256[] seeds
    );

    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address landAddress;
    address checkoutCounter;
    address zone;

    modifier onlyCapacityEnoughGlobalBatch(uint256[] memory _scales, uint256[] memory _amounts) {
        MetacityLandBoxerZone(zone).verifyCapacityEnoughGlobalBatch(_scales, _amounts);
        _;
    }

    modifier onlyCapacityEnoughBatch(string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts) {
        MetacityLandBoxerZone(zone).verifyCapacityEnoughBatch(_zoneIds, _scales, _amounts);
        _;
    }

    constructor() {}

    function setBasicInfo(address _landAddress, address _checkoutCounter, address _zone) public onlyOwner {
        landAddress = _landAddress;
        checkoutCounter = _checkoutCounter;
        zone = _zone;
    }

    function crossChainPurchase(address to, string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts)
        external 
        onlyOwner
    {
        require(_zoneIds.length > 0 && _zoneIds.length == _scales.length && _zoneIds.length == _amounts.length, "invalid args");
        for (uint8 i=0; i<_zoneIds.length; i++) {
            _mintNftAndEmitEventsCrossChain(to, _zoneIds[i], _scales[i], MetacityLandBoxerZone.PriceInfo(ZERO_ADDRESS, 0), _amounts[i]);
        }
    }

    function ethPurchaseLandBatch(string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts) 
        public 
        payable 
        onlyCapacityEnoughBatch(_zoneIds, _scales, _amounts)
    {
        uint256 remainingValue = msg.value;
        for (uint256 i=0; i<_zoneIds.length; i++) {
            bytes32 zoneId = MetacityLandBoxerZone(zone)._getZoneId(_zoneIds[i]);

            MetacityLandBoxerZone.PriceInfo memory scalePrice = MetacityLandBoxerZone(zone)._getPriceByZoneIdAndScale(zoneId, _scales[i]);
            remainingValue = remainingValue.sub(_ethPurchaseLand(zoneId, _scales[i], scalePrice, _amounts[i]));

            MetacityLandBoxerZone(zone).subPurchaseLimitIfNeeded(zoneId, _scales[i], _amounts[i]);

            _mintNftAndEmitEvents(_msgSender(), zoneId, _scales[i], scalePrice, _amounts[i]);
        }
        _refundRemainEth(remainingValue);
    }

    function tokenPurchaseLandBatch(address[] memory _tokens, string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts) 
        public 
        onlyCapacityEnoughBatch(_zoneIds, _scales, _amounts)
    {
        require(_tokens.length == _zoneIds.length, "args error");
        for (uint256 i=0; i<_zoneIds.length; i++) {
            bytes32 zoneId = MetacityLandBoxerZone(zone)._getZoneId(_zoneIds[i]);
            MetacityLandBoxerZone.PriceInfo memory scalePrice = MetacityLandBoxerZone(zone)._getPriceByZoneIdAndScale(zoneId, _scales[i]);
            _tokenPurchaseLand(_tokens[i], zoneId, _scales[i], scalePrice, _amounts[i]);

            MetacityLandBoxerZone(zone).subPurchaseLimitIfNeeded(zoneId, _scales[i], _amounts[i]);

            _mintNftAndEmitEvents(_msgSender(), zoneId, _scales[i], scalePrice, _amounts[i]);
        }
    }

    function ethPurchaseLandGlobalBatch(uint256[] memory _scales, uint256[] memory _amounts) 
        public 
        payable 
        onlyCapacityEnoughGlobalBatch(_scales, _amounts) 
    {
        uint256 remainingValue = msg.value;
        for (uint256 i=0; i<_scales.length; i++) {
            bytes32[] memory _zoneIds = new bytes32[](_amounts[i]);
            uint256 idx = 0;
            while (idx < _amounts[i]) {
                bytes32 zoneId = MetacityLandBoxerZone(zone)._getFirstRandomZoneIdWithEnoughCapacity(idx.add(i), _scales[i], 1);
                remainingValue = remainingValue.sub(_ethPurchaseLand(zoneId, _scales[i], MetacityLandBoxerZone(zone).getGlobalPrice(_scales[i]), 1));
                _zoneIds[idx] = zoneId;
                idx = idx.add(1);
            }
            _globalMintNftAndEmitEvents(_msgSender(), _zoneIds, _scales[i], MetacityLandBoxerZone(zone).getGlobalPrice(_scales[i]), _amounts[i]);
        }
        _refundRemainEth(remainingValue);
    }

    function tokenPurchaseLandGlobalBatch(address[] memory _tokens, uint256[] memory _scales, uint256[] memory _amounts) 
        public 
        onlyCapacityEnoughGlobalBatch(_scales, _amounts)
    {
        require(_tokens.length == _scales.length, "args error");
        for (uint256 i=0; i<_tokens.length; i++) {
            uint256 currentScaleAmountRemains = _amounts[i];
            bytes32[] memory _zoneIds = new bytes32[](_amounts[i]);
            uint256 idx = 0;
            while (currentScaleAmountRemains > 0) {
                bytes32 zoneId = MetacityLandBoxerZone(zone)._getFirstRandomZoneIdWithEnoughCapacity(i.add(currentScaleAmountRemains), _scales[i], 1);
                _zoneIds[idx] = zoneId;
                _tokenPurchaseLand(_tokens[i], zoneId, _scales[i], MetacityLandBoxerZone(zone).getGlobalPrice(_scales[i]), _amounts[i]);
                currentScaleAmountRemains = currentScaleAmountRemains.sub(1);
                idx = idx.add(1);
            }
            _globalMintNftAndEmitEvents(_msgSender(), _zoneIds, _scales[i], MetacityLandBoxerZone(zone).getGlobalPrice(_scales[i]), _amounts[i]);
        }
    }

    function _ethPurchaseLand(bytes32 _zoneId, uint256 _scale, MetacityLandBoxerZone.PriceInfo memory _priceInfo, uint256 _amount) 
        private 
        returns (uint256 purchaseCost) 
    {
        require(_priceInfo.token == ZERO_ADDRESS, "unsupport eth");
        require(msg.value >= _amount.mul(_priceInfo.price), "no enough value");
        IETHCheckouter(checkoutCounter).ethPurchase{
            value: _amount.mul(_priceInfo.price)
        } (
            _amount.mul(_priceInfo.price), 
            ICheckouter.BillingType.FIXED_AMOUNT
        );
        MetacityLandBoxerZone(zone).metaTradeSubCapacity(_zoneId, _scale, _amount);
        purchaseCost = _amount.mul(_priceInfo.price);
    }

    function _tokenPurchaseLand(address token, bytes32 _zoneId, uint256 _scale, MetacityLandBoxerZone.PriceInfo memory _priceInfo, uint256 _amount) private {
        require(token == _priceInfo.token, "unsupport token");
        IERC20Checkouter(checkoutCounter).tokenPurchase(
            _priceInfo.token,
            _msgSender(),
            _amount.mul(_priceInfo.price), 
            ICheckouter.BillingType.FIXED_AMOUNT
        );
        MetacityLandBoxerZone(zone).metaTradeSubCapacity(_zoneId, _scale, _amount);
    }

    function _mintNftAndEmitEventsCrossChain(address to, string memory zoneId, uint256 _scale, MetacityLandBoxerZone.PriceInfo memory _priceInfo, uint256 _amount) private {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256[] memory seeds = new uint256[](_amount);
        (tokenIds, seeds) = _mintLand(to, _amount);

        emit LandPurchased(
            to,
            _priceInfo.token,
            _scale,
            _priceInfo.price,
            _amount,
            zoneId,
            tokenIds,
            seeds
        );
    }

    function _mintNftAndEmitEvents(address to, bytes32 _zoneId, uint256 _scale, MetacityLandBoxerZone.PriceInfo memory _priceInfo, uint256 _amount) private {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256[] memory seeds = new uint256[](_amount);
        (tokenIds, seeds) = _mintLand(to, _amount);

        emit LandPurchased(
            to,
            _priceInfo.token,
            _scale,
            _priceInfo.price,
            _amount,
            MetacityLandBoxerZone(zone)._getZoneIdentifierByZoneId(_zoneId),
            tokenIds,
            seeds
        );
    }

    function _globalMintNftAndEmitEvents(address to, bytes32[] memory _zoneIds, uint256 _scale, MetacityLandBoxerZone.PriceInfo memory _priceInfo, uint256 _amount) private {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256[] memory seeds = new uint256[](_amount);
        (tokenIds, seeds) = _mintLand(to, _amount);

        string[] memory zoneIds_ = new string[](_amount);
        for (uint256 i=0; i<_amount; i++) {
            zoneIds_[i] = MetacityLandBoxerZone(zone)._getZoneIdentifierByZoneId(_zoneIds[i]);
        }
        for (uint256 i=0; i<zoneIds_.length; i++) {
            uint256[] memory _tokenIds = new uint256[](1);
            _tokenIds[0] = tokenIds[i];
            uint256[] memory _seeds = new uint256[](1);
            _seeds[0] = seeds[i];
            emit LandPurchased(
                to,
                _priceInfo.token,
                _scale,
                _priceInfo.price,
                _amount,
                zoneIds_[i],
                _tokenIds,
                _seeds
            );
        }
    }

    function _mintLand(address to, uint256 _amount) private returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256[] memory seeds = new uint256[](_amount);
        uint256 tokenId = IERC721WithAutoId(landAddress).currentId();
        for (uint256 i=0; i<_amount; i++) {
            tokenIds[i] = tokenId + i;
            seeds[i] = LibSeedGenerator.generateRandomSeed(i);
        }
        IERC721WithAutoId(landAddress).mint(to, _amount);
        return (tokenIds, seeds);
    }
    
    function _refundRemainEth(uint256 refundAmount) private {
        if (refundAmount > 0) {
            (bool sent, ) = payable(_msgSender()).call{value: refundAmount}("");
            require(sent, "refund fail");
        }
    }
}