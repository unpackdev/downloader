// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

import "./LibArrayHelper.sol";
import "./LibSeedGenerator.sol";

import "./console.sol";

contract MetacityLandBoxerZone is Context, Ownable {
    using SafeMath for uint256;

    struct PriceInfo {
        address token;
        uint256 price;
    }

    struct ZoneInfo {
        string zoneIdentifier;
        uint256[] scales;
        address[] tokens;
        uint256[] prices;
        uint256[] capacities;
    }

    address landBoxer;
    uint256[] supportedScales;
    mapping(uint256 => PriceInfo) public globalPrices;

    bytes32[] zoneIds;
    mapping(bytes32 => ZoneInfo) landCapacities;
    mapping(uint256 => uint256) globalScaleCapacity;

    ///@dev zoneId => scale => amount
    mapping(bytes32 => mapping(uint256 => uint256)) purchaseLimit;

    constructor(address _landBoxer) {
        landBoxer = _landBoxer;
    }

    function verifyCapacityEnoughGlobalBatch(uint256[] memory _scales, uint256[] memory _amounts) public view {
        require(_scales.length == _amounts.length, "args error");
        for(uint256 i=0; i<_scales.length; i++) {
            require(_isValidScale(_scales[i]));
            require(globalScaleCapacity[_scales[i]] >= _amounts[i], "no enough capacity");
        }
    }

    function verifyCapacityEnoughBatch(string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts) public view {
        require(_zoneIds.length == _scales.length && _zoneIds.length == _amounts.length, "args error");
        for(uint8 i=0; i<_zoneIds.length; i++) {
            bytes32 zoneId = _getZoneId(_zoneIds[i]);
            require(_isValidScale(_scales[i]));
            require(_getCapacityByZoneIdAndScale(zoneId, _scales[i]) >= _amounts[i], "no enough capacity");
            if (purchaseLimit[zoneId][_scales[i]] >= 1) {
                require(purchaseLimit[zoneId][_scales[i]] >= _amounts[i] + 1, "epl error"); //exceed purchase limit
            }
        }
    }

    modifier onlyBoxer() {
        require(msg.sender == landBoxer, "only boxer");
        _;
    } 

    function setPurchaseLimit(string[] memory _zoneIds, uint256[] memory _scales, uint256[] memory _amounts) public onlyOwner {
        require(_zoneIds.length == _scales.length && _scales.length == _amounts.length, "args error");
        for (uint256 i=0; i<_zoneIds.length; i++) {
            require(_isValidScale(_scales[i]));
            bytes32 zoneId = _getZoneId(_zoneIds[i]);
            purchaseLimit[zoneId][_scales[i]] = _amounts[i] + 1;
        }
    }

    function capacityRemaining() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory _capacities = new uint256[](supportedScales.length);
        for (uint256 i=0; i<supportedScales.length; i++) {
            _capacities[i] = globalScaleCapacity[supportedScales[i]];
        }
        return (supportedScales, _capacities);
    }

    function capacityRemaining(string memory _zoneId) public view returns (uint256[] memory _scales, uint256[] memory _capacities) {
        bytes32 zoneId = _getZoneId(_zoneId);

        _scales = landCapacities[zoneId].scales;
        _capacities = landCapacities[zoneId].capacities;
    }

    function capacityRemaining(string memory _zoneId, uint256 _scale) public view returns (uint256 amount) {
        require(_isValidScale(_scale), "invalid scale");
        bytes32 zoneId = _getZoneId(_zoneId);

        amount = landCapacities[zoneId].capacities[_getIndexByZoneIdAndScale(zoneId, _scale)];
    }

    function getGlobalPrice(uint256 scale) public view returns (PriceInfo memory) {
        return globalPrices[scale];
    }

    function correspondingPrice(string[] memory _zoneIds, uint256[] memory _scales) public view returns (address[] memory, uint256[] memory) {
        require(_zoneIds.length > 0 && _zoneIds.length == _scales.length, "params error");
        address[] memory tokens = new address[](_zoneIds.length);
        uint256[] memory prices = new uint256[](_zoneIds.length);
        for (uint256 i=0; i<_zoneIds.length; i++) {
            PriceInfo memory priceInfo;
            if (keccak256(abi.encode(_zoneIds[i])) == keccak256(abi.encode("-1"))) {
                priceInfo = globalPrices[_scales[i]];
            } else {
                priceInfo = _getPriceByZoneIdAndScale(_getZoneId(_zoneIds[i]), _scales[i]);
            }
            tokens[i] = priceInfo.token;
            prices[i] = priceInfo.price;
        }
        return (tokens, prices);
    }

    function setSupportedScalesAndGlobalPrices(uint256[] memory _scales, PriceInfo[] memory _prices) public onlyOwner {
        supportedScales = _scales;
        for (uint256 i=0; i<_scales.length; i++) {
            globalPrices[_scales[i]] = _prices[i];
        }
    }

    function addOrUpdateZones(ZoneInfo[] memory _zoneInfos) public onlyOwner {
        for (uint8 j=0; j<_zoneInfos.length; j++) {
            ZoneInfo memory _zoneInfo = _zoneInfos[j];
            require(_zoneInfo.scales.length == _zoneInfo.prices.length && _zoneInfo.scales.length == _zoneInfo.capacities.length, "args error");
            for (uint256 i=0; i<_zoneInfo.scales.length; i++) {
                require(_isValidScale(_zoneInfo.scales[i]), "invalid scale");
            }
            bytes32 zoneId = _getZoneId(_zoneInfo.zoneIdentifier);
            if (_isZoneRegistered(_zoneInfo.zoneIdentifier)) {
                removeZone(_zoneInfo.zoneIdentifier);
            }
            for (uint256 i=0; i<_zoneInfo.scales.length; i++) {
                globalScaleCapacity[_zoneInfo.scales[i]] = globalScaleCapacity[_zoneInfo.scales[i]].add(_zoneInfo.capacities[i]);
            }
            zoneIds.push(zoneId);
            landCapacities[_getZoneId(_zoneInfo.zoneIdentifier)] = _zoneInfo;
        }
    }

    function addZoneCapacities(string[] memory _zoneIndentifiers, uint256[][] memory _scales, uint256[][] memory _capacities) 
        public 
        onlyOwner {
        for (uint8 i=0; i<_zoneIndentifiers.length; i++) {
            ZoneInfo storage zoneInfo = landCapacities[_getZoneId(_zoneIndentifiers[i])];
            for (uint8 j=0; j<_scales[i].length; j++) {
                for (uint8 k=0; k<zoneInfo.scales.length; k++) {
                    if (zoneInfo.scales[k] == _scales[i][j]) {
                        zoneInfo.capacities[k] = zoneInfo.capacities[k].add(_capacities[i][j]);
                        globalScaleCapacity[zoneInfo.scales[k]] = globalScaleCapacity[zoneInfo.scales[k]].add(_capacities[i][j]);
                    }
                }
            }
        }
        _verifyCapacity();
    }

    function _verifyCapacity() private view {
        //verify scales and global capacities.
        for (uint256 i=0; i<supportedScales.length; i++) {
            uint256 sumSpecificScaleCapacity = 0;
            for (uint256 j=0; j<zoneIds.length; j++) {
                bytes32 zoneId = zoneIds[j];
                if (_isValidZoneScale(zoneId, supportedScales[i])) {
                    sumSpecificScaleCapacity = sumSpecificScaleCapacity.add(landCapacities[zoneId].capacities[_getIndexByZoneIdAndScale(zoneId, supportedScales[i])]);
                }
            }
            require(globalScaleCapacity[supportedScales[i]] == sumSpecificScaleCapacity, "verify error");
        }
    }

    function removeZone(string memory _zoneId) public onlyOwner {
        require(_isZoneRegistered(_zoneId), "no zone info");

        bytes32 zoneId = _getZoneId(_zoneId);
        for (uint256 i=0; i<landCapacities[zoneId].scales.length; i++) {
            globalScaleCapacity[landCapacities[zoneId].scales[i]] = globalScaleCapacity[landCapacities[zoneId].scales[i]].sub(landCapacities[zoneId].capacities[i]);
        }
        zoneIds = LibArrayHelper.removeItemFromListBytes32(zoneIds, zoneId);
        delete landCapacities[zoneId];
    }

    function subPurchaseLimitIfNeeded(bytes32 zoneId, uint256 scale, uint256 amount) public onlyBoxer {
        if (purchaseLimit[zoneId][scale] >= 1) {
            purchaseLimit[zoneId][scale] = purchaseLimit[zoneId][scale].sub(amount);
        }
    }

    function metaTradeSubCapacity(bytes32 _zoneId, uint256 _scale, uint256 _amount) public onlyBoxer {
        if (_isZoneRegistered(_zoneId) && _getCapacityByZoneIdAndScale(_zoneId, _scale) >= _amount) {
            uint256 scaleIndex = _getIndexByZoneIdAndScale(_zoneId, _scale);

            landCapacities[_zoneId].capacities[scaleIndex] = landCapacities[_zoneId].capacities[scaleIndex].sub(_amount);
            globalScaleCapacity[_scale] = globalScaleCapacity[_scale].sub(_amount);
        }
    }

    function _isZoneRegistered(bytes32 zoneId) private view returns (bool registered) {
        for (uint256 i=0; i<zoneIds.length; i++) {
            if (zoneIds[i] == zoneId) {
                registered = true;
            }
        }
    }

    function _isZoneRegistered(string memory _zoneId) private view returns (bool registered) {
        return _isZoneRegistered(_getZoneId(_zoneId));
    }

    function _getZoneId(string memory input) public pure returns (bytes32 zoneId) {
        return keccak256(abi.encode(input));
    }

    function _isValidScale(uint256 _scale) private view returns (bool) {
        for (uint256 i=0; i<supportedScales.length; i++) {
            if (supportedScales[i] == _scale) {
                return true;
            }
        }
        revert("invalid scale");
    }

    function _isValidZoneScale(bytes32 _zoneId, uint256 _scale) private view returns (bool) {
        for (uint256 i=0; i<landCapacities[_zoneId].scales.length; i++) {
            if (landCapacities[_zoneId].scales[i] == _scale) {
                return true;
            }
        }
        return false;
    }

    function _getIndexByZoneIdAndScale(bytes32 _zoneId, uint256 _scale) private view returns (uint256) {
        for (uint256 i=0; i<landCapacities[_zoneId].scales.length; i++) {
            if (landCapacities[_zoneId].scales[i] == _scale) {
                return i;
            }
        }
        revert("not found");
    }

    function _getPriceByZoneIdAndScale(bytes32 zoneId, uint256 _scale) public view returns (PriceInfo memory price) {
        ZoneInfo storage zoneInfo = landCapacities[zoneId];
        for (uint256 i=0; i<zoneInfo.scales.length; i++) {
            if (zoneInfo.scales[i] == _scale) {
                price = PriceInfo(zoneInfo.tokens[i], zoneInfo.prices[i]);
            }
        }
        require(price.price > 0, "no zone info");
    }

    function _getCapacityByZoneIdAndScale(bytes32 zoneId, uint256 _scale) private view returns (uint256 capacity) {
        for (uint256 i=0; i<landCapacities[zoneId].scales.length; i++) {
            if (landCapacities[zoneId].scales[i] == _scale) {
                require(landCapacities[zoneId].prices[i] > 0, "no capacity info");
                capacity = landCapacities[zoneId].capacities[i];
            }
        }
    }

    function _getZoneIdentifierByZoneId(bytes32 zoneId) public view returns (string memory _zoneId) {
        _zoneId = landCapacities[zoneId].zoneIdentifier;
        // require(keccak256(abi.encode(_zoneId)) != keccak256(abi.encode("")), "invalid zoneId");
    }

    function _getFirstRandomZoneIdWithEnoughCapacity(uint256 nonce, uint256 _scale, uint256 _amount) public view returns (bytes32 zoneId) {
        uint256 randomIndex = LibSeedGenerator.generateRandomInteger(zoneIds.length, nonce).sub(1);
        zoneId = zoneIds[randomIndex];
        while (!_isValidZoneScale(zoneId, _scale) || landCapacities[zoneId].capacities[_getIndexByZoneIdAndScale(zoneId, _scale)] < _amount) {
            randomIndex = randomIndex.add(1).mod(zoneIds.length);
            zoneId = zoneIds[randomIndex];
        }
        return zoneId;
    }
}