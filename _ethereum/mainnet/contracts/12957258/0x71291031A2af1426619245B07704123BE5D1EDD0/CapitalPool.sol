/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ICapitalPool.sol";
import "./IPremiumPool.sol";
import "./IStakersPoolV2.sol";
import "./SecurityMatrix.sol";
import "./Constant.sol";
import "./Math.sol";
import "./IExchangeRate.sol";

contract CapitalPool is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, ICapitalPool {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeCapitalPool() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    address public securityMatrix;

    // stakers V2 _token and misc
    address[] public stakersTokenData;
    mapping(address => uint256) public stakersTokenDataMap;
    address public stakersPoolV2;

    // fee pool
    address public feePoolAddress;

    // premium pool
    address public premiumPoolAddress;
    uint256 public premiumPayoutRatioX10000;

    // claim payout address
    address public claimToSettlementPool;

    // product cover pool tokens
    address[] public productCoverTokens;
    mapping(address => uint256) public productCoverTokensMap;
    uint256[] public productList;
    mapping(uint256 => uint256) public productListMap;
    // product id -> token -> cover amount
    mapping(uint256 => mapping(address => uint256)) public coverAmtPPPT;

    uint256 public coverAmtPPMaxRatio;
    uint256 public constant COVERAMT_PPMAX_RATIOBASE = 10000;

    // capital wise
    uint256 public scr;
    address public scrToken;
    mapping(address => uint256) public deltaCoverAmt; // should be reset when updating scr value
    uint256 public cap2CapacityRatio;
    uint256 public constant CAP2CAPACITY_RATIOBASE = 10000;
    address public baseToken;
    uint256 public mt;

    // token -> last expired amount update timestamp
    mapping(address => uint256) public tokenExpCvAmtUpdTimestampMap;

    // exchange rate
    address public exchangeRate;

    modifier allowedCaller() {
        require((SecurityMatrix(securityMatrix).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function setup(
        address _securityMatrix,
        address _feePoolAddress,
        address _premiumPoolAddress,
        address _claimToSettlementPool,
        address _stakersPoolV2,
        address _exchangeRate
    ) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        require(_feePoolAddress != address(0), "S:2");
        require(_premiumPoolAddress != address(0), "S:3");
        require(_claimToSettlementPool != address(0), "S:4");
        require(_stakersPoolV2 != address(0), "S:5");
        require(_exchangeRate != address(0), "S:6");
        securityMatrix = _securityMatrix;
        baseToken = Constant.BCNATIVETOKENADDRESS;
        scrToken = Constant.BCNATIVETOKENADDRESS;
        feePoolAddress = _feePoolAddress;
        premiumPoolAddress = _premiumPoolAddress;
        claimToSettlementPool = _claimToSettlementPool;
        stakersPoolV2 = _stakersPoolV2;
        exchangeRate = _exchangeRate;
    }

    function setData(uint256 _coverAmtPPMaxRatio, uint256 _premiumPayoutRatioX10000) external allowedCaller {
        coverAmtPPMaxRatio = _coverAmtPPMaxRatio;
        premiumPayoutRatioX10000 = _premiumPayoutRatioX10000;
    }

    event UpdateCap2CapacityRatioEvent(uint256 _cap2CapacityRatio);

    function updateCap2CapacityRatio(uint256 _cap2CapacityRatio) external allowedCaller {
        require(_cap2CapacityRatio > 0, "UPDC2CR:1");
        cap2CapacityRatio = _cap2CapacityRatio;

        emit UpdateCap2CapacityRatioEvent(_cap2CapacityRatio);
    }

    event UpdateMTEvent(address indexed _mtToken, uint256 _mtAmount);

    function updateMT(address _mtToken, uint256 _mtAmount) external allowedCaller {
        require(_mtToken == baseToken, "UPDMT:1");
        require(_mtAmount > 0, "UPDMT:2");
        mt = _mtAmount;

        emit UpdateMTEvent(_mtToken, _mtAmount);
    }

    event UpdateSCREvent(address indexed _scrToken, uint256 _scrAmount);

    function updateSCR(
        address _scrToken,
        uint256 _scrAmount,
        address[] memory _tokens,
        uint256[] memory _offsetAmounts
    ) external allowedCaller {
        require(_scrToken != address(0), "UPDSCR:1");
        require(_scrAmount > 0, "UPDSCR:2");
        require(_tokens.length == _offsetAmounts.length, "UPDSCR:3");

        scrToken = _scrToken;
        scr = _scrAmount;

        for (uint256 index = 0; index < _tokens.length; index++) {
            deltaCoverAmt[_tokens[index]] = deltaCoverAmt[_tokens[index]].sub(_offsetAmounts[index]);
        }

        emit UpdateSCREvent(_scrToken, _scrAmount);
    }

    event UpdateExpiredCoverAmountEvent(address indexed _token, uint256 _updateTimestamp, uint256 _productId, uint256 _amount);

    function updateExpiredCoverAmount(
        address _token,
        uint256 _updateTimestamp,
        uint256[] memory _products,
        uint256[] memory _amounts
    ) external allowedCaller {
        require(_token != address(0), "UPDECAMT:1");
        require(_products.length > 0, "UPDECAMT:2");
        require(_products.length == _amounts.length, "UPDECAMT:3");
        require(_updateTimestamp > tokenExpCvAmtUpdTimestampMap[_token], "UPDECAMT:4");

        tokenExpCvAmtUpdTimestampMap[_token] = _updateTimestamp;

        for (uint256 index = 0; index < _products.length; index++) {
            uint256 productId = _products[index];
            uint256 expiredAmount = _amounts[index];
            coverAmtPPPT[productId][_token] = coverAmtPPPT[productId][_token].sub(expiredAmount);

            emit UpdateExpiredCoverAmountEvent(_token, _updateTimestamp, productId, expiredAmount);
        }
    }

    function hasTokenInStakersPool(address _token) external view override returns (bool) {
        return stakersTokenDataMap[_token] == 1;
    }

    function addStakersPoolData(address _token) external onlyOwner {
        require(_token != address(0), "ASPD:1");
        require(stakersTokenDataMap[_token] != 1, "ASPD:2");
        stakersTokenDataMap[_token] = 1;
        stakersTokenData.push(_token);
    }

    function removeStakersPoolDataByIndex(uint256 _index) external onlyOwner {
        require(stakersTokenData.length > _index, "RSPDBI:1");
        address token = stakersTokenData[_index];
        delete stakersTokenDataMap[token];
        if (_index != stakersTokenData.length - 1) {
            stakersTokenData[_index] = stakersTokenData[stakersTokenData.length - 1];
        }
        stakersTokenData.pop();
    }

    function _getTokenToBase(address _tokenFrom, uint256 _amount) private view returns (uint256) {
        if (_tokenFrom == baseToken || _amount == 0) {
            return _amount;
        }
        return IExchangeRate(exchangeRate).getTokenToTokenAmount(_tokenFrom, baseToken, _amount);
    }

    function getStakingPercentageX10000() external view override returns (uint256) {
        uint256 nst = _getCapInBaseToken();
        return nst.mul(10**4).div(mt);
    }

    function getTVLinBaseToken() external view override returns (uint256) {
        return _getCapInBaseToken();
    }

    function _getCapInBaseToken() private view returns (uint256) {
        uint256 retVinBase = 0;

        uint256 poolLength = stakersTokenData.length;
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            retVinBase = retVinBase.add(_getTokenToBase(token, IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token)));
        }

        return retVinBase;
    }

    function _getDeltaCoverAmtInBaseToken() private view returns (uint256) {
        uint256 retVinBase = 0;
        for (uint256 tokenIndex = 0; tokenIndex < productCoverTokens.length; tokenIndex++) {
            address token = productCoverTokens[tokenIndex];
            uint256 temp = _getTokenToBase(token, deltaCoverAmt[token]);
            retVinBase = retVinBase.add(temp);
        }
        return retVinBase;
    }

    function getCapacityInfo() external view override returns (uint256, uint256) {
        return _getFreeCapacity();
    }

    function getProductCapacityInfo(uint256[] memory _products) external view returns (uint256, uint256[] memory) {
        (uint256 freeCapacity, uint256 totalCapacity) = _getFreeCapacity();
        uint256 maxCapacityOfOneProduct = Math.min(totalCapacity.mul(coverAmtPPMaxRatio).div(COVERAMT_PPMAX_RATIOBASE), freeCapacity);

        uint256[] memory usedCapacityOfProducts = new uint256[](_products.length);
        for (uint256 index = 0; index < _products.length; ++index) {
            usedCapacityOfProducts[index] = _getCoverAmtPPInBaseToken(_products[index]);
        }

        return (maxCapacityOfOneProduct, usedCapacityOfProducts);
    }

    function _getFreeCapacity() private view returns (uint256, uint256) {
        // capital
        uint256 capitalInBaseToken = _getCapInBaseToken();
        // - scr
        uint256 srcInBT = _getTokenToBase(scrToken, scr);
        uint256 deltaCoverAmtT = _getDeltaCoverAmtInBaseToken();
        if (capitalInBaseToken <= srcInBT.add(deltaCoverAmtT)) {
            return (0, srcInBT.add(deltaCoverAmtT));
        }
        uint256 capInBaseTokenAftSCR = capitalInBaseToken.sub(srcInBT);
        uint256 baseTokenFreeCapacityAftSCR = capInBaseTokenAftSCR.mul(cap2CapacityRatio).div(CAP2CAPACITY_RATIOBASE);
        return (baseTokenFreeCapacityAftSCR.sub(deltaCoverAmtT), baseTokenFreeCapacityAftSCR.add(srcInBT));
    }

    function getBaseToken() external view override returns (address) {
        return baseToken;
    }

    function getCoverAmtPPMaxRatio() external view override returns (uint256) {
        return coverAmtPPMaxRatio;
    }

    function getCoverAmtPPInBaseToken(uint256 _productId) external view override returns (uint256) {
        return _getCoverAmtPPInBaseToken(_productId);
    }

    function _getCoverAmtPPInBaseToken(uint256 _productId) private view returns (uint256) {
        uint256 retVinBase = 0;
        for (uint256 tokenIndex = 0; tokenIndex < productCoverTokens.length; tokenIndex++) {
            address token = productCoverTokens[tokenIndex];
            uint256 temp = _getTokenToBase(token, coverAmtPPPT[_productId][token]);
            retVinBase = retVinBase.add(temp);
        }
        return retVinBase;
    }

    function canBuyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external view override returns (bool) {
        uint256 coverAmtPPinBaseToken = _getCoverAmtPPInBaseToken(_productId);

        uint256 buyCurrencyAmtinBaseToken = _getTokenToBase(_token, _amount);

        (uint256 btFreeCapacity, uint256 btTotalCapacity) = _getFreeCapacity();
        if (buyCurrencyAmtinBaseToken.add(coverAmtPPinBaseToken) > btTotalCapacity.mul(coverAmtPPMaxRatio).div(COVERAMT_PPMAX_RATIOBASE)) {
            return false;
        }
        if (buyCurrencyAmtinBaseToken > btFreeCapacity) {
            return false;
        }
        return true;
    }

    function canBuyCover(uint256 _amount, address _token) external view override returns (bool) {
        uint256 buyCurrencyAmtinBaseToken = _getTokenToBase(_token, _amount);
        (uint256 btFreeCapacity, ) = _getFreeCapacity();

        if (buyCurrencyAmtinBaseToken > btFreeCapacity) {
            return false;
        }
        return true;
    }

    function buyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external override allowedCaller {
        if (productListMap[_productId] == 0) {
            productList.push(_productId);
            productListMap[_productId] = 1;
        }
        if (productCoverTokensMap[_token] == 0) {
            productCoverTokens.push(_token);
            productCoverTokensMap[_token] = 1;
        }
        coverAmtPPPT[_productId][_token] = coverAmtPPPT[_productId][_token].add(_amount);
        deltaCoverAmt[_token] = deltaCoverAmt[_token].add(_amount);
    }

    function _getExactToken2PaymentToken(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amount
    ) private view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        if (_tokenFrom == _tokenTo) {
            return _amount;
        }
        uint256 ret = IExchangeRate(exchangeRate).getTokenToTokenAmount(_tokenFrom, _tokenTo, _amount);
        require(ret != 0, "_GET2PT:1");
        return ret;
    }

    function _settleExactPayoutFromStakers(
        address _paymentToken,
        uint256 _settleAmt,
        address _claimTo,
        uint256 _claimId
    ) private {
        uint256 settleAmount = _settleAmt;
        uint256 amountInPaymentToken = 0;
        uint256[] memory tempPaymentTokenPerPool = new uint256[](stakersTokenData.length);
        uint256 poolLength = stakersTokenData.length;

        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            uint256 temp = _getExactToken2PaymentToken(token, _paymentToken, IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token));
            tempPaymentTokenPerPool[poolLengthIndex] = temp;
            amountInPaymentToken = amountInPaymentToken.add(temp);
        }

        // weight calc
        uint256[] memory settlePaymentPerPool = new uint256[](stakersTokenData.length);
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            if (poolLengthIndex == poolLength.sub(1)) {
                settlePaymentPerPool[poolLengthIndex] = settleAmount;
                break;
            }
            uint256 tempSettlePerPool = _settleAmt.mul(tempPaymentTokenPerPool[poolLengthIndex]).mul(10**10);
            tempSettlePerPool = tempSettlePerPool.div(amountInPaymentToken).div(10**10);
            settlePaymentPerPool[poolLengthIndex] = tempSettlePerPool;
            require(settleAmount >= tempSettlePerPool, "_SEPFS:1");
            settleAmount = settleAmount.sub(tempSettlePerPool);
        }

        // calc back to in amount and currency
        for (uint256 poolLengthIndex = 0; poolLengthIndex < poolLength; poolLengthIndex++) {
            address token = stakersTokenData[poolLengthIndex];
            if (settlePaymentPerPool[poolLengthIndex] == 0) {
                continue;
            }
            uint256 fromRate = IStakersPoolV2(stakersPoolV2).getStakedAmountPT(token);
            uint256 toRate = tempPaymentTokenPerPool[poolLengthIndex];
            if (toRate == 0) {
                continue;
            }
            IStakersPoolV2(stakersPoolV2).claimPayout(token, _paymentToken, settlePaymentPerPool[poolLengthIndex], _claimTo, _claimId, fromRate, toRate);
        }
    }

    function settlePaymentForClaim(
        address _token,
        uint256 _amount,
        uint256 _claimId
    ) external override allowedCaller {
        require(_amount > 0, "PPFC:1");

        uint256 premiumPayoutRatioAmt = IPremiumPool(premiumPoolAddress).getPremiumPoolAmtInPaymentToken(_token);

        premiumPayoutRatioAmt = premiumPayoutRatioAmt.mul(premiumPayoutRatioX10000).div(10**4);

        uint256 paymentToSettle = _amount;
        if (premiumPayoutRatioAmt != 0) {
            uint256 settleAmt = Math.min(premiumPayoutRatioAmt, _amount);

            uint256 remainAmt = IPremiumPool(premiumPoolAddress).settlePayoutFromPremium(_token, settleAmt, claimToSettlementPool);
            require(settleAmt >= remainAmt, "PPFC:2");
            require(paymentToSettle >= settleAmt.sub(remainAmt), "PPFC:3");
            paymentToSettle = paymentToSettle.sub(settleAmt.sub(remainAmt));
        }
        if (paymentToSettle == 0) {
            return;
        }
        // settle from stakers pools

        _settleExactPayoutFromStakers(_token, paymentToSettle, claimToSettlementPool, _claimId);
    }
}
