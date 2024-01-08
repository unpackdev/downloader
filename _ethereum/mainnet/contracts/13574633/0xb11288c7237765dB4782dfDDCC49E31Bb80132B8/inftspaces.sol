// SPDX-License-Identifier: MIT
// Copyright 2021 Inftspaces & Martin Wawrusch
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
// associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721Burnable.sol";


/***
 We need to whitelist mintLiveEvent function - topmost priority
 We would like to whitelist (seperately from the mintLiveEvent function) the mintInftspaces function, when the saleWhitelistIsActive flag is true.
 e.g. those are two different whitelists. 

 Questions:
 * What would be the benefits of using enumerable long term? Should it be removed for minting cost reduction?
 * Should we include the opensea proxy code functionality for? If so what would we need to add (looking at https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol) with proxy and meta transactions
 * Should we implement the new rarible standard for comissions? 
 * Code Quality? Improvements?
 */

///
/// URL Handling
/// By default we use the base URL for the token combined with the tokenid, but if it has been overriden during minting or set explicitely
/// then we use the one provided there. The idea is to be able to convert all NFTs to IPFS storage when Ethereum switched to Staking and prices are reasonable to update the 8888 tokens.
/// 
/// Also, to support reveal we make the baseUrl settable, so before the reveal we switch it to the final url.
/// @custom:security-contact info@inftspaces.com
contract Inftspaces is ERC721, ERC721Enumerable, ERC721Burnable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE;

    
    mapping(address => bool) public claimedFreeNft;
    mapping(address => uint256) public purchasedForAddress;

    uint256 public price = 60_000_000_000_000_000; // 0.060 ETH

    /// @dev The tokens that are minted for special sales and or participating artists.
    uint256 public constant CUSTOM_RESERVE = 100;
    /// @dev The maxtokens are the total tokens - the custom reservce.
    uint256 public constant MAX_TOKENS = 8788;

    uint256 public constant MAX_PURCHASE_PER_MINT = 11;
    uint256 public maxPurchasePerAccount = 11;

    bool public saleIsActive;
    bool public saleWhitelistIsActive = true;
    bool public isLiveMintingActive;
    uint256 public maxForSale = 2000;

    string public baseURI = "https://dujurg1wstjc2.cloudfront.net/metaphysical-rift/";

    string private _contractURI;

    address public mintLiveEventSigner;

    bool public tokenURIsFrozen;


    Counters.Counter private _tokenIdCounter;

    /// Opensea 'freezing' event.
    event PermanentURI(string _value, uint256 indexed _id);

    /// Invoked when we live minted an NFT
    event LiveMinted(address indexed _to, uint256 indexed _tokenId);

    /// Invoked when the live minting activation has been changed.
    event SetLiveMintingActive(bool _active);

    /// Invoked when the sale price is updated.
    //event PriceChanged(uint256 _price);

    /// Invoked when the sale activation has been changed.
    event SaleIsActive(bool _isActive);

    constructor() ERC721("inftspaces - Metaphysical Rift", "INFTMR") {

    }

    /// @notice Mints between 1 and 10 NFTs.
    /// @param numberOfTokens The number of tokens to mint, a valid number of 1 to 10
    function mintInftspaces(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not active");
        require(numberOfTokens > 0, "1 token min");
        require(numberOfTokens <= MAX_PURCHASE_PER_MINT, "11 tokens max");
        
        require(_tokenIdCounter.current().add(numberOfTokens) <= maxForSale, "Max supply exceeded");
        require(msg.value >= price.mul(numberOfTokens), "Wrong ETH amount");

        uint256 mintedSoFar = purchasedForAddress[msg.sender];
        require(mintedSoFar + numberOfTokens <= maxPurchasePerAccount, "11 tokens per account");


        purchasedForAddress[msg.sender] = mintedSoFar + numberOfTokens;
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, mintIndex);
        }
    }

    /// @notice Mint a token (If you have been whitelisted at an event).
    /// @dev Called buy visitors of our live events. They are entitled to 1 mint per whitelisted address.
    function mintLiveEvent(uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,_r,_s) public {
        require(isLiveMintingActive, "Live minting inactive");
        require(_tokenIdCounter.current().add(1) <= MAX_TOKENS, "Max supply exceeded");
        require(!claimedFreeNft[msg.sender], "Already claimed");

        uint256 mintIndex = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        claimedFreeNft[msg.sender] = true;
        _safeMint(msg.sender, mintIndex);

        emit LiveMinted(msg.sender, mintIndex);
    }

    /// @notice Live minting support for the smart contract owner
    /// @dev Used only in cases where people show up on the live events and don't have money in their ether.
    function mintLiveForAddress(address to) public onlyOwner {
        require(to != address(0), "No zero address");

        require(_tokenIdCounter.current().add(1) <= MAX_TOKENS, "Max supply exceeded");

        uint256 mintIndex = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, mintIndex);
    }

    /// @notice Mint custom reserve NFTs for featured artists
    /// @dev Used to create custom NFT sets for artists
    function mintCustomForAddress(address to, uint256 tokenId) public onlyOwner {
        require(to != address(0), "No zero address");
        require(tokenId >= MAX_TOKENS, "TokenId >= 8788");
        require(tokenId < MAX_TOKENS + CUSTOM_RESERVE, "TokenId <= 8887");
        require(!_exists(tokenId), "Token exists");

        _safeMint(to, tokenId);
    }

    /// @notice Fund withdrawal for owner.
    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    /// @notice sets the price in gwai for a single nft sale. 
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
        // emit PriceChanged( newPrice);
    }

    function setMaxPurchasePerAccount(uint256 newMaxPurchasePerAccount) public onlyOwner {
        maxPurchasePerAccount = newMaxPurchasePerAccount;
    }
    

    function setContractURI(string calldata newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    
    /// @notice enables/disables the pre sale and sale.
    function setMintLiveEventSigner(address adr) public onlyOwner {
        mintLiveEventSigner = adr;
    }

    /// @notice enables/disables the pre sale and sale.
    function setSaleIsActive(bool active) public onlyOwner {
        saleIsActive = active;
        emit SaleIsActive( active);
    }

    /// @notice enables/disables the pre sale and sale.
    function setTokenURIsFrozen() public onlyOwner {
        tokenURIsFrozen = true;
    }

    function setProvenanceHash(string calldata provenanceHash) public onlyOwner {
        require(bytes(PROVENANCE).length == 0, "PROVENANCE SET");
        PROVENANCE = provenanceHash;
    }
    

    /// @notice The live minting action is limited in time. People who do not mint in time will lose their slot.
    function setLiveMintingActive(bool active) public onlyOwner {
        isLiveMintingActive = active;
        emit SetLiveMintingActive(active);
    }

    /// @notice Sets the maximum number of tokens that can be sold right now (presale)
    function setMaxForSale(uint256 newMaxForSale) public onlyOwner {
        require(newMaxForSale <= MAX_TOKENS, "Must be 8788 or less");
        maxForSale = newMaxForSale;
    }


    /// @notice The whitelist is by default activated for the sale, but it needs to be deactivated past the presale, otherwise we won't be able to sell without whitelist.
    function setSaleWhitelistIsActive(bool active) public onlyOwner {
        saleWhitelistIsActive = active;
    }

    /// @dev This is set to empty to ensure that we can disambiguate between a stored full url and an url that is composed from the actual base url and the tokenid. Never change this.
    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    /// @notice Sets the baseURL, which needs to have a trailing /
    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "Not minted");

        string memory uri = super.tokenURI(tokenId);

        return bytes(uri).length > 0 ? uri : string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // /// @notice Will be used by the owner to permanently freeze the metadata on ipfs once Ethereum moves to PoS
    // /// This can be set as long as tokenURIs are not frozen or it has not been set to a dedicated value.
    // function freezeMetadata(uint256 tokenId, string calldata uri) public onlyOwner{
    //     require(_exists(tokenId), "Not minted");
    //     require(!tokenURIsFrozen || bytes(super.tokenURI(tokenId)).length == 0, "Token URIs frozen");

    //     _setTokenURI(tokenId, uri);
    //     emit PermanentURI(uri, tokenId);
    // }

    /// @notice Will be used by the owner to permanently freeze the metadata on ipfs once Ethereum moves to PoS
    /// This can be set as long as tokenURIs are not frozen or it has not been set to a dedicated value.
    function freezeMetadatas(uint256 tokenId, string[] calldata uris) public onlyOwner{
          for(uint256 i = 0; i < uris.length; i++) {
            uint256 mintIndex = tokenId + i;

            require(_exists(mintIndex), "Not minted");
            require(!tokenURIsFrozen || bytes(super.tokenURI(mintIndex)).length == 0, "Token URIs frozen");

            _setTokenURI(mintIndex, uris[i]);
            emit PermanentURI(uris[i], mintIndex);
        }
    }
     
   /* 
    * @dev Requires msg.sender to have valid access message.
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    */
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) 
    {
        require( isValidAccessMessage(msg.sender,_v,_r,_s), "Invalid signer" );
        _;
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(
        address _add,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s) 
        public view returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(this, _add));
        return /* owner() */ mintLiveEventSigner == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            _v,
            _r,
            _s
        );
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }


}


