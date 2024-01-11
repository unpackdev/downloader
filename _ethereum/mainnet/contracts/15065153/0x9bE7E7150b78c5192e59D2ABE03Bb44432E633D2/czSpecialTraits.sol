// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./iczSpecialEditionTraits.sol";

contract czSpecialTraits is iczSpecialEditionTraits, ERC721Enumerable, IERC2981, Ownable, Pausable, ReentrancyGuard {

    constructor() ERC721("CyberZillaz Special Edition Traits", "CZ-SET") {
        _pause();

        uint16 traitId = 1; //1
        traits[traitId] = Trait({ name: "Banana", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 2
        traits[traitId] = Trait({ name: "Mohawk", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 3
        traits[traitId] = Trait({ name: "Ninja", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 4
        traits[traitId] = Trait({ name: "Viking Hat", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 5
        traits[traitId] = Trait({ name: "Pipe", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 6
        traits[traitId] = Trait({ name: "Laurel Wreath", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 7
        traits[traitId] = Trait({ name: "ETH Chain", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 8
        traits[traitId] = Trait({ name: "Cigar", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 9
        traits[traitId] = Trait({ name: "Boss Hat", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 10
        traits[traitId] = Trait({ name: "Zillaz Chain", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 11
        traits[traitId] = Trait({ name: "Wings", traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
        traitId++; // 12
        traits[traitId] = Trait({ name: "Crown",traitId: traitId, price: 0.07 ether, maxMint: 20, minted: 0 });
    }

    /** EVENTS */
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenBurned(address indexed owner, uint256 indexed tokenId);

    /** PUBLIC VARS */
    // number of tokens have been minted so far
    uint16 public override totalMinted;
    // number of tokens have been burned so far
    uint16 public override totalBurned;
    // define if traits can be sold or not
    bool public traitsCanBeSold = false;
    address public royaltyAddress;
    // store all tokens and their traitId
    mapping(uint16 => Token) public tokens;
    // store all traits and their meta infos
    mapping(uint16 => Trait) public traits;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    // uri for revealing nfts traits
    string private _tokenRevealedBaseURI;
    // royalty permille (to support 1 decimal place)
    uint256 private _royaltyPermille = 75;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "SET: Only admins can call this");
        _;
    }

    /** ADMIN ONLY FUNCTIONS */
    function mint(uint16 traitId, address recipient) external override whenNotPaused nonReentrant onlyAdmin {
        Trait storage _trait = _getTraitStorage(traitId);
        require(_trait.minted + 1 <= _trait.maxMint, "SET: All tokens minted");
        
        // Increase mint counter
        totalMinted++;

        // Update mappings
        _trait.minted++;
        tokens[totalMinted] = Token({
            tokenId: totalMinted,
            traitId: traitId
        });

        // Mint the NFT
        _safeMint(recipient, totalMinted);

        emit TokenMinted(recipient, totalMinted);
    }

    function burn(uint16 tokenId) external override nonReentrant {
        if (!_admins[_msgSender()]) {
            require(ownerOf(tokenId) == _msgSender(), "SET: Cannot burn un-owned token");
        }

        totalBurned++;
        delete tokens[tokenId];

        emit TokenBurned(ownerOf(tokenId), tokenId);
        _burn(tokenId);
    }

    /** PUBLIC FUNCTIONS */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, salePrice * _royaltyPermille/1000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'SET: Token does not exist');
        
        Token memory _token = _getToken(uint16(tokenId));
        return string(abi.encodePacked(_tokenRevealedBaseURI, Strings.toString(_token.traitId)));
    }

    function getWalletOfOwner(address owner) external override view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }

    function getToken(uint16 tokenId) external override view returns (Token memory token) {
        return _getToken(tokenId);
    }
    function _getToken(uint16 tokenId) private view returns (Token memory token) {
        return tokens[tokenId];
    }

    function getTrait(uint16 traitId) external override view returns (Trait memory trait) {
        return _getTrait(traitId);
    }
    function _getTrait(uint16 traitId) private view returns (Trait memory trait) {
        return traits[traitId];
    }
    function _getTraitStorage(uint16 traitId) private view returns (Trait storage trait) {
        return traits[traitId];
    }

    /** OVERRIDE */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) nonReentrant {
        require(traitsCanBeSold, "SET: Traits cannot be sold at this point");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721, IERC721) nonReentrant {
        require(traitsCanBeSold, "SET: Traits cannot be sold at this point");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /** OWNER ONLY FUNCTIONS */
    function setTraitPrice(uint16 traitId, uint256 price) external onlyOwner {
        Trait memory myTrait = traits[traitId];
        myTrait.price = price;
        traits[traitId] = myTrait;
    }

    function setTraitsCanBeSold(bool sellable) external onlyOwner {
        traitsCanBeSold = sellable;
    }

    function setRevealedBaseURI(string calldata uri) external onlyOwner {
        _tokenRevealedBaseURI = uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        require(royaltyAddress != address(0), "SET: Royalty address must be set");
        if (_paused) _pause();
        else _unpause();
    }

    function setRoyaltyPermille(uint256 number) external onlyOwner {
        _royaltyPermille = number;
    }

    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

}