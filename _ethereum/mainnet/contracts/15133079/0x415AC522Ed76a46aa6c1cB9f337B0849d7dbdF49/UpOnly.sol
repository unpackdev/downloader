// SPDX-License-Identifier: MIT
/*

   $$\   $$\ $$$$$$$\         $$$$$$\  $$\   $$\ $$\   $$\     $$\ 
   $$ |  $$ |$$  __$$\       $$  __$$\ $$$\  $$ |$$ |  \$$\   $$  |
   $$ |  $$ |$$ |  $$ |      $$ /  $$ |$$$$\ $$ |$$ |   \$$\ $$  / 
   $$ |  $$ |$$$$$$$  |      $$ |  $$ |$$ $$\$$ |$$ |    \$$$$  /  
   $$ |  $$ |$$  ____/       $$ |  $$ |$$ \$$$$ |$$ |     \$$  /   
   $$ |  $$ |$$ |            $$ |  $$ |$$ |\$$$ |$$ |      $$ |    
   \$$$$$$  |$$ |             $$$$$$  |$$ | \$$ |$$$$$$$$\ $$ |    
    \______/ \__|             \______/ \__|  \__|\________|\__|    

 (for art lovers and degens only)

 --
 Up Only NFTs are a unique class of curated NFTs for artists:
 * Each NFT may only be listed at a higher price than previously sold
 * Transfer functions disabled (marketplaces HATE that)
 * Approve functions disabled (to avoid accidental gas wasting)
 * No burn function
 --

*/
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Strings.sol";

struct UpOnlyToken {
    address artist;
    uint256 listPrice;
    uint256 lastSalePrice;
    string  tokenURI;
}

contract UpOnly is ERC721, Ownable, ReentrancyGuard {

    uint256 constant private ARTIST_FEE = 5;
    uint256 constant private CONTRACT_FEE = 1;

    uint256 public supply;
    mapping(uint256 => UpOnlyToken) public tokens;

    event Mint(address indexed artist, uint256 indexed tokenId);
    event List(address indexed seller, uint256 indexed listPrice);
    event Sale(address indexed buyer, uint256 indexed salePrice);

    constructor() ERC721("UpOnly", "UP") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function list(uint256 tokenId, uint256 listPrice) external nonReentrant {
        require(listPrice > tokens[tokenId].lastSalePrice, "ser, this is an Up Only.");
        require(ownerOf(tokenId) == msg.sender, "you don't own that token.");

        tokens[tokenId].listPrice = listPrice;

        emit List(msg.sender, listPrice);
    }

    function buy(uint256 tokenId) external nonReentrant payable {
        uint256 listPrice = tokens[tokenId].listPrice;
        uint256 lastSalePrice = tokens[tokenId].lastSalePrice;
        address seller = ownerOf(tokenId);
        address artist = tokens[tokenId].artist;

        require(seller != address(0));
        require(artist != address(0));
        require(listPrice > 0, "uh that's not for sale");
        require(seller != msg.sender, "you already own that");
        require(msg.value == listPrice, "incorrect amount");
        require(listPrice > lastSalePrice, "ser, this is an Up Only");
        
        tokens[tokenId].lastSalePrice = listPrice;
        delete tokens[tokenId].listPrice;

        _transfer(seller, msg.sender, tokenId);

        (bool success, ) = artist.call{value: msg.value * ARTIST_FEE / 100 }("");
        require(success, "Artist fee payment failed.");

        (success, ) = seller.call{value: msg.value * (100 - CONTRACT_FEE - ARTIST_FEE) / 100}("");
        require(success, "Seller payment failed.");

        emit Sale(msg.sender, msg.value);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(supply > 0, "No items minted yet");
        require(tokens[tokenId].artist != address(0x0), "Token does not exist");
        require(bytes(tokens[tokenId].tokenURI).length > 0, "Metadata is empty");

        return tokens[tokenId].tokenURI;
    }

    //
    // Transfer/Approve functions disabled
    //

    function transferFrom(address, address, uint256) public virtual override {
        require(false, "Transfer disabled");
    }

    function safeTransferFrom(address, address, uint256) public virtual override {
        require(false, "Transfer disabled");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override { 
        require(false, "Transfer disabled");
    }

    function approve(address, uint256) public virtual override {
        require(false, "Approve disabled");
    }

    function setApprovalForAll(address, bool) public virtual override {
        require(false, "Approve disabled");
    }
    
    //
    // Owner functions beyond this point
    //

    function mint(address artist, string calldata tokenURI) external onlyOwner nonReentrant {
        require(artist != address(0x0), "Artist address must not be 0x0");
        uint256 tokenId = supply;
        
        _safeMint(artist, tokenId);
        tokens[tokenId] = UpOnlyToken(artist, 0, 0, tokenURI);
        ++supply;

        emit Mint(artist, tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}