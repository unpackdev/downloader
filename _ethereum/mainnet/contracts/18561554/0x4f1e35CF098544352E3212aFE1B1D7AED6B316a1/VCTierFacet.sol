// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";
import "./LibAppStorage.sol";
import "./LibVCTierStorage.sol";
import "./LibGovTier.sol";
import "./IGovTier.sol";

contract VCTierFacet is Modifiers {
    /// @dev add the VC NFT Tier with only allowed token Ids
    function addVCNFTTier(
        address _vcnftContract,
        LibVCTierStorage.VCNFTTier memory _vcTierDetails
    ) external onlySuperAdmin(msg.sender) {
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        require(_vcnftContract != address(0), "zero address");
        require(
            _vcTierDetails.spAllowedTokens.length <= LibAppStorage.arrayMaxSize,
            "GCL: token array size exceed"
        );
        require(
            _vcTierDetails.spAllowedNFTs.length <= LibAppStorage.arrayMaxSize,
            "GCL: nft array size exceed"
        );

        require(
            _vcTierDetails.spAllowedTokens.length > 0,
            "sp token not exists"
        );
        require(_vcTierDetails.spAllowedNFTs.length > 0, "allowed nfts null");
        require(!es.isAlreadyVcTier[_vcnftContract], "already added vc tier");
        require(
            LibGovTier.isAlreadyTierLevel(_vcTierDetails.traditionalTier),
            "GTL:Traditional Tier Null"
        );

        isTokenExist(_vcTierDetails.spAllowedTokens, _vcnftContract);
        isNFTExist(_vcTierDetails.spAllowedNFTs, _vcnftContract);

        es.vcNftTiers[_vcnftContract] = _vcTierDetails;
        es.isAlreadyVcTier[_vcnftContract] = true;
        es.vcTiersKeys.push(_vcnftContract);
        emit LibVCTierStorage.VCNFTTierAdded(
            _vcnftContract,
            _vcTierDetails.traditionalTier,
            _vcTierDetails.spAllowedTokens,
            _vcTierDetails.spAllowedNFTs
        );
    }

    /// @dev this method adds more sp tokens for the vc nft tier
    /// @param _spTokens erc20 token addresses of strategic partners

    function addVCSpTokens(
        address _vcnftContract,
        address[] memory _spTokens
    ) external onlySuperAdmin(msg.sender) {
        require(_vcnftContract != address(0), "zero address");
        require(_spTokens.length > 0, "sp token not exists");
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        LibVCTierStorage.VCNFTTier storage vcTier = es.vcNftTiers[
            _vcnftContract
        ];
        require(vcTier.traditionalTier != 0, "invalid vc tier");
        uint256 length = _spTokens.length;
        require(
            es.vcNftTiers[_vcnftContract].spAllowedTokens.length + length <=
                LibAppStorage.arrayMaxSize,
            "GCL: token array size exceed"
        );

        isTokenExist(_spTokens, _vcnftContract);

        for (uint256 i = 0; i < length; i++) {
            vcTier.spAllowedTokens.push(_spTokens[i]);
        }
        emit LibVCTierStorage.AddVCSpTokens(_vcnftContract, _spTokens);
    }

    /// @dev this method adds the nft tokens for the vc nft tier
    /// @param _nftAddresses nft token addresses of strategic partners
    function addVCNftTokens(
        address _vcnftContract,
        address[] memory _nftAddresses
    ) external onlySuperAdmin(msg.sender) {
        require(_vcnftContract != address(0), "zero address");
        require(_nftAddresses.length > 0, "sp nfts not exists");
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        LibVCTierStorage.VCNFTTier storage vcTier = es.vcNftTiers[
            _vcnftContract
        ];
        require(vcTier.traditionalTier != 0, "invalid vc tier");

        isNFTExist(_nftAddresses, _vcnftContract);
        uint256 length = _nftAddresses.length;
        require(
            es.vcNftTiers[_vcnftContract].spAllowedNFTs.length + length <=
                LibAppStorage.arrayMaxSize,
            "GCL: nft array size exceed"
        );

        for (uint256 i = 0; i < length; i++) {
            vcTier.spAllowedNFTs.push(_nftAddresses[i]);
        }
        emit LibVCTierStorage.AddVCNftTokens(_vcnftContract, _nftAddresses);
    }

    /// @dev get VC Tier Data
    function getVCTier(
        address _vcTierNFT
    ) external view returns (LibVCTierStorage.VCNFTTier memory) {
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        return es.vcNftTiers[_vcTierNFT];
    }

    function getUserVCNFTTier(
        address _wallet
    ) external view returns (LibVCTierStorage.VCNFTTier memory) {
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        uint256 vcTierlength = es.vcTiersKeys.length;
        if (vcTierlength == 0) {
            return es.vcNftTiers[address(0x0)];
        }

        uint256 maxLTVFromNFTTier;
        address maxVCTierAddress;

        for (uint256 i = 0; i < vcTierlength; i++) {
            //user owns nft balannce
            uint256 tierLoantoValue;

            if (IERC721(es.vcTiersKeys[i]).balanceOf(_wallet) > 0) {
                tierLoantoValue = IGovTier(address(this))
                    .getSingleTierData(
                        es.vcNftTiers[es.vcTiersKeys[i]].traditionalTier
                    )
                    .loantoValue;

                if (tierLoantoValue >= maxLTVFromNFTTier) {
                    maxVCTierAddress = es.vcTiersKeys[i];
                    maxLTVFromNFTTier = tierLoantoValue;
                }
            } else {
                continue;
            }
        }
        return es.vcNftTiers[maxVCTierAddress];
    }

    function isTokenExist(
        address[] memory _tokens,
        address _vcTierNFT
    ) internal {
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();

        for (uint256 i; i < _tokens.length; i++) {
            require(
                !es.isTokenExist[_vcTierNFT][_tokens[i]],
                "token already added"
            );
            es.isTokenExist[_vcTierNFT][_tokens[i]] = true;
        }
    }

    function isNFTExist(address[] memory _nfts, address _vcTierNFT) internal {
        LibVCTierStorage.VCTierStorage storage es = LibVCTierStorage
            .vcTierStorage();
        for (uint256 i; i < _nfts.length; i++) {
            require(!es.isNFTExist[_vcTierNFT][_nfts[i]], "nft already added");
            es.isNFTExist[_vcTierNFT][_nfts[i]] = true;
        }
    }
}
