// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract AnimalWarriors is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint64;

    bytes32 public merkleRoot;

    uint256 public constant maxSupply = 7777;
    uint256 public constant presaleCount = 1555;
    uint256 private _price = 0.05 ether;
    uint256 private _reserved = 200;

    bool private _saleStarted;
    bool private _presaleStarted;
    string public baseURI;

    mapping(uint256 => uint64) public metadata;

    event Minted(address account, uint256 amount, uint256 cost);
    event PresaleMinted(address account, uint256 amount, uint256 cost);

    constructor() ERC721("Animal Warriors", "AW") {
        _saleStarted = false;
        _presaleStarted = false;
    }

    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }

    modifier whenPresaleStarted() {
        require(_presaleStarted);
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external {
        merkleRoot = _merkleRoot;
    }

    function presaleMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        whenPresaleStarted
    {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        uint256 supply = totalSupply();

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof."
        );
        require(amount * _price <= msg.value, "Inconsistent amount sent!");
        require(
            supply + amount <= presaleCount,
            "Not enough Tokens left for presale."
        );

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        emit PresaleMinted(msg.sender, amount, msg.value);
    }

    function mint(uint256 amount) external payable whenSaleStarted {
        uint256 supply = totalSupply();
        require(amount < 21, "You cannot mint more than 20 Tokens at once!");
        require(
            supply + amount <= maxSupply - _reserved,
            "Not enough Tokens left."
        );
        require(amount * _price <= msg.value, "Inconsistent amount sent!");

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        emit Minted(msg.sender, amount, msg.value);
    }

    function togglePresaleStarted() external onlyOwner {
        _presaleStarted = !_presaleStarted;
    }

    function presaleStarted() public view returns (bool) {
        return _presaleStarted;
    }

    function toggleSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function saleStarted() public view returns (bool) {
        return _saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // Make it possible to change the price: just in case
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getReservedLeft() public view returns (uint256) {
        return _reserved;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function claimReserved(uint256 _number, address _receiver)
        external
        onlyOwner
    {
        require(_number <= _reserved, "That would exceed the max reserved.");

        uint256 _tokenId = totalSupply();
        if (_tokenId < presaleCount) _tokenId = presaleCount;

        for (uint256 i = 1; i <= _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved = _reserved - _number;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
