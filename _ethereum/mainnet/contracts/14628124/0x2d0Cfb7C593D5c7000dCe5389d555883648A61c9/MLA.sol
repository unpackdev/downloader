pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

// Parov Stelar X Flowtys
contract MoonlightLoveAffair is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    bool public saleActive = false;
    bool public allowListSaleActive = false;

    string public PROVENANCE;

    uint256 public constant TOKEN_LIMIT = 10000;
    uint256 public constant MAX_ALLOW_LIST_MINT_FL3 = 10;
    uint256 public constant MAX_ALLOW_LIST_MINT_FL2 = 7;
    uint256 public constant MAX_ALLOW_LIST_MINT_FL1 = 4;
    uint256 public constant MAX_PER_ADDRESS = 4;
    uint256 public constant TOKEN_PRICE_AL_FL3 = 0.06 ether;
    uint256 public constant TOKEN_PRICE_AL_FL2 = 0.07 ether;
    uint256 public constant TOKEN_PRICE_AL_FL1 = 0.08 ether;
    uint256 public constant TOKEN_PRICE_AL = 0.085 ether;
    uint256 public TOKEN_PRICE = 0.09 ether;
    
    bytes32 private _allowListRoot;
    bytes32 private _allowListRootFL;
    mapping(address => uint256) private _allowListClaimed;

    constructor() ERC721A("MoonlightLoveAffair", "MLAF", 10, TOKEN_LIMIT) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintAllowListFL(uint256 numTokens, bytes32[] calldata proof, uint256 tier) external payable callerIsUser nonReentrant {
        uint256 ts = totalSupply();
        uint256 _maxPerAddress = MAX_ALLOW_LIST_MINT_FL1;
        uint256 _tokenPrice = TOKEN_PRICE_AL_FL1;
        if (tier == 2) {
          _tokenPrice = TOKEN_PRICE_AL_FL2;
          _maxPerAddress = MAX_ALLOW_LIST_MINT_FL2;
        } else if (tier == 3) {
          _tokenPrice = TOKEN_PRICE_AL_FL3;
          _maxPerAddress = MAX_ALLOW_LIST_MINT_FL3;
        }
        require(_verify(_leaf(msg.sender), proof, _allowListRootFL), "Address is not on allowlist");
        require(allowListSaleActive, "The pre-sale is not active");
        require(_allowListClaimed[msg.sender].add(numTokens) <= _maxPerAddress, "Purchase would exceed max pre-sale tokens");
        require(ts.add(numTokens) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(msg.value == _tokenPrice.mul(numTokens), "Ether value sent is not the required price");

        _allowListClaimed[msg.sender] = _allowListClaimed[msg.sender].add(numTokens);
        _safeMint(msg.sender, numTokens);
    }

    function mintAllowList(uint256 numTokens, bytes32[] calldata proof) external payable callerIsUser nonReentrant {
        uint256 ts = totalSupply();
        require(_verify(_leaf(msg.sender), proof, _allowListRoot), "Address is not on allowlist");
        require(allowListSaleActive, "The pre-sale is not active");
        require(_allowListClaimed[msg.sender].add(numTokens) <= MAX_PER_ADDRESS, "Purchase would exceed max pre-sale tokens");
        require(ts.add(numTokens) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(msg.value == TOKEN_PRICE_AL.mul(numTokens), "Ether value sent is not the required price");

        _allowListClaimed[msg.sender] = _allowListClaimed[msg.sender].add(numTokens);
        _safeMint(msg.sender, numTokens);
    }

    function mint(uint256 quantity) external payable callerIsUser nonReentrant {
        uint256 ts = totalSupply();
        require(saleActive, "The sale is not active");
        require(quantity <= MAX_PER_ADDRESS, "Invalid number of tokens");
        require(ts.add(quantity) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(msg.value == TOKEN_PRICE.mul(quantity), "Ether value sent is not the required price");

        _safeMint(msg.sender, quantity);
    }

    // OWNER ONLY
    function reserve(uint256 quantity, address to) external onlyOwner {
      require(
        quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchSize"
      );
      uint256 numChunks = quantity / maxBatchSize;
      for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(to, maxBatchSize);
      }
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "price must be greater than zero");
        TOKEN_PRICE = newCost;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function flipSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function flipAllowListSaleActive() public onlyOwner {
        allowListSaleActive = !allowListSaleActive;
    }

    function setAllowListRoot(bytes32 _root) public onlyOwner {
        _allowListRoot = _root;
    }

    function setAllowListRootFL(bytes32 _root) public onlyOwner {
        _allowListRootFL = _root;
    }

    function withdraw(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");

        Address.sendValue(payable(to), amount);
    }

    // INTERNAL

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 _leafNode, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, _leafNode);
    }
}