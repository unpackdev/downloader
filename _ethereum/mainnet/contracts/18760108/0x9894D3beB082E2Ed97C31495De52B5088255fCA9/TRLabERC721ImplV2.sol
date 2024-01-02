// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./SignerRoleUpgradeable.sol";
import "./WithTreasuryUpgradeableV2.sol";

    struct Artwork {
        uint256 minted;
        uint256 maxSupply;
        string baseURI;
    }

    error PermitExpired();
    error InvalidPermitSig();
    error ArtworkMaxSupplyError();
    error BuyerNotToError();
    error PurchaseSigError();
    error ArtworkSoldOut(uint256 id);
    error BadArtworkId(uint256 id);
    error BadMaxSupply();
    error BadNonce();

/// added transferByPermit
contract TRLabERC721ImplV2 is
Initializable,
ReentrancyGuardUpgradeable,
OwnableUpgradeable,
WithTreasuryUpgradeableV2,
SignerRoleUpgradeable,
ERC721RoyaltyUpgradeable,
UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;


    // keccak256("Permit(address to,uint256 tokenId,uint256 nonce,uint256 deadline)"),
    bytes32 public constant PERMIT_TYPEHASH = 0xe2e0049957f60df2858b6e2fb96f4e6e80f6327641e52b47b73f9e8f66503411;
    uint256 constant internal ONE_BILLION = 1_000_000_000;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    uint256 public totalSupply;
    string public contractURI; // for opensea collection
    string public defaultBaseURI;
    bytes32 public DOMAIN_SEPARATOR;
    uint256 public artworkNums;
    // tokenId => nonce, for transferByPermit
    mapping(uint256 => uint256) public transferNonces;
    // artworkId => artwork, artworkId is artworkNums + 1, starting from 1
    mapping(uint256 => Artwork) public artworks;
    // user => artworkId => nonce, for purchase
    mapping(address => mapping(uint256 => uint256)) public userNonces;
    // user => batchNonce
    mapping(address => uint256) public userBatchNonces;

    event TransferByPermit(address owner, address to, uint256 tokenId);
    event LogSetContractURI(string uri);
    event LogSetBaseURI(string uri);
    event LogCreateArtwork(uint256 indexed artworkId, uint256 maxSupply, string baseURI);
    event LogUpdateArtwork(uint256 indexed artworkId, uint256 maxSupply, string baseURI);
    event LogPurchaseArtwork(uint256 indexed artworkId, address indexed to, uint256 usdValue, uint256 ethValue);

/// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _treasury, address _signer, string memory name_, string memory symbol_, string memory _contractUri) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __WithTreasury_init(_treasury);
        __SignerRole_init(_signer);

        setNameAndSymbol(name_, symbol_);
        setContractURI(_contractUri);
        totalSupply = 0;
        artworkNums = 0;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("TRLAB ERC721")),
                keccak256(bytes("2")),
                block.chainid,
                address(this)
            )
        );
    }

    function getArtwork(uint256 artworkId) public view returns (Artwork memory) {
        return artworks[artworkId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev if artwork baseURI set, tokenId is {baseURI}/{editionId}, otherwise, {defaultBaseURI}/{tokenId}
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: uri query for non existent token");
        require(tokenId >= ONE_BILLION, "tokenId not correct");
        uint256 artworkId = tokenId / ONE_BILLION;
        Artwork memory artwork = artworks[artworkId];
        require(artwork.maxSupply > 0, "artwork not exists");
        uint256 editionId = tokenId % ONE_BILLION;
        return bytes(artwork.baseURI).length != 0 ? string(abi.encodePacked(artwork.baseURI, editionId.toString())) : string(abi.encodePacked(defaultBaseURI, tokenId.toString()));
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
        * @dev transfer nft token by permit, used for privy embedded wallet
     */
    function transferByPermit(address to, uint256 tokenId, uint256 deadline, bytes calldata sig) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }
        bytes32 digest = ECDSAUpgradeable.toTypedDataHash(
            DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, to, tokenId, transferNonces[tokenId]++, deadline))
        );

        address recoveredAddress = digest.recover(sig);
        address owner = ownerOf(tokenId);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert InvalidPermitSig();
        }
        // approve the caller, since the transferFrom function checks for approval from _msgSender()
        _approve(_msgSender(), tokenId);
        super.safeTransferFrom(owner, to, tokenId);
        emit TransferByPermit(owner, to, tokenId);
    }

    /**
     * @dev create new artwork, if it's open edition, set maxSupply to ONE_BILLION - 1
     */
    function createArtwork(uint256 artworkId, uint256 maxSupply, string calldata baseURI) external onlyOwner {
        if (maxSupply >= ONE_BILLION) {
            revert ArtworkMaxSupplyError();
        }
        if (artworks[artworkId].maxSupply != 0) {
            revert BadArtworkId(artworkId);
        }
        artworkNums++;
        artworks[artworkId] = Artwork({
            minted: 0,
            maxSupply: maxSupply,
            baseURI: baseURI
        });
        emit LogCreateArtwork(artworkId, maxSupply, baseURI);
    }

    /**
     * @dev create new artwork, largest maxSupply is ONE_BILLION - 1
     */
    function updateArtwork(uint256 artworkId, uint256 maxSupply, string calldata baseURI) external onlyOwner {
        Artwork storage artwork = artworks[artworkId];
        if (artwork.maxSupply == 0) {
            revert BadArtworkId(artworkId);
        }
        if (artwork.minted > maxSupply) {
            revert BadMaxSupply();
        }
        if (maxSupply >= ONE_BILLION) {
            revert ArtworkMaxSupplyError();
        }
        artwork.maxSupply = maxSupply;
        artwork.baseURI = baseURI;
        emit LogUpdateArtwork(artworkId, maxSupply, baseURI);
    }

    function batchPurchase(uint256[] calldata artworkIds, address to, uint256 usdValue, uint256 _batchNonce, bytes calldata sig) external payable {
        if (userBatchNonces[to] != _batchNonce) {
            revert BadNonce();
        }
        userBatchNonces[to] = _batchNonce + 1;
        // to prevent user from purchasing from metamask and stripe simultaneously
        bool verifySig = _msgSender() != owner() && !isSigner(_msgSender());
        if (verifySig) {
            if (_msgSender() != to) {
                revert BuyerNotToError();
            }
            bytes32 messageHash = keccak256(
                abi.encode(block.chainid, address(this), to, artworkIds, _batchNonce, msg.value)
            );
            if (!_verifySignedMessage(messageHash, sig)) {
                revert PurchaseSigError();
            }
        }
        if (msg.value > 0) {
            _sendETHToTreasury(msg.value);
        }
        for (uint256 i = 0; i < artworkIds.length; i++) {
            uint256 artworkId = artworkIds[i];
            _mintArtwork(artworkId, to, usdValue);
        }
        totalSupply += artworkIds.length;
    }

    /**
    * @dev function for both end user and admin to mint NFTs. If it's end user, verify sig before mint. Sig also includes price of that artwork.
    */
    function purchaseArtwork(uint256 artworkId, address to, uint256 usdValue, uint256 _nonce, bytes calldata sig) external payable {
        if (userNonces[to][artworkId] != _nonce) {
            revert BadNonce();
        }
        userNonces[to][artworkId] = _nonce + 1;
        bool verifySig = _msgSender() != owner() && !isSigner(_msgSender());
        if (verifySig) {
            if (_msgSender() != to) {
                revert BuyerNotToError();
            }
            bytes32 messageHash = keccak256(
                abi.encode(block.chainid, address(this), to, artworkId, _nonce, msg.value)
            );
            if (!_verifySignedMessage(messageHash, sig)) {
                revert PurchaseSigError();
            }
        }
        if (msg.value > 0) {
            _sendETHToTreasury(msg.value);
        }
        _mintArtwork(artworkId, to, usdValue);
        totalSupply++;
    }

    function _mintArtwork(uint256 artworkId, address to, uint256 usdValue) internal {
        Artwork memory artwork = artworks[artworkId];
        if (artworkId == 0 || artwork.maxSupply == 0) {
            revert BadArtworkId(artworkId);
        }
        if (artwork.minted == artwork.maxSupply) {
            revert ArtworkSoldOut(artworkId);
        }
        artworks[artworkId].minted = artwork.minted + 1;
        uint256 tokenId = artworkId * ONE_BILLION + artwork.minted + 1;
        _safeMint(to, tokenId);
        emit LogPurchaseArtwork(artworkId, to, usdValue, msg.value);
    }

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }
    /**
     * @dev See {IERC721ProjectCore-burn}.
     */
    function burn(uint256 tokenId) public nonReentrant {
        _burn(tokenId);
    }


    function setDefaultBaseURI(string calldata _uri) external onlyOwner {
        defaultBaseURI = _uri;
        emit LogSetBaseURI(_uri);
    }

    /**
     * @dev See {ERC721RoyaltyUpgradeable-setDefaultRoyalties}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev for opensea collection
     */
    function setContractURI(string memory _uri) public onlyOwner {
        contractURI = _uri;
        emit LogSetContractURI(_uri);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return defaultBaseURI;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
