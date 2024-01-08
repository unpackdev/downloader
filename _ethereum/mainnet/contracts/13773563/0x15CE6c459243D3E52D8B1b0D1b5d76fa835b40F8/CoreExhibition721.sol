// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./INA721Standard.sol";
import "./INA721ExhibitionStandard.sol";
import "./AdminFunctions.sol";
import "./NftStandardProperties.sol";
import "./MetadataByToken.sol";
import "./LibPart.sol";
import "./IRaribleRoyaltiesV2.sol";

contract CoreExhibition721 is Ownable, ERC721, INA721Standard, INA721ExhibitionStandard, NftStandardProperties, AdminFunctions, MetadataByToken, IRaribleRoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_RARIBLE_ROYALTIES = 0xcad96cca; // bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca

    // ---
    // Mappings
    // ---

    mapping(address => bool) isArtist;
    mapping(uint256 => address) artistByTokenId;

    // ---
    // Function Modifiers
    // ---

    modifier onlyArtist {
        require(isArtist[msg.sender], "Only Artists.");
        _;
    }

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor(NftOptions memory options) ERC721(options.name, options.symbol) {
        nextTokenId = options.startingTokenId;
        maxInvocations = options.maxInvocations;
        royaltyFeeBps = options.royaltyBps;
        contractURI = options.contractUri;

        // Add default admins.
        isAdmin[msg.sender] = true; // Deployer
        address gnosisSafe = address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3); // imnotArt Gnosis Safe
        isAdmin[gnosisSafe] = true;
        imnotArtPayoutAddress = gnosisSafe;

        // Approve Artists
        isArtist[address(0xa184C07201b6E3c18013fA6b3F9C76a7A61C4Fc7)] = true; // Angelica Ramirez
        isArtist[address(0x1ba3ef24bc64B22a80422678d4B6Ea85f0f92Bde)] = true; // Crystal Street
        isArtist[address(0x5BbfbC4E659e40Fd281b3863f138289CCbA74c52)] = true; // Judy Lindsay
        isArtist[address(0x3B9A65d8F55b2B3eEd8080b0B6f7F6cA23C1aA87)] = true; // May
        isArtist[address(0x348c68d9a5310f3E330AD0DAade3172900Dd28dc)] = true; // MK Raplinger
        isArtist[address(0x8b94e8E61f331d49FfCe99Eb0F6B2e20f35dbe54)] = true; // Pam Voth
        isArtist[address(0x892EFefaBc660502F2914eaB28cE9A445813EE90)] = true; // Taesirat Yusuf
        isArtist[address(0x0DeE12A2548432702e1c275c50b3aD223f9a74be)] = true; // Brittany Pierre
        isArtist[address(0xFeDeB3992cb5a8beB62D6503996825962A863e00)] = true; // Burnish
    }

    // ---
    // Functions
    // ---

    // @dev Return the support interfaces of this contract.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_RARIBLE_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // @dev Mint token for a given artist.
    function mint(address artistAddress, string memory metadataUri) external override returns (uint256 tokenId) {
        require(isAdmin[msg.sender], "Only Admins.");

        tokenId = mintInternal(artistAddress, metadataUri);
    }

    // @dev Mint token from an approved artist address.
    function artistMint(string memory metadataUri) external override returns (uint256 tokenId) {
        require(isArtist[msg.sender], "Only Artists.");

        tokenId = mintInternal(msg.sender, metadataUri);
    }

    // @dev Mint token and setup mappings.
    function mintInternal(address artistAddress, string memory metadataUri) internal returns (uint256 tokenId) {
        require((invocations.add(1) <= maxInvocations), "Max Invocations Hit");

        // Grab Next Token ID
        tokenId = nextTokenId;

        // Mint Token
        _mint(artistAddress, tokenId);

        // Add Mapping of Token ID to Artist Address
        artistByTokenId[tokenId] = artistAddress;

        // Add Mapping of Token ID to Metadata URL
        metadataByTokenId[tokenId] = metadataUri;

        // Emit Mint Event
        emit Mint(tokenId, metadataUri, artistAddress);

        // Increment the Next Token ID
        nextTokenId = nextTokenId.add(1);

        // Increment the Invocations
        invocations = invocations.add(1);
    }

    // @dev Add an address to the isAdmin mapping.
    function addArtist(address addressToAdd) external {
        require(isAdmin[msg.sender], "Only Admins.");

        isArtist[addressToAdd] = true;
    }

    // @dev Remove an address from the isAdmin mapping.
    function removeArtist(address addressToRemove) external {
        require(isAdmin[msg.sender], "Only Admins.");

        isArtist[addressToRemove] = false;
    }

    // @dev Override the tokenURI function to return the mapped value.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist.");

        return metadataByTokenId[tokenId];
    }

    // @dev Update the mapping of metadata by token id.
    function updateMetadataUri(uint256 tokenId, string memory metadataUri) external override {
        require(isAdmin[msg.sender], "Only Admins.");
        require(_exists(tokenId), "Token ID does not exist.");

        metadataByTokenId[tokenId] = metadataUri;
    }

    // @dev Burning of token in case of artist mistake.
    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "Token ID does not exist.");
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only approved artists who own the token allowed.");

        _burn(tokenId);
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    // @dev Rarible royalties V2 implementation.
    function getRaribleV2Royalties(uint256 id) external view override returns (LibPart.Part[] memory) {
        require(_exists(id), "Token ID does not exist.");

        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account : payable(artistByTokenId[id]),
            value : uint96(royaltyFeeBps)
        });

        return royalties;
    }

    // @dev EIP-2981 royalty standard implementation.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount) {
        require(_exists(tokenId), "Token ID does not exist.");

        uint256 royaltyPercentageAmount = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (artistByTokenId[tokenId], royaltyPercentageAmount);
    }
}