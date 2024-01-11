// SPDX-License-Identifier: MIT

/*
//DaBunny Island's genesis collection features 9,999 bunny island hopp3rs - each uniquely bubbly and carries its own sense of humor.

// @twitter:  https://twitter.com/dabunnyisland
*/

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./ERC721B.sol";

contract Dabunny is Ownable, ERC721B, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public immutable adoptionLimit = 10;
    mapping(uint256=> string) private _tokenURIs;
    bool public saleOpen = false;
    string private baseURI = "https://api.dabunnyisland.com/ipfs/QmTswoM3FxkPygeTQSKeT464Vg8TgmrXFsvBNvWiTnS2EV/";
    bool private isRevealed = false;
    uint256 public price = 0.12 * 10 ** 18;
    uint256 public currentSupply = 100;
    uint256 public maxBatchSize = 10;
    bytes32 public whitelistedUsersMerkleRoot;


    constructor(
        string memory name, 
        string memory symbol)
        ERC721B(name, symbol) {
    }

    function mintNFT(uint256 _quantity, bytes32[] memory _proof) public payable {
        require(totalSupply() + _quantity < currentSupply, "Reaching max supply");

        if (_msgSender() != owner()) {
            require(msg.value >= price * _quantity, "Needs to send more eth");
            require(getMintedCountByOwner(msg.sender) + _quantity <= adoptionLimit, "Exceed max adoption amount");
            if(!isWhitelisted(msg.sender, _proof)){
                require(saleOpen, "Sorry!! can't mint when sale is closed.");
            }
        }
        _safeMint(msg.sender, _quantity);
    }
    
    function isWhitelisted(address _account, bytes32[] memory _proof) public view returns (bool){
        bytes32 node = keccak256(abi.encodePacked(_account));
        if(_proof.verify(whitelistedUsersMerkleRoot, node))
            return true;
        else 
            return false;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
            return string(abi.encodePacked(baseURI, _tokenId.toString(), '.json'));

    }


    function setWhitelistUserMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistedUsersMerkleRoot = _merkleRoot;
    }

    function revealToken(bool reveal) onlyOwner public {
        isRevealed = reveal;
    } 

    function updateBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _price) public onlyOwner() {
        price = _price * 10 ** 18;
    }

    function setCurrentSupply(uint256 _supply) public onlyOwner() {
        require(_supply > currentSupply, 'Provide a valid supply i.e. greater than current supply and less than/equal to max supply.');
        currentSupply = _supply;
    }

    function toggleSale() public onlyOwner() {
        saleOpen = !saleOpen;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getMintedCountByOwner(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner nonReentrant{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getMaxSupply() public view returns (uint256){
        return currentSupply;
    }

    function getMaxBatchSize() public view returns (uint256){
        return maxBatchSize;
    }

    receive() external payable {}

}
