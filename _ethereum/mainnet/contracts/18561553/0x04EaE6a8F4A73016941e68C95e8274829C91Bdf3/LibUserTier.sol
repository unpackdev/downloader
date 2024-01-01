// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IGovTier.sol";
import "./LibGovTierStorage.sol";
import "./LibGovNFTTierStorage.sol";
import "./LibVCTierStorage.sol";
import "./LibAppStorage.sol";

library LibUserTier {
    function validateGovHoldingTierForToken(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibGovTierStorage.TierData memory _tierData
    ) internal pure returns (uint256) {
        if (_stakedCollateralTokens.length == 1) {
            require(_tierData.singleToken, "single token not allowed");
        } else {
            require(_tierData.multiToken, "multi token not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibGovNFTTierStorage.NFTTierData memory _nftTierData
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_nftTierData.traditionalTier);

        //start validatting loan offer
        if (_stakedCollateralTokens.length == 1) {
            require(
                traditionalTierData.singleToken,
                "single token not allowed"
            );
        } else {
            require(traditionalTierData.multiToken, "multi token not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTSpTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibGovNFTTierStorage.NFTTierData memory _nftTierData,
        LibGovNFTTierStorage.SingleSPTierData memory _nftSpTier
    ) internal pure returns (uint256) {
        if (_stakedCollateralTokens.length > 1 && !_nftSpTier.singleToken) {
            //only single token allowed for sp tier, and having no single token in your current tier
            return 5;
        }

        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }

        bool found = false;

        for (uint256 c = 0; c < _stakedCollateralTokens.length; c++) {
            if (_stakedCollateralTokens[c] == _nftTierData.spToken) {
                found = true;
            }

            for (uint256 x = 0; x < _nftTierData.allowedSuns.length; x++) {
                if (
                    //collateral can be either approved sun token or associated sp token
                    _stakedCollateralTokens[c] == _nftTierData.allowedSuns[x]
                ) {
                    //collateral can not be other then sp token or approved sun tokens
                    found = true;
                }
            }
            if (!found) {
                //can not be other then approved sun Tokens or approved SP token
                return 7;
            }
        }
        return 200;
    }

    function validateVCTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibVCTierStorage.VCNFTTier memory _vcTier
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_vcTier.traditionalTier);

        if (_stakedCollateralTokens.length == 1) {
            require(
                traditionalTierData.singleToken,
                "single token not allowed"
            );
        } else {
            require(traditionalTierData.multiToken, "multi token not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier, loan amount is greater than max loan amount
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralTokens.length; j++) {
            bool found = false;

            uint256 spTokenLength = _vcTier.spAllowedTokens.length;
            for (uint256 a = 0; a < spTokenLength; a++) {
                if (_stakedCollateralTokens[j] == _vcTier.spAllowedTokens[a]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp tokens or approved sun tokens
                return 7;
            }
        }

        return 200;
    }

    function validateGovHoldingTierForNFT(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibGovTierStorage.TierData memory _tierData
    ) internal pure returns (uint256) {
        //user has gov tier level
        //start validatting loan offer
        if (_stakedCollateralNFTs.length == 1) {
            require(_tierData.singleNFT, "single nft not allowed");
        } else {
            require(_tierData.multiNFT, "multi nft not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv, loan amount is greater than max loan amount
            return 3;
        }

        return 200;
    }

    function validateNFTTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibGovNFTTierStorage.NFTTierData memory _nftTierData
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (_stakedCollateralNFTs.length == 1) {
            require(traditionalTierData.singleNFT, "single nft not allowed");
        } else {
            require(traditionalTierData.multiNFT, "multi nft not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTSpTierforNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibGovNFTTierStorage.NFTTierData memory _nftTierData,
        LibGovNFTTierStorage.SingleSPTierData memory _nftSpTier
    ) internal pure returns (uint256) {
        if (_stakedCollateralNFTs.length > 1 && !_nftSpTier.singleToken) {
            //only single nft or single token allowed for sp tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }

        for (uint256 c = 0; c < _stakedCollateralNFTs.length; c++) {
            bool found = false;

            for (uint256 x = 0; x < _nftTierData.allowedNfts.length; x++) {
                if (_stakedCollateralNFTs[c] == _nftTierData.allowedNfts[x]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    function validateVCTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibVCTierStorage.VCNFTTier memory _vcTier
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_vcTier.traditionalTier);

        if (_stakedCollateralNFTs.length == 1) {
            require(traditionalTierData.singleNFT, "single nft not allowed");
        } else {
            require(traditionalTierData.multiNFT, "multi nft not allowed");
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralNFTs.length; j++) {
            bool found = false;

            uint256 spNFTLength = _vcTier.spAllowedNFTs.length;
            for (uint256 a = 0; a < spNFTLength; a++) {
                if (_stakedCollateralNFTs[j] == _vcTier.spAllowedNFTs[a]) {
                    //collateral can not be other then sp nft
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) internal pure returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }
}
