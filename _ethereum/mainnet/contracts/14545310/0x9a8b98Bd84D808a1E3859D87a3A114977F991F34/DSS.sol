pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract DarkSideShadies is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    bool public allowListSaleActive = false;

    string public PROVENANCE;

    uint256 public constant TOKEN_LIMIT = 101;
    uint256 public constant MAX_ALLOW_LIST_MINT = 1;
    
    bytes32 private _allowListRoot;
    mapping(address => uint256) private _allowListClaimed;

    constructor() ERC721A("DarkSideShadies", "DSS", 1, TOKEN_LIMIT) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintAllowList(bytes32[] calldata proof) external callerIsUser {
        uint256 ts = totalSupply();
        require(_verify(_leaf(msg.sender), proof), "Address is not on allowlist");
        require(allowListSaleActive, "The sale is not active");
        require(_allowListClaimed[msg.sender] == 0, "Purchase would exceed max tokens");
        require(ts.add(1) <= TOKEN_LIMIT, "Purchase would exceed max tokens");

        _allowListClaimed[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }

    // OWNER ONLY
    function reserve(uint256 quantity) external onlyOwner {
      _safeMint(msg.sender, quantity);
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function flipAllowListSaleActive() public onlyOwner {
        allowListSaleActive = !allowListSaleActive;
    }

    function setAllowListRoot(bytes32 _root) public onlyOwner {
        _allowListRoot = _root;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
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

    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _allowListRoot, _leafNode);
    }
}