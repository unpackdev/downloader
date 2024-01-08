// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

interface IMerkleDistributor {
    function merkleRoot() external view returns (bytes32);
    function isClaimed(uint256 index) external view returns (bool);
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    event Claimed(uint256 index, address account, uint256 amount);
}

contract MagicGoatBox is Ownable, ERC721, IMerkleDistributor {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public constant mintLimit = 20;
    uint256 public constant mintPrice = 0.05 ether;
    uint256 public constant maxTotalSupply = 8192;
    uint256 public constant maxReserveLimit = 500;
    
    string public baseURI = "";
    uint256 public totalSupply = 0;
    uint256 public reserveLimit = 0;
    uint256 public saleStartTime = 1631718000;

    bool public claimActive = true;
    bytes32 public override merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;

    event Minted(address indexed _user, uint256 indexed _tokenId, string _tokenURI);

    constructor(string memory _baseURI, bytes32 _merkleRoot) ERC721("Magic Goat Box", "MGX") {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }
    
    function setClaimActive(bool _claimActive) external onlyOwner {
        claimActive = _claimActive;
    }
    
    function airdrop(address _addr, uint256 _num) external onlyOwner {
        require(reserveLimit.add(_num) <= maxReserveLimit, "Not enough tokens left.");
        
        reserveLimit = reserveLimit.add(_num);
        _batchMint(_addr, _num);
    }

    function withdraw(address payable _addr, uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance.");

        payable(_addr).transfer(_amount);
    }
    
    function _batchMint(address _addr, uint256 _num) private {
        require(totalSupply.add(_num) <= maxTotalSupply, "Not enough tokens left.");

        uint256 tokenId = totalSupply;
        for(uint i = 0; i < _num; i++) {
            tokenId = tokenId.add(1);

            totalSupply = totalSupply.add(1);
            _safeMint(_addr, tokenId);

            emit Minted(_addr, tokenId, tokenURI(tokenId));
        }
    }

    function mint(uint256 _num) external payable {
        require(totalSupply.sub(reserveLimit).add(_num) <= maxTotalSupply.sub(maxReserveLimit), "Sold out.");
        require(block.timestamp >= saleStartTime, "Sale is not active.");
        require(_num > 0 && _num <= mintLimit, "Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_num), "Insufficient payment.");

        _batchMint(msg.sender, _num);
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(amount == 1, 'MerkleDistributor: Claim limit exceeded.');
        require(reserveLimit.add(amount) <= maxReserveLimit, "MerkleDistributor: Not enough tokens left.");
        require(claimActive, 'MerkleDistributor: Claim closed.');
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        _setClaimed(index);
        
        reserveLimit = reserveLimit.add(amount);
        _batchMint(account, amount);

        emit Claimed(index, account, amount);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString())) : "";
    }
}
