// SPDX-License-Identifier: MIT
// _|_|_|                _|      _|
// _|    _|    _|_|_|  _|_|_|_|      _|_|_|      _|_|_|  _|      _|    _|_|    _|  _|_|    _|_|_|    _|_|
// _|    _|  _|    _|    _|      _|  _|    _|  _|    _|  _|      _|  _|_|_|_|  _|_|      _|_|      _|_|_|_|
// _|    _|  _|    _|    _|      _|  _|    _|  _|    _|    _|  _|    _|        _|            _|_|  _|
// _|_|_|      _|_|_|      _|_|  _|  _|    _|    _|_|_|      _|        _|_|_|  _|        _|_|_|      _|_|_|
//                                                   _|
pragma solidity ^ 0.8.7;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
contract DatingVerse is Ownable, ERC721A, ReentrancyGuard
{
    using SafeMath for uint256;
    enum Status {
        Pending, DiamondPreMint, DiamondMint, WhiteMint, PublicMint, Refund, Finished
    }
    Status public status;
    bool private placeholder = true;
    bool private reservedTags = false;
    bool private refundTags = false;
    uint public refundStartTime;
    bytes32 public merkleRoot;
    bytes32 public diamondPreMerkleRoot;
    bytes32 public diamondMerkleRoot;
    uint256 public immutable maxTotalDiamondSupply;
    uint256 public immutable maxTotalSupply;
    uint256 public immutable maxMint;
    uint256 public immutable price;
    constructor() ERC721A("Datingverse Genesis", "Datingverse Genesis") {
        maxTotalDiamondSupply = 500;
        maxTotalSupply = 5000;
        maxMint = 2;
        price = 0.1 ether;
        status = Status.Pending;
    }
    // Reserve some Datingverses for kol
    function reserveDatingverses() external onlyOwner {
        if (!reservedTags) {
            _safeMint(msg.sender, 20);
            reservedTags = true;
        }
    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }
    modifier mintQuantityVerify(uint256 quantity) {
        require(quantity > 0, "quantity > 0");
        require(_numberMinted(msg.sender) + quantity <= maxMint, "Max supply exceeded!");
        _;
    }
    modifier mintPriceVerify(uint256 quantity) {
        require(msg.value >= price * quantity, "Insufficient funds!");
        _;
    }
    function setStatus(Status _status) external onlyOwner {
        if(status == Status.Refund){
            require(refundStartTime + 10 days <= block.timestamp, "The refund time is not over yet!");
        }else if(_status == Status.Refund){
            require(!refundTags,"Refund completed");
            refundTags = true;
            refundStartTime = block.timestamp;
        }
        status = _status;
    }
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    function setDiamondPreMerkleRoot(bytes32 root) external onlyOwner {
        diamondPreMerkleRoot = root;
    }
    function setDiamondMerkleRoot(bytes32 root) external onlyOwner {
        diamondMerkleRoot = root;
    }
    function getPrice() public view returns(uint256) {
        return price;
    }
    function _startTokenId() override internal view virtual returns(uint256) {
        return 1;
    }
    function diamondPreMint(uint256 index, bytes32[] calldata merkleProof, uint256 quantity) external payable callerIsUser mintQuantityVerify(quantity) mintPriceVerify(quantity) {
        require(status == Status.DiamondPreMint, "diamondPreMint has not started yet!");
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender));
        require(MerkleProof.verify(merkleProof, diamondPreMerkleRoot, leaf), "Invalid merkle proof!");
        require(totalSupply() + quantity <= maxTotalDiamondSupply, "diamondSale would exceed max supply!");
        _safeMint(msg.sender, quantity);
    }
    function diamondMint(uint256 index, bytes32[] calldata merkleProof, uint256 quantity) external payable callerIsUser mintQuantityVerify(quantity) mintPriceVerify(quantity) {
        require(status == Status.DiamondMint, "diamondMint has not started yet!");
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender));
        require(MerkleProof.verify(merkleProof, diamondMerkleRoot, leaf), "Invalid merkle proof!");
        require(totalSupply() + quantity <= maxTotalDiamondSupply, "diamondSale would exceed max supply!");
        _safeMint(msg.sender, quantity);
    }
    function whiteMint(uint256 index, bytes32[] calldata merkleProof, uint256 quantity) external payable callerIsUser mintQuantityVerify(quantity) mintPriceVerify(quantity) {
        require(status == Status.WhiteMint, "whiteMint has not started yet!");
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof!");
        require(totalSupply() + quantity <= maxTotalSupply, "whiteSale would exceed max supply!");
        _safeMint(msg.sender, quantity);
    }
    function publicMint(uint256 quantity) external payable callerIsUser mintQuantityVerify(quantity) mintPriceVerify(quantity)
    {
        require(status == Status.PublicMint, "publicMint has not started yet!");
        _safeMint(msg.sender, quantity);
    }
    // // metadata URI
    string private _baseTokenURI;
    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns(string memory) {
        if (placeholder) {
            return string(abi.encodePacked(_baseTokenURI));
        }
        else {
            return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
        }
    }
    function togglePlaceholder() external onlyOwner {
        placeholder = !placeholder;
    }
    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner
    {
        require(status == Status.Finished && refundTags, "Invalid status!");
        uint256 balance = address(this) .balance;
        Address.sendValue(payable(msg.sender),balance);
    }

    function refund(uint256[] memory tokenIds) external callerIsUser {
        require(status == Status.Refund, "refund has not started yet!");
        require(tokenIds.length > 0, "no tokenId support!");
        require(tokenIds.length <= maxTotalSupply, "Invalid token!");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Invalid owner!");
            _burn(tokenIds[i]);
        }
        uint256 totalCost = price * tokenIds.length;
        Address.sendValue(payable(msg.sender), totalCost);
    }
}