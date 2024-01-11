//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

import "./console.sol";

/*   //
*   ('>
*   /rr
*  *\))_  
*/

contract ProtocolCampNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bool public _paused = false;
    mapping(address => bool) public whitelistClaimed;

    bytes32 public _merkleRoot;
    uint256 public _quantity;

    string private _baseTokenURI;


    constructor() ERC721("Protocol Campers", "PCAMP")  {
    // constructor() ERC721("WTest v9", "TEST")  {
    }

    event NewEpicNFTMinted(address sender, uint256 tokenId);

    function mintWL(bytes32[] calldata _merkleProof, uint256 _id) public {

        require( !_paused, "Mint paused" );
        require( !whitelistClaimed[msg.sender], "Already claimed");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _id));
        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "No WL or Wrong URI");

        whitelistClaimed[msg.sender] = true;
        mintNFT(msg.sender, _id);
    }

    function mintNFT(address recipient, uint256 _id) private returns (uint256)
    {   
        require(recipient != address(0), "ERC721: mint to the zero address");
        require(!_exists(_id), "ERC721: token already minted");

        _tokenIds.increment();
        
        _mint(recipient, _id);
        // console.log("Trying to send %s tokens", _id);
        // console.log("Token uri", tokenURI(_id));

         // EMIT MAGICAL EVENTS.
        emit NewEpicNFTMinted(msg.sender, _id);

        return _id;
    }

     function mintByOwner(address to , uint256 _id) public onlyOwner {

        require( !_paused, "Mint paused" );
        
        mintNFT(to, _id);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setQuantity(uint256 quantity) external onlyOwner {
        _quantity = quantity;
    }

     function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause(bool val) external onlyOwner {
        _paused = val;
    }

    function changeOwnership(address newOwner) public onlyOwner {
        transferOwnership( newOwner);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function _total() public view returns (uint256) {
       return _tokenIds.current();
    }
   
    function _tokenURI(uint256 tokenId) public view returns (string memory) {
       return tokenURI(tokenId);
    }

}


// npx hardhat run --network ropsten scripts/deploy.ts
// npx hardhat run --network rinkeby scripts/deploy.ts