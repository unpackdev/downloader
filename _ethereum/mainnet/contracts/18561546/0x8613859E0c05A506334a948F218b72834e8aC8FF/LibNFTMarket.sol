// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibMarketStorage.sol";

import "./IERC721.sol";

library LibNFTMarket {
    event LoanOfferCreatedNFT(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsNFT loanDetailsNFT
    );

    event NFTLoanOfferActivated(
        uint256 nftLoanId,
        address _lender,
        uint256 _loanAmount,
        uint256 _termsLengthInDays,
        uint256 _APYOffer,
        address[] stakedCollateralNFTsAddress,
        uint256[] stakedCollateralNFTId,
        uint256[] stakedNFTPrice,
        address _borrowStableCoin
    );

    event NFTLoanOfferAdjusted(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsNFT loanDetailsNFT
    );

    event LoanOfferCancelNFT(
        uint256 nftloanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    event NFTLoanPaybacked(
        uint256 nftLoanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    event AutoLiquidatedNFT(
        uint256 nftLoanId,
        LibMarketStorage.LoanStatus loanStatus
    );

    /// @dev check approval of nfts from the borrower to the nft market
    /// @param nftAddresses ERC721 NFT contract addresses
    /// @param nftIds nft token ids
    /// @return bool returns the true or false for the nft approvals
    function checkApprovalNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds
    ) internal view returns (bool) {
        uint256 length = nftAddresses.length;

        for (uint256 i = 0; i < length; i++) {
            //borrower will approved the tokens staking as collateral
            require(
                IERC721(nftAddresses[i]).getApproved(nftIds[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
        }
        return true;
    }

    /// @dev function that receive an array of addresses to check approval of NFTs
    /// @param nftAddresses contract addresses of ERC721
    /// @param nftIds token ids of nft contracts
    /// @param borrower address of the borrower

    function checkApprovedandTransferNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds,
        address borrower
    ) internal returns (bool) {
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(
                borrower,
                address(this),
                nftIds[i]
            );
        }

        return true;
    }
}
