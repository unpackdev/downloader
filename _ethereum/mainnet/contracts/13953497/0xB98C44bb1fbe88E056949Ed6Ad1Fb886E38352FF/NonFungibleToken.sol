//▒███████▒ ▒█████   ███▄ ▄███▓ ▄▄▄▄    ██▓▓█████
//▒ ▒ ▒ ▄▀░▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▓██▒▓█   ▀
//░ ▒ ▄▀▒░ ▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██▒▒███
//  ▄▀▒   ░▒██   ██░▒██    ▒██ ▒██░█▀  ░██░▒▓█  ▄
//▒███████▒░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓░██░░▒████▒
//░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒░▓  ░░ ▒░ ░
//░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░  ░      ░▒░▒   ░  ▒ ░ ░ ░  ░
//░ ░ ░ ░ ░░ ░ ░ ▒  ░      ░    ░    ░  ▒ ░   ░
//  ░ ░        ░ ░         ░    ░       ░     ░  ░
//░                                  ░
// ███▄ ▄███▓ ▒█████   ███▄    █  ██ ▄█▀▓█████▓██   ██▓
//▓██▒▀█▀ ██▒▒██▒  ██▒ ██ ▀█   █  ██▄█▒ ▓█   ▀ ▒██  ██▒
//▓██    ▓██░▒██░  ██▒▓██  ▀█ ██▒▓███▄░ ▒███    ▒██ ██░
//▒██    ▒██ ▒██   ██░▓██▒  ▐▌██▒▓██ █▄ ▒▓█  ▄  ░ ▐██▓░
//▒██▒   ░██▒░ ████▓▒░▒██░   ▓██░▒██▒ █▄░▒████▒ ░ ██▒▓░
//░ ▒░   ░  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ▒ ▒▒ ▓▒░░ ▒░ ░  ██▒▒▒
//░  ░      ░  ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░▒ ▒░ ░ ░  ░▓██ ░▒░
//░      ░   ░ ░ ░ ▒     ░   ░ ░ ░ ░░ ░    ░   ▒ ▒ ░░
//       ░       ░ ░           ░ ░  ░      ░  ░░ ░
//                                             ░ ░
// ▄▄▄▄    █    ██   ██████  ██▓ ███▄    █ ▓█████   ██████   ██████
//▓█████▄  ██  ▓██▒▒██    ▒ ▓██▒ ██ ▀█   █ ▓█   ▀ ▒██    ▒ ▒██    ▒
//▒██▒ ▄██▓██  ▒██░░ ▓██▄   ▒██▒▓██  ▀█ ██▒▒███   ░ ▓██▄   ░ ▓██▄
//▒██░█▀  ▓▓█  ░██░  ▒   ██▒░██░▓██▒  ▐▌██▒▒▓█  ▄   ▒   ██▒  ▒   ██▒
//░▓█  ▀█▓▒▒█████▓ ▒██████▒▒░██░▒██░   ▓██░░▒████▒▒██████▒▒▒██████▒▒
//░▒▓███▀▒░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░░▓  ░ ▒░   ▒ ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░
//▒░▒   ░ ░░▒░ ░ ░ ░ ░▒  ░ ░ ▒ ░░ ░░   ░ ▒░ ░ ░  ░░ ░▒  ░ ░░ ░▒  ░ ░
// ░    ░  ░░░ ░ ░ ░  ░  ░   ▒ ░   ░   ░ ░    ░   ░  ░  ░  ░  ░  ░
// ░         ░           ░   ░           ░    ░  ░      ░        ░
//      ░



//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Pausable.sol";
import "Whitelist.sol";


/**
 * @dev Implementation of Non-Fungible Token Standard (ERC-721), including some extensions such
 * as EIP-2981 and off-chain whitelisting. This contract is designed to be ready-to-use and versatile.
 */
contract ZombieMonkeyBusiness is ERC721URIStorage, Ownable, Pausable, Whitelist {

    // general constants and immutable variables
    uint256 immutable public COLLECTION_MAX_ITEMS;          // maximum number of items in the collection
    uint256 public constant ROYALTY_DENOM = 1000;           // denominator used for fractions
    uint256 public immutable MAX_ROYALTY_NUM;               // maximum royalty numerator

    uint256 public maxMintsPerTx;                           // maximum number of mints per transaction
    uint256 public maxWhitelistMint;                        // maximum number of NFTs that can be minted during whitelist period
    uint256 public startingTime;                            // UTC timestamp when minting starts
    uint256 public royaltyNum;                              // numerator for royalties (see EIP-2981)
    uint256 public price;                                   // price for minting one NFT

    uint256 public totalSupply;                             // number of NFTs minted thus far
    uint256 public totalWhitelistMinted;                    // number of NFTs minted during whitelist period
    bool public specialMintLocked;                          // when `true`, `specialMint` cannot longer be called
    mapping(uint256 => address) public royalties;           // mapping for royalties


    mapping(bytes32 => uint256) internal _whitelistMinted;  // number of NFT minted per address during the whitelist period
    mapping(address => uint256[]) internal _ownerToIds;     // mapping from owner to list of owned NFT IDs.
    mapping(uint256 => uint256) internal _idToOwnerIndex;
    string internal __baseURI;
    string internal _extensionURI;


    constructor(string memory name_,
                string memory symbol_,
                uint256 collectionMaxItems_,
                uint256 maxMintsPerTx_,
                uint256 price_,
                uint256 startingTime_,
                uint256 maxRoyaltyNum_,
                uint256 royaltyNum_,
                uint256 maxWhitelistMint_,
                string memory _baseURI_,
                string memory _extensionURI_) ERC721(name_, symbol_){
        require(royaltyNum_ <= maxRoyaltyNum_, "royalty exceeds maximum authorized value");
        require(maxWhitelistMint_ <= collectionMaxItems_, "max whitelist cannot exceed max supply");
        COLLECTION_MAX_ITEMS = collectionMaxItems_;
        MAX_ROYALTY_NUM = maxRoyaltyNum_;
        setPrice(price_);
        maxMintsPerTx = maxMintsPerTx_;
        startingTime = startingTime_;
        royaltyNum = royaltyNum_;
        maxWhitelistMint = maxWhitelistMint_;
        setSigner(msg.sender);
        __baseURI = _baseURI_;
        _extensionURI = _extensionURI_;
    }


    function setMaxMintsPerTx(uint256 _newMaxMintsPerTx) external onlyOwner {
        maxMintsPerTx = _newMaxMintsPerTx;
    }


    function setMaxWhitelistMint(uint256 _maxWhitelistMint) external onlyOwner {
        require(_maxWhitelistMint <= COLLECTION_MAX_ITEMS, "max whitelist cannot exceed max supply");
        maxWhitelistMint = _maxWhitelistMint;
    }


    function setStartingTime(uint256 _startingTime) external onlyOwner {
        startingTime = _startingTime;
    }


    function setRoyaltyNum(uint256 _newRoyaltyNum) public onlyOwner {
        require(_newRoyaltyNum <= MAX_ROYALTY_NUM, "royalty exceeds maximum authorized value");
        royaltyNum = _newRoyaltyNum;
    }


    function setPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "price must be positive");
        price = _newPrice;
    }


    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        __baseURI = _newBaseURI;
    }


    function setExtensionURI(string memory _newExtensionURI) external onlyOwner {
        _extensionURI = _newExtensionURI;
    }


    function setSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "signer cannot be the zero address");
        _signer = _newSigner;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == 0x2a55205a;     // EIP-2981 interface for royalties
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(bytes(_extensionURI).length == 0){
            return super.tokenURI(tokenId);
        }
        return string(abi.encodePacked(super.tokenURI(tokenId), _extensionURI));
    }


    function getOwnerNFTs(address owner) public view returns (uint256[] memory){
		return _ownerToIds[owner];
	}


    function mint() external payable whenNotPaused {
        require(block.timestamp > startingTime, "minting not open yet");

        uint256 _numToMint = _getNumToMint(price);

        for(uint256 i=totalSupply; i < (totalSupply + _numToMint); i++){
            _mint(msg.sender, i);
        }
        totalSupply += _numToMint;
    }


    // The param `_amount` is ignored if `_price` is positive. When price is positive, msg.sender
    // is used to infer amount to mint. When price is equal to zero, `_amount` is used.
    function whitelistMint(uint256 _maxAmount, uint256 _price, uint256 _amount, bytes memory _signature) external payable whenNotPaused {
        require(_verify(msg.sender, _maxAmount, _price, _signature), "invalid arguments or not whitelisted");

        uint256 _numToMint = _price > 0 ? _getNumToMint(_price) : _isValidMint(_amount);

        for(uint256 i=totalSupply; i < (totalSupply + _numToMint); i++){
            _mint(msg.sender, i);
        }

        totalSupply += _numToMint;
        totalWhitelistMinted += _numToMint;
        bytes32 _hash = _getMessageHash(msg.sender, _maxAmount, _price);
        _whitelistMinted[_hash] += _numToMint;

        require(totalWhitelistMinted <= maxWhitelistMint, "over whitelist limit");
        require(_whitelistMinted[_hash] <= _maxAmount, "over account whitelist limit");
    }


    function specialMint(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(!specialMintLocked, "special mint permanently locked");
        require(recipients.length == amounts.length, "arrays have different lengths");
        for(uint256 i=0; i < recipients.length; i++){
            for(uint256 j=totalSupply; j < (totalSupply + amounts[i]); j++){
                _mint(recipients[i], j);
            }
            totalSupply += amounts[i];
        }
        require(totalSupply <= COLLECTION_MAX_ITEMS, "would exceed supply");
    }


    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId),
                    "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }


    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
        returns (address receiver, uint256 royaltyAmount) {
            require(_exists(_tokenId), "operator query for nonexistent token");
            royaltyAmount = (_salePrice * royaltyNum) /  ROYALTY_DENOM;
            receiver = royalties[_tokenId];
    }


    // permanently prevent dev from calling `specialMint`.
    function lockSpecialMint() external onlyOwner
    {
        specialMintLocked = true;
    }


    function withdraw() external payable onlyOwner returns (bool success) {
        (success,) = payable(owner()).call{value: address(this).balance}("");
    }


    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        royalties[tokenId] = to;
    }


    function _isValidMint(uint256 _numToMint) private view returns(uint256){
        require(_numToMint > 0, "not enough");
        require((_numToMint + totalSupply) <= COLLECTION_MAX_ITEMS,
                        "would exceed max supply");
        require(_numToMint <= maxMintsPerTx, "limit on minting too many at a time");
        return _numToMint;
    }


    function _getNumToMint(uint256 _price) private view returns(uint256 _numToMint) {
        _numToMint = msg.value / _price;
        _isValidMint(_numToMint);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if(from != address(0)){
            require(from == ownerOf(tokenId), "not owner");
        }

        if(from == to){
            return;
        }

        uint256 _idToPreviousOwnerIndex = _idToOwnerIndex[tokenId];

        // adding token to array of new owner
        if(to != address(0)){
            _ownerToIds[to].push(tokenId);
            _idToOwnerIndex[tokenId] = _ownerToIds[to].length - 1;
        }

        // remove token from array of previous owner
        if(from != address(0)){
            uint256 _len = _ownerToIds[from].length;
            if(_idToPreviousOwnerIndex < (_len - 1)){
                _ownerToIds[from][_idToPreviousOwnerIndex] = _ownerToIds[from][_len - 1];
                _idToOwnerIndex[_ownerToIds[from][_len - 1]] = _idToPreviousOwnerIndex;
            }
            _ownerToIds[from].pop();
        }
    }


    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}
