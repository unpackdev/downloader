// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./MerkleProof.sol";

contract WeThem is ERC721, ERC721Burnable, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot = "";
    mapping(address => bool) public whitelistMinted;

    uint public maxItems = 402;
    uint public totalSupply = 0;
    string public baseURI;
    bool public isStarted;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor(bytes32 _merkleRoot) ERC721("We Them: Sacred Society", "SACRED-REBEL") {
        merkleRoot = _merkleRoot;
    }

    modifier mintingOpen() {
        require(isStarted, "We Them: Sale isn't started yet");
        _;
    }

    function ownerMint() external onlyOwner mintingOpen {
        _mintWithoutValidation(msg.sender);
    }

    function mintSale(bytes32 leaf, bytes32[] memory proof) external mintingOpen {
        require(!whitelistMinted[msg.sender], "We Them: You minted already");
        require(keccak256(abi.encodePacked(msg.sender)) == leaf, "We Them: Sender doesn't match with data");
        require(verify(merkleRoot, leaf, proof), "We Them: Not whitelisted address");

        _mintWithoutValidation(msg.sender);
    }

    function isSoldOut() public view returns (bool) {
        return totalSupply >= maxItems;
    }

    function _mintWithoutValidation(address to) internal {
        uint newTotalSupply = totalSupply.add(1);
        require(newTotalSupply <= maxItems, "We Them: Sold out");

        whitelistMinted[msg.sender] = true;
        _safeMint(to, newTotalSupply);
        totalSupply = newTotalSupply;
        emit Mint(to, newTotalSupply);
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setMaxItems(uint _maxItems) external onlyOwner {
        maxItems = _maxItems;
    }

    function setSaleState(bool _isStarted) external onlyOwner {
        isStarted = _isStarted;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function burn(uint256 tokenId) public override onlyOwner {
        _burn(tokenId);
    }

}