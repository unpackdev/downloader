// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Administration.sol";
import "./Strings.sol";

contract BEAN is ERC721A, Ownable, Administration { 
    uint public price = 0.033 ether;
    uint public maxSupply = 3333;
    uint public maxTx = 20;
    uint public reserve = 99;

    uint256 public mintTimestamp;
    uint256 public wlTimestamp;

    bytes32 public merkleRoot = 0x3f40bac8664dbdb5e9e91586e43380d39619fb9b8279dc88384c3a0061ebe753;
    uint256 public nextTokenId;
    
    mapping(address => uint[]) private ownership;

    string internal baseTokenURI = '';

    string internal _contractURI = 'ipfs://QmPEtQL7s5AZMZF4C82V7gNG8L2Xq7uPnV5qDoPzVHT3HH';
    
    constructor(uint256 _wlTimestamp, uint256 _mintTimestamp) ERC721A("BEAN", "BEAN") {
        mintTimestamp = _mintTimestamp;
        wlTimestamp = _wlTimestamp;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setContractURI(string calldata contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setWlTimestamp(uint256 _activationTimestamp) external onlyOwner {
        wlTimestamp = _activationTimestamp;
    }

    function setMintTimestamp(uint256 _activationTimestamp) external onlyOwner {
        mintTimestamp = _activationTimestamp;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty);
    }

    function mintToReserved(address to, uint qty) external onlyAdmin {
        _mintToReserved(to, qty);
    }

    function buy(uint qty, bytes32[] calldata merkleProof) external payable {
        require(wlTimestamp <= block.timestamp, "store closed");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "address not in whitelist");
        _buy(qty);
    }
    
    function buy(uint qty) external payable {
        require(mintTimestamp <= block.timestamp, "store closed");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        uint free = balanceOf(_msgSender()) == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free), "PAYMENT: invalid value");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply - reserve, "SUPPLY: Value exceeds totalSupply");
        _mint(to, qty);
    }

    function _mintToReserved(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "ipfs://QmTngYMA1rEBrGRMbeY9ac45nF2916JKZ9x3BTTPZGQeG9";
    }
}
