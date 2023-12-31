// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Fee.sol";
import "./NftCostData.sol";
import "./IDittoPool.sol";
import "./DittoPool.sol";
import "./CurveErrorCode.sol";
import "./FixedPointMathLib.sol";
import "./IUpshotOracle.sol";
import "./DittoPoolTrade.sol";


/**
 * @title Ditto Pool Appraisal Curve
 */
contract DittoPoolApp is DittoPool {
    using FixedPointMathLib for uint256;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoPoolAppUpdatePriceMaxBuy(uint256 priceMaxBuy);
    event DittoPoolAppUpdatePriceMinSell(uint256 priceMinSell);
    event DittoPoolAppraisalInitializedWithOracle(address oracle);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoPoolAppInvalidTokenPrice();
    error DittoPoolAppraisalIncorrectToken();
    error DittoPoolAppraisalIncorrectCollection();

    // ***************************************************************
    // * ========================= ORACLE ========================== *
    // ***************************************************************
    IUpshotOracle internal _oracle;

    /**
     * View function for the oracle
     * 
     * @return oracle The oracle address
     */
    function oracle() public view returns (IUpshotOracle) {
        return _oracle;
    }
    
    ///@dev Minimum price to sell a token out of the pool
    uint256 internal _priceMinSell;

    ///@dev Maximum price to buy a token for the pool, a given LP position
    uint256 internal _priceMaxBuy;

    /**
     * @param priceMaxBuy_ The maximum price to buy a token for the pool, a given LP position
     */
    function changePriceMaxBuy(uint256 priceMaxBuy_) external onlyOwner {
        _changePriceMaxBuy(priceMaxBuy_);
    }

    /**
     * @param priceMinSell_ The minimum price to sell a token out of the pool
     */
    function changePriceMinSell(uint256 priceMinSell_) external onlyOwner {
        _changePriceMinSell(priceMinSell_);
    }

    ///@notice Internal helper function to change the priceMaxBuy
    function _changePriceMaxBuy(uint256 priceMaxBuy_) private {
        _priceMaxBuy = priceMaxBuy_;
        emit DittoPoolAppUpdatePriceMaxBuy(_priceMaxBuy);
    }

    ///@notice Internal helper function to change the priceMinSell
    function _changePriceMinSell(uint256 priceMinSell_) private {
        _priceMinSell = priceMinSell_;
        emit DittoPoolAppUpdatePriceMinSell(_priceMinSell);
    }

    /**
     * @dev View function for the priceMaxBuy
     */
    function priceMaxBuy() external view returns (uint256 priceMaxBuy_) {
        priceMaxBuy_ = _priceMaxBuy;
    }

    /**
     * @dev View function for the priceMinSell
     */
    function priceMinSell() external view returns (uint256 priceMinSell_) {
        priceMinSell_ = _priceMinSell;
    }

    /**
     * @dev Custom initialization function for the Ditto Pool Appraisal Curve to initialize the 
     *   appraisal oracle address
     * 
     * @param templateInitData_ The oracle address encoded in bytes
     */
    function _initializeCustomPoolData(bytes calldata templateInitData_) internal override {
        (
            address oracle_, 
            uint256 priceMinSell_,
            uint256 priceMaxBuy_
        ) = abi.decode(templateInitData_, (address, uint256, uint256));
        _oracle = IUpshotOracle(oracle_);
        _changePriceMinSell(priceMinSell_);
        _changePriceMaxBuy(priceMaxBuy_);

        emit DittoPoolAppraisalInitializedWithOracle(address(_oracle));
    }

    // ***************************************************************
    // * ================== CURVE IMPLEMENTATION =================== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function bondingCurve() public pure virtual override (IDittoPool) returns (string memory curve) {
        return "Curve: APP";
    }

    /**
     * @dev See {DittPool-_validateDelta}
     */
    function _invalidDelta(uint128 /*delta*/) internal pure override returns (bool valid) {
        return false;
    }

    /**
     * @dev See {DittPool-_validateBasePrice}
     */
    function _invalidBasePrice(uint128 /*newBasePrice*/) internal pure override returns (bool) {
        return false;
    }


    function _decodeTokenPrices(
        PriceData[] memory tokenPriceData_
    ) internal returns (uint256[] memory tokenPrices) {

        uint256 tokenPriceDataCount = tokenPriceData_.length;

        tokenPrices = new uint256[](tokenPriceDataCount);

        if (tokenPriceDataCount == 0) {
            return tokenPrices;
        }

        for(uint256 i = 0; i < tokenPriceDataCount;) {
            if (tokenPriceData_[i].nft != address(_nft)) {
                revert DittoPoolAppraisalIncorrectCollection();
            }

            if (tokenPriceData_[i].token != address(_token)) {
                revert DittoPoolAppraisalIncorrectToken();
            }

            unchecked {
                ++i;
            }
        }

        tokenPrices = _oracle.decodeTokenPrices(tokenPriceData_);
    }

    /**
     * @dev See {DittPool-_getBuyInfo}
     */
    function _getBuyInfo(
        uint128 /*basePrice*/,
        uint128 /*delta*/,
        uint256 numItems,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        )
    {
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        if (swapData_.length == 0) {
            return (CurveErrorCode.MISSING_SWAP_DATA, 0, 0, 0, nftCostData);
        }

        PriceData[] memory tokenPriceData = abi.decode(swapData_, (PriceData[]));

        if (tokenPriceData.length != numItems) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        uint256[] memory tokenPrices = _decodeTokenPrices(tokenPriceData);

        nftCostData = new NftCostData[](numItems);
        uint256 tokenPrice;
        Fee memory calculatedFees;

        for (uint256 i = 0; i < numItems;) {
            tokenPrice = tokenPrices[i];

            ///@notice appraised price is less than that at which the admin 
            /// has specified the pool will sell out an nft
            if(tokenPrice < _priceMinSell) {
                revert DittoPoolAppInvalidTokenPrice();
            }

            calculatedFees = Fee({
                lp: _mul(tokenPrice, fee_.lp),
                protocol: _mul(tokenPrice, fee_.protocol),
                admin: _mul(tokenPrice, fee_.admin)
            });

            nftCostData[i] = NftCostData({
                specificNftId: true,
                nftId: tokenPriceData[i].nftId,
                price: tokenPrice,
                fee: calculatedFees
            });
            
            inputValue += 
                tokenPrice + 
                calculatedFees.lp +
                calculatedFees.protocol +
                calculatedFees.admin;

            unchecked {
                ++i;
            }
        }

        // If we got all the way here, no math error happened
        error = CurveErrorCode.OK;
    }

    /**
     *  @dev See {DittPool-_getSellInfo}
     */
    function _getSellInfo(
        uint128 /*basePrice*/,
        uint128 /*delta*/,
        uint256 numItems,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 outputValue,
            NftCostData[] memory nftCostData
        )
    {
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        if (swapData_.length == 0) {
            return (CurveErrorCode.MISSING_SWAP_DATA, 0, 0, 0, nftCostData);
        }

        PriceData[] memory tokenPriceData = abi.decode(swapData_, (PriceData[]));

        if (tokenPriceData.length != numItems) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        uint256[] memory tokenPrices = _decodeTokenPrices(tokenPriceData);

        nftCostData = new NftCostData[](numItems);

        Fee memory calculatedFees;
        uint256 tokenPrice;

        for (uint256 i = 0; i < numItems;) {
            tokenPrice = tokenPrices[i];

            ///@notice appraised value is greater than that at which the admin 
            ///has specified the pool will buy an nft
            if(tokenPrice > _priceMaxBuy) {
                revert DittoPoolAppInvalidTokenPrice();
            }

            calculatedFees = Fee({
                lp: _mul(tokenPrice, fee_.lp),
                protocol: _mul(tokenPrice, fee_.protocol),
                admin: _mul(tokenPrice, fee_.admin)
            });

            nftCostData[i] = NftCostData({
                specificNftId: true,
                nftId: tokenPriceData[i].nftId,
                price: tokenPrice,
                fee: calculatedFees
            }); 

            outputValue += 
                tokenPrice - 
                (
                    calculatedFees.lp +
                    calculatedFees.protocol +
                    calculatedFees.admin
                );

            unchecked {
                ++i;
            }
        }

        // If we got all the way here, no math error happened
        error = CurveErrorCode.OK;
    }

    function getBuyNftQuote(uint256 /* numNfts_ */, bytes calldata /* swapData_ */)
        external
        pure
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        )
    {
        NftCostData[] memory nftCostData_;
        return (CurveErrorCode.NOOP, 0, 0, 0, nftCostData_);
    }


    function getSellNftQuote(uint256 /* numNfts_ */, bytes calldata /* swapData_ */)
        external
        pure
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        )
    {
        NftCostData[] memory nftCostData_;
        return (CurveErrorCode.NOOP, 0, 0, 0, nftCostData_);
    }
}
