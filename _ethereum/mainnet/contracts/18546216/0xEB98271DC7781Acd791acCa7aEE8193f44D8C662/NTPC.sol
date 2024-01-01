//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./ERC721Psi.sol";
import "./DefaultOperatorFilterer.sol";

contract NTPC is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant PRE_PRICE = 0.01 ether;
    uint256 public constant PUB_PRICE = 0.005 ether;

    uint256 public max_supply = 333;

    bool public preSaleStart = false;
    bool public pubSaleStart = false;

    uint256 public mintLimit = 10;
    uint256 public mintLimitPs = 2;

    bytes32 public merkleRoot;

    bool private _revealed = false;
    string private _baseTokenURI;
    string private _unrevealedURI = "https://ntpc-mint-page.pages.dev/uri/img/unreveal.json";

    mapping(address => uint256) public claimed;
    mapping(address => uint256) public claimedAl;

    constructor() ERC721Psi("NeoTokyoPunksCartoon", "NTPC") Ownable(0x7A3df47Cb07Cb1b35A6d706Fd639bfbD46e907Ac) {
        _setDefaultRoyalty(0xD075F2D6F90c27102f36EdfDe39Bc4de495CE541, 1000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721Psi) returns (string memory) {
        if (_revealed) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return _unrevealedURI;
        }
    }

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PUB_PRICE * _quantity;
        require(pubSaleStart, "Before sale begin.");
        _mintCheckForPubSale(_quantity, supply, cost);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkMerkleProof(
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function preMint(
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PRE_PRICE * _quantity;
        require(preSaleStart, "Before sale begin.");
        _mintCheckForPreSale(_quantity, supply, cost);

        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        claimedAl[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheckForPreSale(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + _quantity <= max_supply, "Max supply over");
        require(_quantity <= mintLimitPs, "Mint quantity over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            claimedAl[msg.sender] + _quantity <= mintLimitPs,
            "Already claimed max"
        );
    }

    function _mintCheckForPubSale(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + _quantity <= max_supply, "Max supply over");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= max_supply, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // only owner
    function setUnrevealedURI(string calldata _uri) public onlyOwner {
        _unrevealedURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setMintLimit(uint256 _quantity) public onlyOwner {
        mintLimit = _quantity;
    }

    function reveal(bool _state) public onlyOwner {
        _revealed = _state;
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        address creator = payable(0xD075F2D6F90c27102f36EdfDe39Bc4de495CE541); 
        address engineer = payable(0x7A3df47Cb07Cb1b35A6d706Fd639bfbD46e907Ac); 
        bool success;

        (success, ) = creator.call{value: ((sendAmount * 700) / 1000)}("");
        require(success, "Failed to withdraw Ether");
        (success, ) = engineer.call{value: ((sendAmount * 300) / 1000)}("");
        require(success, "Failed to withdraw Ether");
    }

    // OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royality
    function setRoyalty(
        address _royaltyAddress,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }

    // set max supply
    function setMaxSupply(uint256 _num) external onlyOwner {
        require(max_supply <= 1000, "Max supply need to be until 1000");
        max_supply = _num;
    }
}
