// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721AQueryable.sol";

contract DDuck is ERC721AQueryable, Ownable {
    uint256 public constant PRESERVED_MINTS = 150;
    uint256 public constant FREE_MINTS = 450;
    uint256 public constant FIRST_STAGE = 1500;
    uint256 public constant MAX_SUPPLY = 3000;
    // uint256 public constant PRESERVED_MINTS = 2;
    // uint256 public constant FREE_MINTS = 4;
    // uint256 public constant FIRST_STAGE = 10;
    // uint256 public constant MAX_SUPPLY = 20;
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public constant MAX_FREE_MINT_PER_ACCOUNT = 2;

    bool public mintStart;
    string private baseURI;
    uint256 public mintPrice = 0.003 ether;

    constructor() ERC721A("DuckDuckWorld", "DDW") {}

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function preserveMint() external onlyOwner {
        require(mintCount() == 0, "already preminted");
        _safeMint(msg.sender, PRESERVED_MINTS);
    }

    function flipMintstart() external onlyOwner {
        mintStart = !mintStart;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function mintCount() public view returns (uint256) {
        return _nextTokenId() - _startTokenId();
    }

    function mint(uint256 quantity) external payable nonContractCaller {
        require(mintStart, "mint not started");
        require(quantity <= MAX_MINT_PER_TX, "Mint amount should <= 5");
        uint256 _mintCount = mintCount();
        uint256 _mintToCount = _mintCount + quantity;
        uint256 refunds;
        if (_mintCount < FREE_MINTS + PRESERVED_MINTS) {
            require(_mintToCount <= FREE_MINTS + PRESERVED_MINTS, "Mint amount exceed free-mint supply");
            require(balanceOf(msg.sender) + quantity <= MAX_FREE_MINT_PER_ACCOUNT, "Exceed free mint amount per account");
            refunds = msg.value;
        } else {
            require(_mintToCount <= MAX_SUPPLY, "Mint amount exceed max supply");
            uint256 payedPrice = quantity * mintPrice;
            require(msg.value >= payedPrice, "Not enought mint funds");
            if (msg.value > payedPrice) refunds = msg.value - payedPrice;
        }
        if (_mintCount < FIRST_STAGE) {
            require(_mintToCount <= FIRST_STAGE, "Mint amount exceed first stage");
            if (_mintToCount == FIRST_STAGE) mintStart = false;
        }
        if (refunds > 0) payable(msg.sender).transfer(refunds);
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }

    modifier nonContractCaller() {
        require(tx.origin == msg.sender, "cannot call from contract");
        _;
    }
}
