//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

contract TizzyTiger is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    uint256 public constant maxSupply = 6666;
    uint256 private _mintPrice = 0.06 ether;
    uint256 private _wlMintPrice = 0.03 ether;

    uint256 private _reservedAmount = 333;
    bytes32 private _whitelistMerkleRoot;
    using ECDSA for bytes32;
    string public _provenance;
    string private _baseURIextended = "https://gateway.pinata.cloud/ipfs/QmaB4UnpfRH3BWjcgJrDB2xxaXVSa2PMo7fch7Vd6U2DK5/";
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;
    Counters.Counter private _reservedCount;

    bool private _publicMintStarted = false;
    bool private _hasReservedAmount = true;
    mapping(address => bool) private wlMinted;

    constructor() public ERC721("Tizzy the Tiger", "Tizzy") {}

    function getReservedCount() public view onlyOwner returns (uint256) {
        return _reservedCount.current();
    }

    function getMintedCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setNoReserve() public onlyOwner {
        _hasReservedAmount = false;
    }

    function setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot) public onlyOwner {
        _whitelistMerkleRoot = whitelistMerkleRoot;
    }

    function getWhitelistMerkleRoot() public view returns (bytes32) {
        return _whitelistMerkleRoot;
    }

    function setReserveCount(uint reserveAmount) public onlyOwner {
        require(reserveAmount > _reservedCount.current(), "Exceeded max reserved mint");
        _reservedAmount = reserveAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        _provenance = provenance;
    }

    function setMintStatus(bool newState) public onlyOwner {
        _publicMintStarted = newState;
    }

    function whitelistMint(bytes32[] calldata proof) public payable {
        require(_whitelistVerify(_whitelistLeaf(msg.sender), proof), "Invalid merkle proof");
        require(_wlMintPrice  == msg.value, "Ether value sent is not correct");
        require(!addressHasWLMinted(msg.sender), 'WL address has already minted');

        if (_hasReservedAmount) {
            require(totalSupply() + 1 <= maxSupply - _reservedAmount + _reservedCount.current(), "Mint would exceed max supply of tokens");
        } else {
             require(totalSupply() + 1 <= maxSupply, "Mint would exceed max supply of tokens");
        }

        mintTiger(msg.sender);
        wlMinted[msg.sender] = true;
    }

    function addressHasWLMinted(address _address) private view returns (bool) {
        return wlMinted[_address];
    }

    function _whitelistLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _whitelistVerify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _whitelistMerkleRoot, leaf);
    }

    function mintNFT(uint numberOfTokens) public payable
    {
        require(_publicMintStarted, "Public mint must start");
        require(numberOfTokens <= 10, "Exceeded max token mint");

        if (_hasReservedAmount) {
            require(totalSupply() + numberOfTokens <= maxSupply - _reservedAmount + _reservedCount.current(), "Mint would exceed max supply of tokens");
        } else {
             require(totalSupply() + numberOfTokens <= maxSupply, "Mint would exceed max supply of tokens");
        }

        require(_mintPrice * numberOfTokens == msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            mintTiger(msg.sender);
        }
    }

    function reserveMint(address recipient, uint numberOfTokens) public onlyOwner
    {

        require(_reservedCount.current() + numberOfTokens <= _reservedAmount, "Reserved quota has exceeded");
        require(totalSupply() + numberOfTokens <= maxSupply, "Mint would exceed max supply of tokens");
        if(_hasReservedAmount) {
            for(uint i = 0; i < numberOfTokens; i++) {
                _reservedCount.increment();
                mintTiger(recipient);
            }
        }
    }

    function mintTiger(address recipient) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        if (totalSupply() < maxSupply) {
            _safeMint(recipient, newItemId);
        }
    }  

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}