// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./AspenERC721DropStorage.sol";
import "./BaseAspenERC721DropV4.sol";
import "./AspenERC721DropLogic.sol";
import "./IDropClaimCondition.sol";

contract AspenERC721DropDelegateLogic is IDropClaimConditionV1, AspenERC721DropStorage, IDelegateBaseAspenERC721DropV4 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return AspenERC721DropStorage.supportsInterface(interfaceId);
    }

    /// ======================================
    /// ========= Delegated Logic ============
    /// ======================================
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address platformFeeRecipient, uint16 platformFeeBps) {
        (address _platformFeeReceiver, uint256 _claimFeeBPS) = aspenConfig.getClaimFee(_owner);
        platformFeeRecipient = _platformFeeReceiver;
        platformFeeBps = uint16(_claimFeeBPS);
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _conditionId) external view returns (ClaimCondition memory condition) {
        condition = AspenERC721DropLogic.getClaimConditionById(claimData, _conditionId);
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions() external view returns (ClaimCondition[] memory conditions) {
        conditions = AspenERC721DropLogic.getClaimConditions(claimData);
    }

    /// @dev Returns basic info for claim data
    function getClaimData()
        external
        view
        returns (uint256 nextTokenIdToMint, uint256 maxTotalSupply, uint256 maxWalletClaimCount)
    {
        (nextTokenIdToMint, maxTotalSupply, maxWalletClaimCount) = AspenERC721DropLogic.getClaimData(claimData);
    }

    /// @dev Returns the total payment amount the collector has to pay taking into consideration all the fees
    function getClaimPaymentDetails(
        uint256 _quantity,
        uint256 _pricePerToken,
        address _claimCurrency
    )
        external
        view
        returns (
            address claimCurrency,
            uint256 claimPrice,
            uint256 claimFee,
            address collectorFeeCurrency,
            uint256 collectorFee
        )
    {
        AspenERC721DropLogic.ClaimFeeDetails memory claimFees = AspenERC721DropLogic.getAllClaimFees(
            aspenConfig,
            _owner,
            _claimCurrency,
            _quantity,
            _pricePerToken
        );

        return (
            claimFees.claimCurrency,
            claimFees.claimPrice,
            claimFees.claimFee,
            claimFees.collectorFeeCurrency,
            claimFees.collectorFee
        );
    }

    /// @dev returns the pause status of the drop contract.
    function getClaimPauseStatus() external view override returns (bool pauseStatus) {
        pauseStatus = claimIsPaused;
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(
        uint256 _tokenId
    ) public view override isValidTokenId(_tokenId) returns (address, uint16) {
        return AspenERC721DropLogic.getRoyaltyInfoForToken(claimData, _tokenId);
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view override returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 _tokenId) public view isValidTokenId(_tokenId) returns (bool) {
        return _exists(_tokenId);
    }

    /// @dev Returns the offset for token IDs.
    function getSmallestTokenId() external pure override returns (uint8) {
        return TOKEN_INDEX_OFFSET;
    }

    function getTransferTimeForToken(uint256 _tokenId) external view override returns (uint256) {
        return transferableAt[_tokenId];
    }

    function getChargebackProtectionPeriod() external view override returns (uint256) {
        return chargebackProtectionPeriod;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(
        address _claimer
    )
        external
        view
        override
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = AspenERC721DropLogic.getActiveClaimConditions(
            claimData
        );
        (
            conditionId,
            walletClaimedCount,
            walletClaimedCountInPhase,
            lastClaimTimestamp,
            nextValidClaimTimestamp
        ) = AspenERC721DropLogic.getUserClaimConditions(claimData, _claimer);
        isClaimPaused = claimIsPaused;
        tokenSupply = totalSupply();
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria
    ///     including verification proofs.
    function verifyClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view override {
        AspenERC721DropLogic.fullyVerifyClaim(
            claimData,
            _receiver,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails()
        external
        view
        override
        returns (string memory termsURI, uint8 termsVersion, bool termsActivated)
    {
        return termsData.getTermsDetails();
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address);
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address, _termsVersion);
    }
}
