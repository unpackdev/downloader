// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract senshiNFT is ERC721A, Ownable, Pausable  {

    string public _name = "SENSHI NFT";
    string public _symbol = "SENSHI";
    string private _baseURIExtended;
    uint256 immutable public _maxSupply = 10000;
    uint256 public _mintingPrice;
    uint256 public _mintingLimit;
    bool public _openForWhitelisted;
    bytes32 public _merkleRoot;
    
    constructor () ERC721A(_name, _symbol) {}

    function mint(uint256 nftAmount, bytes32[] calldata _merkleProof) external whenNotPaused payable {
        require(_totalMinted() + nftAmount <= _mintingLimit , "Max limit reached");
        require(msg.value == _mintingPrice * nftAmount, "Invalid price");

        if(_openForWhitelisted) {
            require(verifyMerkleProof(_merkleProof, _merkleRoot), " Not Whitelisted");
        }
        _safeMint(msg.sender , nftAmount);
    }

    function withdrawEth(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function toggleWhitelistingStatus() external onlyOwner {
        _openForWhitelisted = !_openForWhitelisted;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length > 0, "Cannot be null");
        _baseURIExtended = baseURI_;
    }

    function currentSupply() public view returns(uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    function updatePriceAndSupply(uint256 newPrice, uint updatedSupply) external onlyOwner {
        require(_totalMinted() + updatedSupply <= _maxSupply, "Max supply reach");
        _mintingPrice = newPrice;
        _mintingLimit += updatedSupply;
    }

    function pause() public whenNotPaused onlyOwner{
        _pause();
    }

    function unpause() public whenPaused onlyOwner{
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkle) public onlyOwner {
        _merkleRoot = _merkle;
    }

    function verifyMerkleProof(bytes32[] memory proof, bytes32 root)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
}
