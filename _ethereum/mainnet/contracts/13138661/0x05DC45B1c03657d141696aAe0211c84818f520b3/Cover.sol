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

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ISecurityMatrix.sol";
import "./Math.sol";
import "./Constant.sol";
import "./ICoverConfig.sol";
import "./ICoverData.sol";
import "./ICoverQuotation.sol";
import "./ICapitalPool.sol";
import "./IPremiumPool.sol";
import "./IExchangeRate.sol";
import "./IReferralProgram.sol";
import "./IProduct.sol";
import "./ICover.sol";

contract Cover is ICover, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // the security matrix address
    address public smx;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the cover quotation address
    address public quotation;
    // the capital pool address
    address public capitalPool;
    // the premium pool address
    address public premiumPool;
    // the insur token address
    address public insur;

    // buy cover maxmimum block number latency
    uint256 public buyCoverMaxBlkNumLatency;
    // buy cover signer flag map (signer -> true/false)
    mapping(address => bool) public buyCoverSignerFlagMap;
    // buy cover owner nonce flag map (owner -> nonce -> true/false)
    mapping(address => mapping(uint256 => bool)) public buyCoverNonceFlagMap;

    // the exchange rate address
    address public exchangeRate;

    // the referral program address
    address public referralProgram;

    // the product address
    address public product;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setup(
        address securityMatrixAddress,
        address insurTokenAddress,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _coverQuotationAddress,
        address _capitalPool,
        address _premiumPool,
        address _exchangeRate,
        address _referralProgram,
        address _productAddress
    ) external onlyOwner {
        require(securityMatrixAddress != address(0), "S:1");
        require(insurTokenAddress != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_coverQuotationAddress != address(0), "S:5");
        require(_capitalPool != address(0), "S:6");
        require(_premiumPool != address(0), "S:7");
        require(_exchangeRate != address(0), "S:8");
        require(_referralProgram != address(0), "S:9");
        require(_productAddress != address(0), "S:10");
        smx = securityMatrixAddress;
        insur = insurTokenAddress;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        quotation = _coverQuotationAddress;
        capitalPool = _capitalPool;
        premiumPool = _premiumPool;
        exchangeRate = _exchangeRate;
        referralProgram = _referralProgram;
        product = _productAddress;
    }

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        override
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        )
    {
        require(products.length == durationInDays.length, "GPCHK: 1");
        require(products.length == amounts.length, "GPCHK: 2");

        // check if the currency is a valid premium currency
        require(ICoverConfig(cfg).isValidCurrency(currency), "GPCHK: 3");

        // check the owner and referrer addresses
        require(owner != address(0), "GPCHK: 4");
        require(address(uint160(referralCode)) != address(0), "GPCHK: 5");

        // check if each amount is within the individual capacity
        uint256[] memory helperParameters = new uint256[](2);
        helperParameters[0] = 0;
        helperParameters[1] = 0;
        for (uint256 i = 0; i < products.length; i++) {
            helperParameters[0] = helperParameters[0].add(amounts[i]);
            helperParameters[1] = helperParameters[1].add(amounts[i].mul(durationInDays[i]));
            require(ICapitalPool(capitalPool).canBuyCoverPerProduct(products[i], amounts[i], currency), "GPCHK: 6");
        }

        // check if the total amount is within the overall capacity (ETH/DAI, from Capital Pool)
        require(ICapitalPool(capitalPool).canBuyCover(helperParameters[0], currency), "GPCHK: 7");

        // check and calculate the cover premium amount
        uint256 premiumAmount = 0;
        uint256 discountPercent = 0;
        (premiumAmount, discountPercent) = ICoverQuotation(quotation).getPremium(products, durationInDays, amounts, currency);
        require(premiumAmount > 0, "GPCHK: 8");

        // check the Cover Owner and Referral Reward Percentages (its length is 2)
        require(rewardPercentages.length == 2, "GPCHK: 9");
        uint256[] memory insurRewardAmounts = new uint256[](2);

        // calculate the Cover Owner and Referral Reward amounts
        uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, insur, premiumAmount);
        if (premiumAmount2Insur > 0 && owner != address(uint160(referralCode))) {
            // estimate the Cover Owner INSUR Reward Amount
            uint256 coverOwnerRewardPctg = _getRewardPctg(rewardPercentages[0]);
            insurRewardAmounts[0] = _getRewardAmount(premiumAmount2Insur, coverOwnerRewardPctg);
            // estimate the Referral INSUR Reward Amount
            uint256 referralRewardPctg = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, rewardPercentages[1]);
            insurRewardAmounts[1] = IReferralProgram(referralProgram).getRewardAmount(Constant.REFERRALREWARD_COVER, premiumAmount2Insur, referralRewardPctg);
        } else {
            // there is no INSUR reward amounts if no valid premium value or referrer
            insurRewardAmounts[0] = 0;
            insurRewardAmounts[1] = 0;
        }

        return (premiumAmount, helperParameters, discountPercent, insurRewardAmounts);
    }

    event BuyCoverEvent(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, uint256 estimatedPremium, uint256 coverStatus);

    event BuyCoverEventV2(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, uint256 estimatedPremium, uint256 coverStatus, uint256 delayEffectiveDays);

    event BuyCoverOwnerRewardEvent(address indexed owner, uint256 rewardPctg, uint256 insurRewardAmt);

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable override whenNotPaused nonReentrant {
        // check the number of cover details
        require(products.length == durationInDays.length, "BC: 1");
        require(products.length == amounts.length, "BC: 2");

        // check if the currency is a valid premium currency
        require(ICoverConfig(cfg).isValidCurrency(currency), "BC: 3");

        // check the beneficiary address list (its length is 2)
        require(owner != address(0), "BC: 4");
        require(address(uint160(referralCode)) != address(0), "BC: 5");

        // check the helper parameters (its length is 4)
        // helperParameters[0] -> totalAmounts (the sum of cover amounts)
        // helperParameters[1] -> totalWeight (the sum of cover amounts multipled by cover durations)
        // helperParameters[2] -> coverOwnerRewardPctg (the cover owner reward perentageX10000 of premium, 0 if not set)
        // helperParameters[3] -> referralRewardPctg (the referral reward perentageX10000 of premium, 0 if not set)
        require(helperParameters.length == 4, "BC: 6");

        // check the security parameters (its length is 2)
        // securityParameters[0] -> blockNumber (the block number when the signature is generated off-chain)
        // securityParameters[1] -> nonce (the nonce of the cover owner, can be timestamp in seconds)
        require(securityParameters.length == 2, "BC: 7");

        // check the block number latency
        require((block.number >= securityParameters[0]) && (block.number - securityParameters[0] <= buyCoverMaxBlkNumLatency), "BC: 8");

        // check the signature
        require(_checkSignature(address(this), products, durationInDays, amounts, currency, owner, referralCode, premiumAmount, helperParameters, securityParameters, v, r, s), "BC: 9");

        // check the cover owner nonce flag
        require(!buyCoverNonceFlagMap[owner][securityParameters[1]], "BC: 10");
        buyCoverNonceFlagMap[owner][securityParameters[1]] = true;

        // check and receive the premium from this transaction
        if (currency == Constant.BCNATIVETOKENADDRESS) {
            require(premiumAmount <= msg.value, "BC: 11");
            IPremiumPool(premiumPool).addPremiumAmount{value: premiumAmount}(currency, premiumAmount);
        } else {
            require(IERC20Upgradeable(currency).balanceOf(_msgSender()) >= premiumAmount, "BC: 12");
            require(IERC20Upgradeable(currency).allowance(_msgSender(), address(this)) >= premiumAmount, "BC: 13");
            IERC20Upgradeable(currency).safeTransferFrom(_msgSender(), address(this), premiumAmount);
            IERC20Upgradeable(currency).safeTransfer(premiumPool, premiumAmount);
            IPremiumPool(premiumPool).addPremiumAmount(currency, premiumAmount);
        }

        // process the cover creation and reward distribution
        _processCovers(products, durationInDays, amounts, currency, owner, referralCode, premiumAmount, helperParameters);
    }

    function _checkSignature(
        address scAddress,
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) internal view returns (bool) {
        bytes32 msgHash = "msgHash";
        {
            bytes memory msg1 = abi.encodePacked(scAddress, products, durationInDays, amounts, currency);
            bytes memory msg2 = abi.encodePacked(owner, referralCode, premiumAmount, helperParameters, securityParameters);
            msgHash = keccak256(abi.encodePacked(msg1, msg2));
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        address signer1 = ecrecover(prefixedHash, v[0], r[0], s[0]);
        return buyCoverSignerFlagMap[signer1];
    }

    function _processCovers(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters
    ) internal {
        uint256 ownerRewardPctg = 0;
        uint256 referralRewardPctg = 0;

        // check and give out the insur token reward if there is any referrer
        if (owner != address(uint160(referralCode))) {
            uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, insur, premiumAmount);
            // distribute the cover owner reward
            ownerRewardPctg = _getRewardPctg(helperParameters[2]);
            _processCoverOwnerReward(owner, premiumAmount2Insur, ownerRewardPctg);
            // distribute the referral reward if the referrer address is not the owner address
            referralRewardPctg = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, helperParameters[3]);
            IReferralProgram(referralProgram).processReferralReward(address(uint160(referralCode)), owner, Constant.REFERRALREWARD_COVER, premiumAmount2Insur, referralRewardPctg);
        }

        // create the expanded cover records (one per each cover item)
        uint256[] memory capacities = new uint256[](2);
        (capacities[0], capacities[1]) = ICapitalPool(capitalPool).getCapacityInfo();
        _createCovers(owner, currency, premiumAmount, products, durationInDays, amounts, capacities, helperParameters, ownerRewardPctg, referralRewardPctg);
    }

    function _createCovers(
        address owner,
        address currency,
        uint256 premiumAmount,
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory capacities,
        uint256[] memory helperParameters,
        uint256 ownerRewardPctg,
        uint256 referralRewardPctg
    ) internal {
        require(IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, ICapitalPool(capitalPool).getBaseToken(), helperParameters[0]) <= capacities[0], "BCC: 1");
        uint256 cumPremiumAmount = 0;
        for (uint256 index = 0; index < products.length; ++index) {
            require(IExchangeRate(exchangeRate).getTokenToTokenAmount(currency, ICapitalPool(capitalPool).getBaseToken(), amounts[index]).add(ICapitalPool(capitalPool).getCoverAmtPPInBaseToken(products[index])) <= capacities[1].mul(ICapitalPool(capitalPool).getCoverAmtPPMaxRatio()).div(10000), "BCC: 2");
            ICapitalPool(capitalPool).buyCoverPerProduct(products[index], amounts[index], currency);

            uint256 estimatedPremium = 0;
            if (index == products.length.sub(1)) {
                estimatedPremium = premiumAmount.sub(cumPremiumAmount);
            } else {
                uint256 currentWeight = amounts[index].mul(durationInDays[index]);
                estimatedPremium = currentWeight.mul(10000).div(helperParameters[1]).mul(premiumAmount).div(10000);
                cumPremiumAmount = cumPremiumAmount.add(estimatedPremium);
            }

            _createOneCover(owner, currency, products[index], durationInDays[index], amounts[index], estimatedPremium, ownerRewardPctg, referralRewardPctg);
        }
    }

    function _createOneCover(
        address owner,
        address currency,
        uint256 productId,
        uint256 durationInDays,
        uint256 amount,
        uint256 estimatedPremium,
        uint256 ownerRewardPctg,
        uint256 referralRewardPctg
    ) internal {
        uint256 beginTimestamp = block.timestamp.add(IProduct(product).getProductDelayEffectiveDays(productId) * 1 days); // solhint-disable-line not-rely-on-time
        uint256 endTimestamp = beginTimestamp.add(durationInDays * 1 days);
        uint256 nextCoverId = ICoverData(data).increaseCoverCount(owner);
        ICoverData(data).setNewCoverDetails(owner, nextCoverId, productId, amount, currency, beginTimestamp, endTimestamp, endTimestamp.add(ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired() * 1 days), estimatedPremium);

        if (ownerRewardPctg > 0) {
            ICoverData(data).setCoverRewardPctg(owner, nextCoverId, ownerRewardPctg);
        }

        if (referralRewardPctg > 0) {
            ICoverData(data).setCoverReferralRewardPctg(owner, nextCoverId, referralRewardPctg);
        }

        uint256 delayEffectiveDays = IProduct(product).getProductDelayEffectiveDays(productId);
        emit BuyCoverEventV2(currency, owner, nextCoverId, productId, durationInDays, ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired(), amount, estimatedPremium, Constant.COVERSTATUS_ACTIVE, delayEffectiveDays);
    }

    event UnlockCoverRewardEvent(address indexed owner, uint256 amount);

    function unlockRewardByController(address _owner, address _to) external override allowedCaller whenNotPaused nonReentrant returns (uint256) {
        return _unlockReward(_owner, _to);
    }

    function _unlockReward(address owner, address to) internal returns (uint256) {
        uint256 toBeunlockedAmt = ICoverData(data).getBuyCoverInsurTokenEarned(owner);
        if (toBeunlockedAmt > 0) {
            ICoverData(data).decreaseTotalInsurTokenRewardAmount(toBeunlockedAmt);
            ICoverData(data).decreaseBuyCoverInsurTokenEarned(owner, toBeunlockedAmt);
            IERC20Upgradeable(insur).safeTransfer(to, toBeunlockedAmt);
            emit UnlockCoverRewardEvent(owner, toBeunlockedAmt);
        }
        return toBeunlockedAmt;
    }

    function getRewardAmount() external view override returns (uint256) {
        return ICoverData(data).getBuyCoverInsurTokenEarned(_msgSender());
    }

    function getCoverOwnerRewardAmount(uint256 premiumAmount2Insur, uint256 overwrittenRewardPctg) external view override returns (uint256, uint256) {
        uint256 rewardPctg = _getRewardPctg(overwrittenRewardPctg);
        uint256 rewardAmount = _getRewardAmount(premiumAmount2Insur, rewardPctg);
        return (rewardPctg, rewardAmount);
    }

    function _getRewardPctg(uint256 overwrittenRewardPctg) internal view returns (uint256) {
        return overwrittenRewardPctg > 0 ? overwrittenRewardPctg : ICoverConfig(cfg).getInsurTokenRewardPercentX10000();
    }

    function _getRewardAmount(uint256 premiumAmount2Insur, uint256 rewardPctg) internal pure returns (uint256) {
        return rewardPctg <= 10000 ? premiumAmount2Insur.mul(rewardPctg).div(10**4) : 0;
    }

    function _processCoverOwnerReward(
        address owner,
        uint256 premiumAmount2Insur,
        uint256 rewardPctg
    ) internal {
        require(rewardPctg <= 10000, "PCORWD: 1");
        uint256 rewardAmount = _getRewardAmount(premiumAmount2Insur, rewardPctg);
        if (rewardAmount > 0) {
            ICoverData(data).increaseTotalInsurTokenRewardAmount(rewardAmount);
            ICoverData(data).increaseBuyCoverInsurTokenEarned(owner, rewardAmount);
            emit BuyCoverOwnerRewardEvent(owner, rewardPctg, rewardAmount);
        }
    }

    function getINSURRewardBalanceDetails() external view override returns (uint256, uint256) {
        uint256 insurRewardBalance = IERC20Upgradeable(insur).balanceOf(address(this));
        uint256 totalRewardRequired = ICoverData(data).getTotalInsurTokenRewardAmount();
        return (insurRewardBalance, totalRewardRequired);
    }

    function removeINSURRewardBalance(address toAddress, uint256 amount) external override onlyOwner {
        IERC20Upgradeable(insur).safeTransfer(toAddress, amount);
    }

    event SetBuyCoverMaxBlkNumLatencyEvent(uint256 numOfBlocks);

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external override onlyOwner {
        require(numOfBlocks > 0, "SBCMBNL: 1");
        buyCoverMaxBlkNumLatency = numOfBlocks;
        emit SetBuyCoverMaxBlkNumLatencyEvent(numOfBlocks);
    }

    event SetBuyCoverSignerEvent(address indexed signer, bool enabled);

    function setBuyCoverSigner(address signer, bool enabled) external override onlyOwner {
        require(signer != address(0), "SBCS: 1");
        buyCoverSignerFlagMap[signer] = enabled;
        emit SetBuyCoverSignerEvent(signer, enabled);
    }
}
