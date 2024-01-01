// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IGovTier.sol";
import "./IGovNFTTier.sol";
import "./IVCTier.sol";
import "./LibAppStorage.sol";
import "./LibGovTierStorage.sol";
import "./LibUserTier.sol";
import "./LibGovNFTTierStorage.sol";
import "./LibVCTierStorage.sol";
import "./LibMarketStorage.sol";

contract UserTierFacet is Modifiers {
    /// @dev this function returns the tierLevel data by user's Gov Token Balance or without gov balance (if super admin assign tier to some user without gove balance) check else logic in this function
    /// @param userWalletAddress user address for check tier level data

    function getTierDatabyGovBalance(
        address userWalletAddress
    ) external view returns (LibGovTierStorage.TierData memory _tierData) {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            s.govGovToken != address(0x0),
            "GTL: gov gToken not Configured"
        );
        uint256 userGovBalance = IERC20(s.govToken).balanceOf(
            userWalletAddress
        ) + IERC20(s.govGovToken).balanceOf(userWalletAddress);

        bytes32[] memory tierKeys = IGovTier(address(this))
            .getGovTierLevelKeys();
        uint256 lengthTierLevels = tierKeys.length;

        if (
            userGovBalance >=
            IGovTier(address(this)).getSingleTierData(tierKeys[0]).govHoldings
        ) {
            return
                tierDatabyGovBalance(
                    userGovBalance,
                    lengthTierLevels,
                    tierKeys
                );
        } else {
            bytes32 tier = IGovTier(address(this)).getWalletTier(
                userWalletAddress
            );

            return IGovTier(address(this)).getSingleTierData(tier);
        }
    }

    function tierDatabyGovBalance(
        uint256 _userGovBalance,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (LibGovTierStorage.TierData memory _tierData) {
        if (
            _userGovBalance >=
            IGovTier(address(this))
                .getSingleTierData(_tierKeys[_lengthTierLevels - 1])
                .govHoldings
        ) {
            return
                IGovTier(address(this)).getSingleTierData(
                    _tierKeys[_lengthTierLevels - 1]
                );
        }

        for (uint256 i = 1; i < _lengthTierLevels; i++) {
            if (
                (_userGovBalance >=
                    IGovTier(address(this))
                        .getSingleTierData(_tierKeys[i - 1])
                        .govHoldings) &&
                (_userGovBalance <
                    IGovTier(address(this))
                        .getSingleTierData(_tierKeys[i])
                        .govHoldings)
            ) {
                return
                    IGovTier(address(this)).getSingleTierData(_tierKeys[i - 1]);
            }
        }
    }

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256) {
        return
            LibUserTier.getMaxLoanAmount(
                _collateralTokeninStable,
                _tierLevelLTVPercentage
            );
    }

    /// @dev returns the max loan amount to value
    /// @param _collateralTokeninStable value of collateral in stable token
    /// @param _borrower address of the borrower
    /// @return maxLoanAmount returns the max loan amount in stable token
    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256 maxLoanAmount) {
        if (_tierType == LibMarketStorage.TierType.GOV_TIER) {
            LibGovTierStorage.TierData memory tierData = this
                .getTierDatabyGovBalance(_borrower);
            maxLoanAmount =
                (_collateralTokeninStable * tierData.loantoValue) /
                100;
        } else if (_tierType == LibMarketStorage.TierType.NFT_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_borrower);

            LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
                address(this)
            ).getSingleTierData(nftTier.traditionalTier);
            maxLoanAmount =
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (_tierType == LibMarketStorage.TierType.NFT_SP_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_borrower);

            LibGovNFTTierStorage.SingleSPTierData
                memory nftSpTier = IGovNFTTier(address(this)).getSingleSpTier(
                    nftTier.spTierId
                );
            maxLoanAmount = (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else if (_tierType == LibMarketStorage.TierType.VC_TIER) {
            LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
                .getUserVCNFTTier(_borrower);

            LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
                address(this)
            ).getSingleTierData(vcTier.traditionalTier);
            maxLoanAmount =
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        }
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralTokens staked collateral erc20 token addresses
    /// @return status returns the status of the loan creation for token market
    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256 status) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.

        if (_tierType == LibMarketStorage.TierType.GOV_TIER) {
            LibGovTierStorage.TierData memory tierData = this
                .getTierDatabyGovBalance(_wallet);
            //user has gov tier level
            status = LibUserTier.validateGovHoldingTierForToken(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralTokens,
                tierData
            );
        }
        //determine if user nft tier is available
        // need to determinne is user one
        //of the nft holder in NFTTierData mapping
        else if (_tierType == LibMarketStorage.TierType.NFT_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_wallet);

            status = LibUserTier.validateNFTTier(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralTokens,
                nftTier
            );
        } else if (_tierType == LibMarketStorage.TierType.NFT_SP_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_wallet);

            LibGovNFTTierStorage.SingleSPTierData
                memory nftSpTier = IGovNFTTier(address(this)).getSingleSpTier(
                    nftTier.spTierId
                );
            status = LibUserTier.validateNFTSpTier(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralTokens,
                nftTier,
                nftSpTier
            );
        } else if (_tierType == LibMarketStorage.TierType.VC_TIER) {
            LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
                .getUserVCNFTTier(_wallet);

            status = LibUserTier.validateVCTier(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralTokens,
                vcTier
            );
        }
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralNFTs staked collateral NFT token addresses
    /// @return status returns the status of the loan creation for nft market
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256 status) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.

        if (_tierType == LibMarketStorage.TierType.GOV_TIER) {
            LibGovTierStorage.TierData memory tierData = this
                .getTierDatabyGovBalance(_wallet);

            status = LibUserTier.validateGovHoldingTierForNFT(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralNFTs,
                tierData
            );
        } else if (_tierType == LibMarketStorage.TierType.NFT_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_wallet);

            status = LibUserTier.validateNFTTierForNFTs(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralNFTs,
                nftTier
            );
        } else if (_tierType == LibMarketStorage.TierType.NFT_SP_TIER) {
            LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
                address(this)
            ).getUserNftTier(_wallet);
            LibGovNFTTierStorage.SingleSPTierData
                memory nftSpTier = IGovNFTTier(address(this)).getSingleSpTier(
                    nftTier.spTierId
                );

            status = LibUserTier.validateNFTSpTierforNFTs(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralNFTs,
                nftTier,
                nftSpTier
            );
        } else if (_tierType == LibMarketStorage.TierType.VC_TIER) {
            LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
                .getUserVCNFTTier(_wallet);

            status = LibUserTier.validateVCTierForNFTs(
                _loanAmount,
                _collateralinStable,
                _stakedCollateralNFTs,
                vcTier
            );
        }
    }
}
