// SPDX-License-Identifier: MIT

/*
 ________         _  __             ___  _      _ __       ___ 
/_  __/ /  ___   / |/ /__ _    __  / _ \(_)__ _(_) /____ _/ (_)
 / / / _ \/ -_) /    / -_) |/|/ / / // / / _ `/ / __/ _ `/ /   
/_/ /_//_/\__/ /_/|_/\__/|__,__/ /____/_/\_, /_/\__/\_,_/_(_)  
   ___                  _        _______/___/                  
  / _ )___  _______    (_)__    / ___/ /  (_)______ ____ ____  
 / _  / _ \/ __/ _ \  / / _ \  / /__/ _ \/ / __/ _ `/ _ `/ _ \ 
/____/\___/_/ /_//_/ /_/_//_/  \___/_//_/_/\__/\_,_/\_, /\___/ 
                                                   /___/       

// imnotArt Exhibition 1

As an emerging hub for digital art and NFTs, “The New Digital: Born in Chicago” showcases 
the many ways Chicago inspires creativity — from the city’s architecture, to the culture 
of the Midwest, and its vibrant neighborhoods.

This genesis exhibition from imnotArt Chicago features seven artists who were born or 
raised in Chicago, each with work reflecting a unique aspect of this great city.  
Together, starting with this exhibition, we are building something special right here in 
the 312. Welcome to The New Digital.

// Featured Artists
Chuck Anderson
Sophie Sturdevant
Joey the Photographer
Willea Zwey
ProbCause
Sean Williams
Sinclair

// Smart Contract
imnotFuzzyHat <Ian Olson>

*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./RoyaltiesV2.sol";

contract imnotArtExhibition1 is Ownable, ERC721Enumerable, RoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    uint16 constant public artistFirstSaleBps = 6500; // 65% of First Sale
    uint16 constant public artistSecondarySaleBps = 500; // 5% of Secondary Sale
    uint16 constant public imnotArtSecondarySaleBps = 250; // 2.5% of Secondary Sale

    // ---
    // Properties
    // ---
    uint256 public nextTokenId = 1;
    address public imnotArtPayoutAddress;
    string private _contractUri;
    bool public useRoyaltyContracts;

    // ---
    // Structs
    // ---

    /* Only need Artist BPS, as remainder would be given to imnotArt after Artist is paid */
    struct TokenBps {
        uint16 artistFirstSaleBps;
        uint16 artistSecondarySaleBps;
    }

    // ---
    // Events
    // ---
    event PermanentURI(string _value, uint256 indexed _id); // OpenSea Freezing Metadata

    // ---
    // Security
    // ---
    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isArtist;

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "Only admins.");
        _;
    }

    modifier onlyArtist() {
        require(_isArtist[msg.sender], "Only approved artists.");
        _;
    }

    modifier onlyValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token ID does not exist.");
        _;
    }

    // ---
    // Mappings
    // ---
    mapping(uint256 => string) private _metadataByTokenId;
    mapping(uint256 => address) public artistByTokenId;
    mapping(uint256 => TokenBps) public tokenBpsByTokenId;
    mapping(address => address) public royaltyContractByArtistAddress;

    // ---
    // Constructor
    // ---
    constructor() ERC721("The New Digital: Born in Chicago", "IMNOTARTEXHIBITION1") {
        _isAdmin[msg.sender] = true;
        useRoyaltyContracts = false;

        // imnotArt Mainnet Gnosis Safe
        _isAdmin[address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3)] = true;
        imnotArtPayoutAddress = address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3);
        _contractUri = "ipfs://QmWybmS4kK9cNdWBqGzysgikzpss9KRfcUgpuMAL9SQXaH";

        // Artists
        _isArtist[address(0x7fd29e547dC2d2Ec3773457295a98893A0Db2e05)] = true; // Chuck Anderson
        _isArtist[address(0x86d0b90816F8f8290129dD9E62C7A75117547A98)] = true; // Sophie Sturdevant
        _isArtist[address(0x28C0719a45F9E7a35c4dCD845D1A269d0079D781)] = true; // Joey the Photographer
        _isArtist[address(0xB802162900a4e2d1b2472B14895D56A73aE647E8)] = true; // Willea Zwey
        _isArtist[address(0x7049871039097E61b1Ae827e77aBb1C9a0B14061)] = true; // ProbCause
        _isArtist[address(0x0C88aF8b65C68D1d3cb9eC719E9Ce2A76642E135)] = true; // Sean Williams
        _isArtist[address(0x4F9B8A31c0986fA44cD386b1610F54a56eC8dc70)] = true; // Sinclair
    }

    // ---
    // Supported Interfaces
    // ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---
    function mintToken(address artistAddress, string memory metadataUri) public onlyAdmin returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        _mint(artistAddress, tokenId);
        artistByTokenId[tokenId] = artistAddress;

        _metadataByTokenId[tokenId] = metadataUri;
        emit PermanentURI(metadataUri, tokenId);

        TokenBps memory tokenBps = TokenBps({
            artistFirstSaleBps: artistFirstSaleBps,
            artistSecondarySaleBps: artistSecondarySaleBps
        });
        tokenBpsByTokenId[tokenId] = tokenBps;
    }

    function artistMintToken(string memory metadataUri) public onlyArtist returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        _mint(msg.sender, tokenId);
        artistByTokenId[tokenId] = msg.sender;

        _metadataByTokenId[tokenId] = metadataUri;
        emit PermanentURI(metadataUri, tokenId);

        TokenBps memory tokenBps = TokenBps({
            artistFirstSaleBps: artistFirstSaleBps,
            artistSecondarySaleBps: artistSecondarySaleBps
        });
        tokenBpsByTokenId[tokenId] = tokenBps;
    }

    // ---
    // Burning
    // ---
    function burn(uint256 tokenId) public virtual onlyArtist {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only approved artist owners.");
        _burn(tokenId);
    }

    // ---
    // Contract Updates
    // ---
    function updateImnotArtPayoutAddress(address newPayoutAddress) public onlyAdmin {
        imnotArtPayoutAddress = newPayoutAddress;
    }

    function updateContractUri(string memory newContractUri) public onlyAdmin {
        _contractUri = newContractUri;
    }

    function updateTokenMetadata(uint256 tokenId, string memory metadataUri, bool permanent) public onlyOwner onlyValidTokenId(tokenId) {
        _metadataByTokenId[tokenId] = metadataUri;

        if (permanent) {
            emit PermanentURI(metadataUri, tokenId);
        }
    }

    function addAdmin(address newAdminAddress) public onlyAdmin {
        _isAdmin[newAdminAddress] = true;
    }

    function removeAdmin(address removeAdminAddress) public onlyAdmin {
        _isAdmin[removeAdminAddress] = true;
    }

    function addApprovedArtist(address newArtistAddress) public onlyAdmin {
        _isArtist[newArtistAddress] = true;
    }

    function removeApprovedArtist(address removeArtistAddress) public onlyAdmin {
        _isArtist[removeArtistAddress] = false;
    }

    function toggleUseRoyaltyContracts() public onlyAdmin {
        useRoyaltyContracts = !useRoyaltyContracts;
    }

    function addRoyaltyContractAddress(address artistAddress, address royaltyContractAddress) public onlyAdmin {
        royaltyContractByArtistAddress[artistAddress] = royaltyContractAddress;
    }

    // ---
    // Metadata
    // ---
    function tokenURI(uint256 tokenId) public view override virtual onlyValidTokenId(tokenId) returns (string memory) {
        return _metadataByTokenId[tokenId];
    }

    // ---
    // Contract Retrieve Functions
    // ---
    function getTokensOfOwner(address _owner) public view returns (uint256[] memory tokenIds) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            tokenIds = new uint256[](0);
        } else {
            tokenIds = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                tokenIds[index] = tokenOfOwnerByIndex(_owner, index);
            }
        }

        return tokenIds;
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    /* OpenSea */
    function contractURI() public view virtual returns (string memory) {
        return _contractUri;
    }

    /* Rarible Royalties V2 */
    function getRaribleV2Royalties(uint256 tokenId) external view override onlyValidTokenId(tokenId) returns (LibPart.Part[] memory) {
        LibPart.Part[] memory royalties = new LibPart.Part[](2);
        
        royalties[0] = LibPart.Part({
            account: payable(artistByTokenId[tokenId]),
            value: uint96(artistSecondarySaleBps)
        });

        royalties[1] = LibPart.Part({
            account: payable(imnotArtPayoutAddress),
            value: uint96(imnotArtSecondarySaleBps)
        });

        return royalties;
    }

    /* EIP-2981 - https://eips.ethereum.org/EIPS/eip-2981 */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        address artistAddress = artistByTokenId[tokenId];
        uint256 combinedBpsForSinglePayout = uint256(artistSecondarySaleBps).add(uint256(imnotArtSecondarySaleBps));
        uint256 royaltyAmount = SafeMath.div(SafeMath.mul(salePrice, combinedBpsForSinglePayout), 10000);

        address payoutAddress = imnotArtPayoutAddress;
        
        if (useRoyaltyContracts) {
            payoutAddress = royaltyContractByArtistAddress[artistAddress];
        }

        if (payoutAddress == address(0)) {
            payoutAddress = imnotArtPayoutAddress;
        }

        return (payoutAddress, royaltyAmount);
    }

    /*
    
    imnotArt POV on Gallery Exhibition Contracts
    
    The idea to build a smart contract specific for 'The New Digital: Born in Chicago' was 
    rooted in a desire to establish provenance within the exhibition. Through the 
    'imnotArtExhibition1' contract we allow our participating artists to mint their work 
    themselves, thus creating a digital signature with both the artist and exhibition.
    
    As we were finalizing this contract we started to observe a new movement of artists 
    creating their own smart contracts.
    
    We believe this is the future.
    
    In our opinion, artists are best served through minting works from their own smart contracts.  
    As a gallery we believe this is the correct model and will do our part in encouraging and 
    onboarding artists to create their own smart contracts. 
    
    This will be imnotArt's first - and last - exhibition contract.  Our POV may continue to evolve 
    but will always align with the best interest of artists.

    - imnotMatt

    */
}