// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GoddessesOfSun is ERC721, Ownable{
    using Strings for uint256;

    uint256 public constant totalSupply = 999;
    uint256 public minted = 0;
    uint256 public tokensLeft = totalSupply;
    uint256 public mintLimit = 10;
    uint256 public mintPrice = 0.1 ether;
    address payable communityWallet = payable(0x2D19380b4fFc48A04191d046686811b5A04CfE50);
   
    string public _name = "Goddesses Of Sun";
    string public _symbol = "GOS";

    string public unrevealedURI;
    string public revealedURI;

    //0x99841f5d6a45ddaca75f2d550add3a68ac124d3a6e46486dc4c3ec1f16b3a354
    bytes32 public rootHash;

    bool public revealed = false;

    bool public preSale = false;
    bool public publicSale = false;

  
    constructor() ERC721(
        _name,
        _symbol
        ){}

    //MINT
    function mintToken(uint256 quantity, bytes32[] memory proof) public payable  {
        if(!preSale && !publicSale){
            revert("Sale has not been started yet.");
        }
        if(preSale == true){
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, rootHash, leaf), "User not whitelisted for private sale");
        } 

        require(minted + quantity <= totalSupply,"Invalid quantity.");
        require(balanceOf(msg.sender) + quantity <= mintLimit, "You cannot mint more than the mintLimit.");
        require( msg.value >= mintPrice * quantity, "Invalid Price To Mint");
        (bool success,) = communityWallet.call{value: msg.value}("");
        if(!success) {
            revert("Payment Sending Failed");
        }

        while(quantity > 0){
                minted++;
                _safeMint(msg.sender, minted);
                quantity--;
                tokensLeft --;
            } 
    }

    function airdropTokens(address[] memory receivers) external onlyOwner {
        
        require(minted + receivers.length <= totalSupply,"Invalid number of addresses passed.");

        for(uint i = 0; i < receivers.length; i++){
            if(receivers[i] != address(0) && receivers[i]!= 0x000000000000000000000000000000000000dEaD){
            minted++;
            _safeMint(receivers[i], minted);
           
            tokensLeft --;    
            }
        }
    }

    function setSaleStatus() external onlyOwner{
        preSale = !preSale;
        publicSale = !preSale;
    }

    //ROOT HASH
    function setRootHash(bytes32 _rootHash) external onlyOwner{
        require(_rootHash.length > 0, "Invalid Root hash");
        rootHash = _rootHash;
    }

    //MINT LIMIT
    function setMintLimit(uint256 _mintLimit) external  onlyOwner{
        require(_mintLimit > 0 && _mintLimit <= totalSupply, "Invalid mint limit." );
        mintLimit = _mintLimit;
    }

    //MINT PRICE
    function setMintPrice(uint256 _mintPrice) external onlyOwner{
        require(_mintPrice > 0, "mint price can't be zero" );
        mintPrice = _mintPrice;
    }

    //UNREVEALED URI
    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner{
        require(bytes(_unrevealedURI).length > 0, "Invalid Unrevealed URI" );
        unrevealedURI = _unrevealedURI;
    }

    //REVEALED URI 
    function setRevealedURI(string memory _revealedURI) external onlyOwner{
        require(bytes(_revealedURI).length > 0, "Invalid Revealed URI" );
        revealedURI = _revealedURI;
    }
    
    //REVEALED STATUS
    function setRevealedStatus() public onlyOwner{
        revealed = !revealed;
    }

    function setCommunityWallet(address payable _communityWallet) external onlyOwner{
        require(_communityWallet != address(0) &&
        _communityWallet != 0x000000000000000000000000000000000000dEaD, "address can't be set to address(0) or deadAddress");
        communityWallet = _communityWallet;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= totalSupply, "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false){
            return bytes(unrevealedURI).length > 0 ? string(abi.encodePacked(unrevealedURI)) : "";
        }
        else{
            return bytes(revealedURI).length > 0 ? string(abi.encodePacked(revealedURI, tokenId.toString(),".json")) : "";
        } 
    }

 

}