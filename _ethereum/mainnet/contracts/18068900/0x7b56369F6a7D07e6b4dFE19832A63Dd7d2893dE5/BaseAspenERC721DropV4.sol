// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseAspenERC721DropV4.sol'

pragma solidity ^0.8.4;

import "./IAspenERC721Drop.sol";
import "./IAspenFeatures.sol";
import "./IAspenVersioned.sol";
import "./IMulticallable.sol";
import "./IERC721.sol";
import "./IERC2981.sol";
import "./IERC4906.sol";
import "./INFTSupply.sol";
import "./INFTLimitSupply.sol";
import "./ICedarNFTIssuance.sol";
import "./IRoyalty.sol";
import "./IUpdateBaseURI.sol";
import "./IContractMetadata.sol";
import "./IOwnable.sol";
import "./IPausable.sol";
import "./IAgreement.sol";
import "./IPrimarySale.sol";
import "./IPlatformFee.sol";
import "./ILazyMint.sol";
import "./INFTClaimCount.sol";

/// Delegate features
interface IDelegateBaseAspenERC721DropV4 is IDelegatedNFTSupplyV1, IDelegatedNFTIssuanceV1, IDelegatedRoyaltyV0, IDelegatedUpdateBaseURIV1, IDelegatedPausableV0, IDelegatedAgreementV1, IDelegatedPlatformFeeV0 {}

/// Restricted features
interface IRestrictedBaseAspenERC721DropV4 is IRestrictedERC4906V0, IRestrictedNFTLimitSupplyV1, IRestrictedNFTIssuanceV6, IRestrictedRoyaltyV1, IRestrictedUpdateBaseURIV1, IRestrictedMetadataV2, IRestrictedPausableV1, IRestrictedAgreementV3, IRestrictedPrimarySaleV2, IRestrictedOperatorFiltererV0, IRestrictedOperatorFilterToggleV0, IRestrictedLazyMintV1, IRestrictedNFTClaimCountV0 {}

/// Inherit from this base to implement introspection
abstract contract BaseAspenERC721DropV4 is IAspenFeaturesV1, IAspenVersionedV2, IMulticallableV0, IERC721V5, IERC721MetadataV0, IERC721BurnableV0, IERC2981V0, IPublicNFTSupplyV0, IPublicNFTIssuanceV5, IPublicRoyaltyV1, IPublicMetadataV0, IPublicOwnableV1, IPublicAgreementV2, IPublicPrimarySaleV1, IPublicOperatorFilterToggleV1 {
    function supportedFeatureCodes() override public pure returns (uint256[] memory features) {
        features = new uint256[](35);
        /// IAspenFeatures.sol:IAspenFeaturesV1
        features[0] = 0x6efbb19b;
        /// IAspenVersioned.sol:IAspenVersionedV2
        features[1] = 0xe4144b09;
        /// IMulticallable.sol:IMulticallableV0
        features[2] = 0xad792170;
        /// standard/IERC721.sol:IERC721V5
        features[3] = 0x6e7e06fe;
        /// standard/IERC721.sol:IERC721MetadataV0
        features[4] = 0x3a7b499a;
        /// standard/IERC721.sol:IERC721BurnableV0
        features[5] = 0x54e82008;
        /// standard/IERC2981.sol:IERC2981V0
        features[6] = 0x4313e0e3;
        /// standard/IERC4906.sol:IRestrictedERC4906V0
        features[7] = 0xd8519fe1;
        /// issuance/INFTSupply.sol:IPublicNFTSupplyV0
        features[8] = 0x92ad6684;
        /// issuance/INFTSupply.sol:IDelegatedNFTSupplyV1
        features[9] = 0xad089694;
        /// issuance/INFTLimitSupply.sol:IRestrictedNFTLimitSupplyV1
        features[10] = 0xe31b6d69;
        /// issuance/ICedarNFTIssuance.sol:IPublicNFTIssuanceV5
        features[11] = 0x012ec382;
        /// issuance/ICedarNFTIssuance.sol:IDelegatedNFTIssuanceV1
        features[12] = 0x7f7f3224;
        /// issuance/ICedarNFTIssuance.sol:IRestrictedNFTIssuanceV6
        features[13] = 0xbc74f6c0;
        /// royalties/IRoyalty.sol:IPublicRoyaltyV1
        features[14] = 0x3dcd5bc8;
        /// royalties/IRoyalty.sol:IDelegatedRoyaltyV0
        features[15] = 0xb43da18a;
        /// royalties/IRoyalty.sol:IRestrictedRoyaltyV1
        features[16] = 0x29e81c60;
        /// baseURI/IUpdateBaseURI.sol:IDelegatedUpdateBaseURIV1
        features[17] = 0x0ed70707;
        /// baseURI/IUpdateBaseURI.sol:IRestrictedUpdateBaseURIV1
        features[18] = 0xe7f77644;
        /// metadata/IContractMetadata.sol:IPublicMetadataV0
        features[19] = 0xe0412fa9;
        /// metadata/IContractMetadata.sol:IRestrictedMetadataV2
        features[20] = 0x7c749d62;
        /// ownable/IOwnable.sol:IPublicOwnableV1
        features[21] = 0x48fcaf28;
        /// pausable/IPausable.sol:IDelegatedPausableV0
        features[22] = 0x8b81344f;
        /// pausable/IPausable.sol:IRestrictedPausableV1
        features[23] = 0x9a19ec63;
        /// agreement/IAgreement.sol:IPublicAgreementV2
        features[24] = 0x6051f2a9;
        /// agreement/IAgreement.sol:IDelegatedAgreementV1
        features[25] = 0x3ae96461;
        /// agreement/IAgreement.sol:IRestrictedAgreementV3
        features[26] = 0x2f96dff3;
        /// primarysale/IPrimarySale.sol:IPublicPrimarySaleV1
        features[27] = 0x47a9ced4;
        /// primarysale/IPrimarySale.sol:IRestrictedPrimarySaleV2
        features[28] = 0x63ff2dbf;
        /// royalties/IRoyalty.sol:IRestrictedOperatorFiltererV0
        features[29] = 0x8622d2ee;
        /// royalties/IRoyalty.sol:IPublicOperatorFilterToggleV1
        features[30] = 0x90fc4399;
        /// royalties/IRoyalty.sol:IRestrictedOperatorFilterToggleV0
        features[31] = 0x22a8937c;
        /// royalties/IPlatformFee.sol:IDelegatedPlatformFeeV0
        features[32] = 0x6195f7de;
        /// lazymint/ILazyMint.sol:IRestrictedLazyMintV1
        features[33] = 0x7f0a633a;
        /// issuance/INFTClaimCount.sol:IRestrictedNFTClaimCountV0
        features[34] = 0x9a6157ef;
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 4;
    }

    function implementationInterfaceId() virtual override public pure returns (string memory interfaceId) {
        interfaceId = "impl/IAspenERC721Drop.sol:IAspenERC721DropV4";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        /// ERC165 'handshake'
        if ((interfaceID == 0x0) || (interfaceID == 0xffffffff)) return false;
        /// ERC165 itself
        if (interfaceID == 0x01ffc9a7) return true;
        /// impl/IAspenERC721Drop.sol:IAspenERC721DropV4
        if (interfaceID == 0xa568eb69) return true;
        /// IAspenFeatures.sol:IAspenFeaturesV1
        if (interfaceID == 0x43c60851) return true;
        /// IAspenVersioned.sol:IAspenVersionedV2
        if (interfaceID == 0x0b2a676f) return true;
        /// IMulticallable.sol:IMulticallableV0
        if (interfaceID == 0xac9650d8) return true;
        /// standard/IERC721.sol:IERC721V5
        if (interfaceID == 0x80ac58cd) return true;
        /// standard/IERC721.sol:IERC721MetadataV0
        if (interfaceID == 0x5b5e139f) return true;
        /// standard/IERC721.sol:IERC721BurnableV0
        if (interfaceID == 0x42966c68) return true;
        /// standard/IERC2981.sol:IERC2981V0
        if (interfaceID == 0x2a55205a) return true;
        /// issuance/INFTSupply.sol:IPublicNFTSupplyV0
        if (interfaceID == 0x18160ddd) return true;
        /// issuance/INFTSupply.sol:IDelegatedNFTSupplyV1
        if (interfaceID == 0x371e420a) return true;
        /// issuance/INFTLimitSupply.sol:IRestrictedNFTLimitSupplyV1
        if (interfaceID == 0x3f3e4c11) return true;
        /// issuance/ICedarNFTIssuance.sol:IPublicNFTIssuanceV5
        if (interfaceID == 0x7a5a8e7e) return true;
        /// issuance/ICedarNFTIssuance.sol:IDelegatedNFTIssuanceV1
        if (interfaceID == 0xaedc31ea) return true;
        /// issuance/ICedarNFTIssuance.sol:IRestrictedNFTIssuanceV6
        if (interfaceID == 0xe1ccb8b1) return true;
        /// royalties/IRoyalty.sol:IPublicRoyaltyV1
        if (interfaceID == 0x981a0d63) return true;
        /// royalties/IRoyalty.sol:IDelegatedRoyaltyV0
        if (interfaceID == 0x4cc157df) return true;
        /// royalties/IRoyalty.sol:IRestrictedRoyaltyV1
        if (interfaceID == 0xfbc2afff) return true;
        /// baseURI/IUpdateBaseURI.sol:IDelegatedUpdateBaseURIV1
        if (interfaceID == 0x7aafcb38) return true;
        /// baseURI/IUpdateBaseURI.sol:IRestrictedUpdateBaseURIV1
        if (interfaceID == 0x817234fa) return true;
        /// metadata/IContractMetadata.sol:IPublicMetadataV0
        if (interfaceID == 0xe8a3d485) return true;
        /// metadata/IContractMetadata.sol:IRestrictedMetadataV2
        if (interfaceID == 0x09feb698) return true;
        /// ownable/IOwnable.sol:IPublicOwnableV1
        if (interfaceID == 0x9e0a8b6e) return true;
        /// pausable/IPausable.sol:IDelegatedPausableV0
        if (interfaceID == 0x3ea4694c) return true;
        /// pausable/IPausable.sol:IRestrictedPausableV1
        if (interfaceID == 0x2745d444) return true;
        /// agreement/IAgreement.sol:IPublicAgreementV2
        if (interfaceID == 0x815af908) return true;
        /// agreement/IAgreement.sol:IDelegatedAgreementV1
        if (interfaceID == 0x6ccea0e2) return true;
        /// agreement/IAgreement.sol:IRestrictedAgreementV3
        if (interfaceID == 0xc0d72452) return true;
        /// primarysale/IPrimarySale.sol:IPublicPrimarySaleV1
        if (interfaceID == 0x079fe40e) return true;
        /// primarysale/IPrimarySale.sol:IRestrictedPrimarySaleV2
        if (interfaceID == 0x6f4f2837) return true;
        /// royalties/IRoyalty.sol:IRestrictedOperatorFiltererV0
        if (interfaceID == 0xce8b3706) return true;
        /// royalties/IRoyalty.sol:IPublicOperatorFilterToggleV1
        if (interfaceID == 0x0a0a9c04) return true;
        /// royalties/IRoyalty.sol:IRestrictedOperatorFilterToggleV0
        if (interfaceID == 0x32f0cd64) return true;
        /// royalties/IPlatformFee.sol:IDelegatedPlatformFeeV0
        if (interfaceID == 0xd45573f6) return true;
        /// lazymint/ILazyMint.sol:IRestrictedLazyMintV1
        if (interfaceID == 0x47158264) return true;
        /// issuance/INFTClaimCount.sol:IRestrictedNFTClaimCountV0
        if (interfaceID == 0x6e25467e) return true;
        /// issuance/INFTSupply.sol:IDelegatedNFTSupplyV0
        if (interfaceID == 0x784bcc73) return true;
        /// issuance/INFTLimitSupply.sol:IRestrictedNFTLimitSupplyV0
        if (interfaceID == 0x3f3e4c11) return true;
        /// issuance/ICedarNFTIssuance.sol:IPublicNFTIssuanceV4
        if (interfaceID == 0x7a5a8e7e) return true;
        /// issuance/ICedarNFTIssuance.sol:IDelegatedNFTIssuanceV0
        if (interfaceID == 0xf3e76e50) return true;
        /// issuance/ICedarNFTIssuance.sol:IRestrictedNFTIssuanceV5
        if (interfaceID == 0x82bd3805) return true;
        /// royalties/IRoyalty.sol:IRestrictedRoyaltyV0
        if (interfaceID == 0xfbc2afff) return true;
        /// baseURI/IUpdateBaseURI.sol:IDelegatedUpdateBaseURIV0
        if (interfaceID == 0x191b9515) return true;
        /// baseURI/IUpdateBaseURI.sol:IRestrictedUpdateBaseURIV0
        if (interfaceID == 0x817234fa) return true;
        /// metadata/IContractMetadata.sol:IRestrictedMetadataV1
        if (interfaceID == 0x938e3d7b) return true;
        /// metadata/IContractMetadata.sol:IRestrictedMetadataV0
        if (interfaceID == 0x938e3d7b) return true;
        /// pausable/IPausable.sol:IRestrictedPausableV0
        if (interfaceID == 0x2745d444) return true;
        /// primarysale/IPrimarySale.sol:IRestrictedPrimarySaleV1
        if (interfaceID == 0x6f4f2837) return true;
        /// lazymint/ILazyMint.sol:IRestrictedLazyMintV0
        if (interfaceID == 0x47158264) return true;
        /// Otherwise not supported
        return false;
    }

    function isIAspenFeaturesV1() override public pure returns (bool) {
        return true;
    }
}
