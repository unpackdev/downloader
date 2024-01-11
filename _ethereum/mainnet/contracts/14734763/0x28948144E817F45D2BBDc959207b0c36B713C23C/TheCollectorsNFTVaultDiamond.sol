// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/***
 *    ████████╗██╗  ██╗███████╗
 *    ╚══██╔══╝██║  ██║██╔════╝
 *       ██║   ███████║█████╗
 *       ██║   ██╔══██║██╔══╝
 *       ██║   ██║  ██║███████╗
 *       ╚═╝   ╚═╝  ╚═╝╚══════╝
 *     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
 *    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
 *    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
 *    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
 *    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
 *     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
 *    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
 *    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
 *    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
 *    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
 *    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
 *    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝
 */

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultLogicFacet.sol";
import "./TheCollectorsNFTVaultAssetsManagerFacet.sol";
import "./TheCollectorsNFTVaultOpenseaManagerFacet.sol";
import "./TheCollectorsNFTVaultTokenManagerFacet.sol";
import "./TheCollectorsNFTVaultDiamondCutAndLoupeFacet.sol";
import "./LibDiamond.sol";

/*
    @title
    The collectors NFT Vault is the first fully decentralized product that allows a group of people to handle
    together the lifecycle of an NFT and all while using any marketplace (including Opensea).
    The main concept and what really differentiate this product from others is the fact that you are not losing the 3
    primary reasons for purchasing an NFT. The first one is the bragging rights, you are getting an NFT that looks like
    the original NFT but with the ownership % on top of it. You can still brag that you own 55% of a MAYC.
    The second one, is the liquidity, meaning you can always sell your share of the original NFT over Opensea or
    any other marketplaces. 50% of a BAYC with a floor price of 80 ETH worth 40 ETH. And the third one is the buying it
    for the art. As you are the partial owner of the original NFT, you can decide what to do with it and vote
    to keep it just for the art.
    @dev
    This contract is using the very robust and innovative EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535) which
    allows a contract to be organized in the most efficient way
*/
contract TheCollectorsNFTVaultDiamond is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor(
        string memory __baseTokenURI,
        address _logicFacetAddress,
        address _assetsManagerFacetAddress,
        address _openseaManagerFacetAddress,
        address _vaultTokenManagerFacetAddress,
        address _diamondCutAndLoupeFacetAddress,
        address __nftVaultAssetHolderImpl,
        address[3] memory addresses
    ) ERC721("The Collectors NFT Vault", "TheCollectorsNFTVault") {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Moving tracker to 1 so we can use 0 to indicate that user doesn't have any tokens
        _as.tokenIdTracker.increment();
        // The base uri of the tokens
        _as.baseTokenURI = __baseTokenURI;
        // The implementation for asset holder. Is used to significantly reduce the creation cost of a new vault
        // Everytime a new marketplace will be added, the implementation will change
        _as.nftVaultAssetHolderImpl = __nftVaultAssetHolderImpl;
        // Currently only supporting opensea but are planning to add more marketplaces in the near future
        // When it happens, the assets holder creator address will be changed
        _as.nftVaultAssetsHolderCreator = _openseaManagerFacetAddress;
        _as.liquidityWallet = addresses[0];
        _as.stakingWallet = addresses[1];
        _as.royaltiesRecipient = addresses[2];
        _as.royaltiesBasisPoints = 250; // 2.5%
        _as.nftVaultTokenTransferHandler = _vaultTokenManagerFacetAddress;

        // Adding all logic functions
        LibDiamond.addFunctions(_logicFacetAddress, _getLogicFacetSelectors());
        // Adding all assets manager functions
        LibDiamond.addFunctions(_assetsManagerFacetAddress, _getAssetsManagerFacetSelectors());
        // Adding all opensea manager functions
        // In the future more marketplaces will be added
        LibDiamond.addFunctions(_openseaManagerFacetAddress, _getOpenseaManagerFacetSelectors());
        // Adding all NFT vault token functions
        LibDiamond.addFunctions(_vaultTokenManagerFacetAddress, _getNFTVaultTokenManagerFacetSelectors());
        // Adding all diamond cut and loupe functions
        LibDiamond.addFunctions(_diamondCutAndLoupeFacetAddress, _getDiamondCutAndLoupeFacetSelectors());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IDiamondLoupe).interfaceId ||
        interfaceId == type(IDiamondCut).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // =========== ERC721 Overrides ===========

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_as.baseTokenURI, _as.vaultTokens[tokenId].toString(), "/", tokenId.toString(), ".json"));
    }

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        Check out the implementation to learn more
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        Address.functionDelegateCall(
            _as.nftVaultTokenTransferHandler,
            abi.encodeWithSelector(
                INFTTokenTransferHandler.transferNFTVaultToken.selector, from, to, tokenId
            )
        );
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        bytes memory data = Address.functionStaticCall(
            _as.nftVaultTokenTransferHandler,
            abi.encodeWithSelector(
                INFTTokenTransferHandler.isNFTApprovedForAll.selector, owner, operator
            )
        );

        (bool result) = abi.decode(data, (bool));

        return result;
    }

    // =========== Diamond ===========

    /*
        @dev
        Adding all functions of logic facet
    */
    function _getLogicFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](22);
        selectors[0] = TheCollectorsNFTVaultLogicFacet.setBaseTokenURI.selector;
        selectors[1] = TheCollectorsNFTVaultLogicFacet.setLiquidityWallet.selector;
        selectors[2] = TheCollectorsNFTVaultLogicFacet.setStakingWallet.selector;
        selectors[3] = TheCollectorsNFTVaultLogicFacet.createVault.selector;
        selectors[4] = TheCollectorsNFTVaultLogicFacet.joinPublicVault.selector;
        selectors[5] = TheCollectorsNFTVaultLogicFacet.addParticipant.selector;
        selectors[6] = TheCollectorsNFTVaultLogicFacet.setTokenInfoAndMaxBuyPrice.selector;
        selectors[7] = TheCollectorsNFTVaultLogicFacet.setListingPrice.selector;
        selectors[8] = TheCollectorsNFTVaultLogicFacet.vote.selector;
        selectors[9] = TheCollectorsNFTVaultLogicFacet.fundVault.selector;
        selectors[10] = TheCollectorsNFTVaultLogicFacet.withdrawFunds.selector;
        selectors[11] = TheCollectorsNFTVaultLogicFacet.assetsHolders.selector;
        selectors[12] = TheCollectorsNFTVaultLogicFacet.vaults.selector;
        selectors[13] = TheCollectorsNFTVaultLogicFacet.vaultTokens.selector;
        selectors[14] = TheCollectorsNFTVaultLogicFacet.vaultsExtensions.selector;
        selectors[15] = TheCollectorsNFTVaultLogicFacet.liquidityWallet.selector;
        selectors[16] = TheCollectorsNFTVaultLogicFacet.stakingWallet.selector;
        selectors[17] = TheCollectorsNFTVaultLogicFacet.getVaultParticipants.selector;
        selectors[18] = TheCollectorsNFTVaultLogicFacet.getParticipantPercentage.selector;
        selectors[19] = TheCollectorsNFTVaultLogicFacet.getTokenPercentage.selector;
        selectors[20] = TheCollectorsNFTVaultLogicFacet.salvageERC721Token.selector;
        selectors[21] = TheCollectorsNFTVaultLogicFacet.salvageETH.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of assets manager facet
    */
    function _getAssetsManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = TheCollectorsNFTVaultAssetsManagerFacet.migrate.selector;
        selectors[1] = TheCollectorsNFTVaultAssetsManagerFacet.listNFTForSale.selector;
        selectors[2] = TheCollectorsNFTVaultAssetsManagerFacet.cancelNFTForSale.selector;
        selectors[3] = TheCollectorsNFTVaultAssetsManagerFacet.buyNFTFromVault.selector;
        selectors[4] = TheCollectorsNFTVaultAssetsManagerFacet.sellNFTToVault.selector;
        selectors[5] = TheCollectorsNFTVaultAssetsManagerFacet.unstakeCollector.selector;
        selectors[6] = TheCollectorsNFTVaultAssetsManagerFacet.stakeCollector.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getOpenseaManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TheCollectorsNFTVaultOpenseaManagerFacet.buyNFTOnOpensea.selector;
        selectors[1] = TheCollectorsNFTVaultOpenseaManagerFacet.listNFTOnOpensea.selector;
        selectors[2] = TheCollectorsNFTVaultOpenseaManagerFacet.cancelListingOnOpensea.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getNFTVaultTokenManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = TheCollectorsNFTVaultTokenManagerFacet.claimVaultTokenAndGetLeftovers.selector;
        selectors[1] = TheCollectorsNFTVaultTokenManagerFacet.redeemToken.selector;
        selectors[2] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesRecipient.selector;
        selectors[3] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesRecipient.selector;
        selectors[4] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesBasisPoints.selector;
        selectors[5] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesBasisPoints.selector;
        selectors[6] = TheCollectorsNFTVaultTokenManagerFacet.royaltyInfo.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getDiamondCutAndLoupeFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddress.selector;
        return selectors;
    }

    // =========== Lifecycle ===========

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // To learn more about this implementation read EIP 2535
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}
