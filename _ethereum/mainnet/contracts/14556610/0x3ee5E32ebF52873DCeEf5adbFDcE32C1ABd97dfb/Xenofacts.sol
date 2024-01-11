//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./BitMaps.sol";
import "./ReentrancyGuard.sol";

import "./RoyaltiesV2.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

import "./Signature.sol";
import "./LockableArtToken.sol";

/**
 * @title Xenofacts Contract
 * @author dev@monoliths.art
 * @notice Minting and art encoding of Xenofacts ERC721 tokens.
 */
contract Xenofacts is ERC721, ReentrancyGuard, Ownable, LockableArtToken, RoyaltiesV2 {

    mapping(uint256 => string) private _tokenURIs;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _artTokenLocked;

    uint256 private _price = 0.05 ether;

    // How many tokens can a wallet hold
    uint256 public constant MAX_PUBLIC_MINT = 22;
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_ALLOWLIST_SUPPLY = 222;

    // Is public sale active
    bool public saleIsActive = false;

    // Is whitelist sale active   
    bool public isAllowListActive = false;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // multisig wallet managing financial aspects
    address private _multiSigWallet = 0xb4D3465EFd38Df0B3b48a0B9ae905cD0fce2300a;

    // royalties wallet (8% artists, 2% team)
    address private _royaltyWallet = 0x385DC5355244F787f96790D7f7De3AF7cC5cd37E;

    // Used to validate authorized whitelist mints and art locking
    address private _signerAddress = 0x1921A6C0Ad36280582D05969Ee87aC1F2ADb23B7;

    // Monoliths contract address
    address private _monoContract;

    modifier onlyMultiSig() {
        require(msg.sender == _multiSigWallet, 'Requires multiple signatures to complete');
        _;
    }

    modifier onlySigner() {
        require(msg.sender == _signerAddress, 'Requires signer');
        _;
    }

    modifier onlyMonoContract() {
        require(msg.sender == _monoContract, 'Not allowed');
        _;
    }

    /**
     *  Events
     */
    event ArtEncoded(address indexed owner, uint256 tokenId);
    event ArtLocked(address indexed owner, uint256 tokenId);

    //Constructor
    constructor() ERC721 ("Xenofacts", "XENO") {
    }

    function setMonoContract(address monoContract) public onlyOwner {
        _monoContract = monoContract;
    }

    /**
     *  Minting
     */

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(uint numberOfTokens) public payable nonReentrant {
        uint256 ts = _tokenIds.current();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + _tokenIds.current() < MAX_SUPPLY, "No more to mint.");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_PUBLIC_MINT, "No more tokens for you!");
        require(_price * numberOfTokens <= _price, "Not enough funds");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintToAddress(msg.sender);
        }
    }

    /*
    * @notice Free mints for artists on whitelist
    */
    function mintAllowList(uint256 numberOfTokens, uint256 maxNumberOfTokens, bytes calldata signature) public nonReentrant {
        uint256 ts = _tokenIds.current();
        require(isAllowListActive, "Allow list is not active");
        require(balanceOf(msg.sender) + numberOfTokens <= maxNumberOfTokens, "Exceeded allowed amount available to purchase");
        require(ts + numberOfTokens <= MAX_ALLOWLIST_SUPPLY, "Exceeded max available whitelist value");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Exceeded max available value");

        bytes32 message = Signature.prefixed(keccak256(abi.encodePacked(numberOfTokens, maxNumberOfTokens, msg.sender, address(this))));
        require(Signature.recoverSigner(message, signature) == _signerAddress, "Signer needs to authorize URI change");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintToAddress(msg.sender);
        }
    }

    function _mintToAddress(address to) private {
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _tokenIds.increment();

        // emit rarible royalty event
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0].value = 1000;
        royalties[0].account = payable(_royaltyWallet);
        emit RoyaltiesSet(newItemId, royalties);
    }

    /**
     *  URI functions
     */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
    
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://meta.monoliths.art/x/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://meta.monoliths.art/c/2";
    }

    /**
     *  Art Encoding
     *
     * The art encoding is done by contract owner after user signs permission to do so
     */

    function encodeArt(uint256 tokenId, string calldata uri, bytes calldata signature) public {
        require(_exists(tokenId), "URI set of nonexistent token");
        require(msg.sender == ownerOf(tokenId), "You don't own this token");

        string memory _currentTokenURI = _tokenURIs[tokenId];
        require(bytes(_currentTokenURI).length == 0, "This token is already encoded");
    
        bytes32 message = Signature.prefixed(keccak256(abi.encodePacked(tokenId, uri, address(this))));
        require(Signature.recoverSigner(message, signature) == _signerAddress, "Signer needs to authorize URI change");
    
        _tokenURIs[tokenId] = uri;
        emit ArtEncoded(msg.sender, tokenId);
    }

    function isArtEncoded(uint256 artTokenId) external view returns(bool) {
        string memory _currentTokenURI = _tokenURIs[artTokenId];
        return (bytes(_currentTokenURI).length != 0);
    }

    /**
     * Locking to monoliths
     */
    function isArtTokenLocked(uint256 artTokenId) external view override returns(bool) {
        return _artTokenLocked.get(artTokenId);
    }
    
    function lockArtToken(uint256 artTokenId) external override onlyMonoContract {
        require(_artTokenLocked.get(artTokenId) == false, "Art token is already locked");
        _artTokenLocked.set(artTokenId);
        emit ArtLocked(tx.origin, artTokenId);
    } 

    /**
     *  Pricing
     */
    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    /*
     * Royalties
     */

    function getRaribleV2Royalties(uint256 /*id*/) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = 1000;
        _royalties[0].account = payable(_royaltyWallet);
        return _royalties;
    }

    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (_royaltyWallet, _salePrice / 10);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    } 

    /*
     * Withdraw funds
     */
    function withdraw() public onlyMultiSig {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}
