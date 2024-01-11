// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";

contract Programmer is ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {

    event Mint(address indexed account, uint256 indexed tokenid);

    uint256 constant public MAX_TOKEN = 10000;
    uint256 constant public MAX_FREE_TOKEN = 5000;
    uint256 public TEAM_KEEP = 500;

    uint256[MAX_TOKEN] internal _randIndices;
    mapping(address => uint256) public freeMintNum;
    mapping(address => uint256) public saleMintNum;

    uint64 constant public MAX_TOKENS_PER_ACCOUNT_FOR_FREE = 2;
    uint64 constant public MAX_TOKENS_PER_ACCOUNT_FOR_SALE = 5;

    string private _internalbaseURI;

    uint256 constant public price = 0.005 ether;
    bool public saleStarting;

    constructor(string memory baseURI_) ERC721("Great Programmer Club", "GPC") {
        _internalbaseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalbaseURI;
    }

    function freeMint(uint256 num) external callerIsUser mintStarting nonReentrant {
        require(totalSupply() + num <= MAX_FREE_TOKEN, "over free supply");
        require(freeMintNum[msg.sender] + num <= MAX_TOKENS_PER_ACCOUNT_FOR_FREE, "OVER TOKENS PER ACCOUNT FOR FREE");
        freeMintNum[msg.sender] += num;
        mint(msg.sender, num);
    }

    function saleMint(uint256 num) external payable callerIsUser mintStarting nonReentrant {
        require(totalSupply() + num <= MAX_TOKEN - TEAM_KEEP, "over total supply");
        require(saleMintNum[msg.sender] + num <= MAX_TOKENS_PER_ACCOUNT_FOR_SALE, "OVER TOKENS PER ACCOUNT FOR SALE");
        require(msg.value == price * num, "error pay amount");
        saleMintNum[msg.sender] += num;
        mint(msg.sender, num);
    }

    function teamMint(uint256 num) external onlyOwner {
        require(totalSupply() + num <= MAX_TOKEN - TEAM_KEEP, "over total supply");
        require(num <= TEAM_KEEP, "OVER TEAM AMOUNT");
        mint(msg.sender, num);
        TEAM_KEEP-= num;
    }

    function mint(address to, uint256 num) internal {
        for (uint i = 0; i < num; i++) {
            uint256 tokenid = getRandomTokenId();
            super._safeMint(to, tokenid);
            emit Mint(to, tokenid);
        }
    }

    function claim() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "token transfer paused");
    }

    function emergencyPause() external onlyOwner {
        _pause();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _internalbaseURI = uri;
    }

    function getRandomTokenId() internal returns (uint256) {
        unchecked {
            uint256 remain = MAX_TOKEN - totalSupply();
            uint256 pos = unsafeRandom() % remain;
            uint256 val = _randIndices[pos] == 0 ? pos : _randIndices[pos];
            _randIndices[pos] = _randIndices[remain - 1] == 0 ? remain - 1 : _randIndices[remain - 1];
            return val;
        }
    }

    function unsafeRandom() internal view returns (uint256) {
        unchecked {
            return uint256(keccak256(abi.encodePacked(
                blockhash(block.number-1), 
                block.difficulty,
                block.timestamp, 
                totalSupply(), 
                tx.origin,
                gasleft()
            )));
        }
    }

    function saleStart() external onlyOwner {
        saleStarting = true;
    }

    modifier mintStarting() {
        require(saleStarting == true, "sale not starting");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}