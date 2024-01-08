pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
contract Lootpunk is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 constant INIT_COST = 10 ** 16; // 1eth = 10**18
    mapping(uint64 => uint256) private bagId2ClaimCost;
    ERC721 private lootContract;
    string private baseUri;
    event Claim(uint64 indexed bagId, address indexed who);
    constructor() ERC721("Lootpunk", "LOOTPUNK") Ownable() {
        lootContract = ERC721(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
        baseUri = string("https://api.lootpunk.org/metadata?tokenId=");
    }
    function linkLootContract(address addr) external onlyOwner {
        lootContract = ERC721(addr);
    }
    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }
    function claim(uint64 tokenId) public payable nonReentrant {
        require(lootContract.ownerOf(tokenId) == _msgSender(), "NOT an Owner of Loot");
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        uint256 cost = getCost(tokenId);
        require(msg.value >= cost, "Not enough ETH sent");
        if (_exists(tokenId)) {
            address old_owner = ownerOf(tokenId);
            _transfer(old_owner, _msgSender(), tokenId);
        } else {
            _safeMint(_msgSender(), tokenId);
        }
        bagId2ClaimCost[tokenId] = getCost(tokenId);
        emit Claim(tokenId, _msgSender());
    }
    function ownerMint(uint64 tokenId) external onlyOwner {
        require(!_exists(tokenId));
        _safeMint(_msgSender(), tokenId);
        emit Claim(tokenId, _msgSender());
    }
    function getCost(uint64 bagId) public view returns(uint256) {
        if (bagId2ClaimCost[bagId] < INIT_COST) return INIT_COST;
        return uint256(bagId2ClaimCost[bagId] * 103 / 100);
    }
    function withdraw(uint256 amount) external payable onlyOwner {
        payable(address(owner())).transfer(amount);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(owner() == _msgSender(), "transfer blocked");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(owner() == _msgSender(), "transfer blocked");
        _safeTransfer(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(owner() == _msgSender(), "transfer blocked");
        _safeTransfer(from, to, tokenId, _data);
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(owner() == _msgSender(), "transfer blocked");
    }
    function approve(address to, uint256 tokenId) public virtual override {
        require(owner() == _msgSender(), "transfer blocked");
        ERC721.approve(to, tokenId);
    }
}
