// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// import "./ERC721.sol";
// import "./ERC721Enumerable.sol";
// import "./ERC721URIStorage.sol";
// import "./ERC721Pausable.sol";
// import "./Ownable.sol";
// import "./ERC2981.sol";
// import "./MerkleProof.sol";

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
contract ERC721HaiDrop is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable,ERC2981, Ownable {
    uint256 private _nextTokenId = 1;
    mapping(string => bool) private _hashMintedTokenURIs;
    uint256 private maxMintPerWallect = 10;
    uint256 public maxTotalSupply = 333;
    bytes32 private merkleRoot = 0x72177ecb727a467533097090f9afae72bc448838972dc1efcb78b30c045329f2;
    mapping(address => uint256) private  whitelistNumber;
    mapping(address => bool) private whitelistClaimed;
    uint256 public  mintPrice  = 0.1 ether;

    constructor()
        ERC721("CorgiMarketPt", "CMP")
        Ownable(msg.sender)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        require(totalSupply() < maxTotalSupply,"hased max minted");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage,ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function isHashTokenURI(string memory tokenURI_) public view  returns (bool)
    {
        return _hashMintedTokenURIs[tokenURI_];
    }
    
    
    function mintNFT(address recipient, 
        string memory tokenURI_,
        bytes32[] calldata merkleProof) 
        public payable
        returns (uint256)
    {
        require(totalSupply() < maxTotalSupply,"hased max minted");
        if(owner() != _msgSender())
        {
            
            if(!whitelistClaimed[msg.sender])
                checkWhitelistMint(merkleProof);

            uint256 number = whitelistNumber[msg.sender];
            require(number > 0,"minted to max number ");
            require(mintPrice == msg.value, "Ether value sent is not correct");
        }
        uint256 tokenId = _nextTokenId++;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _hashMintedTokenURIs[tokenURI_] = true;
        if(owner() != _msgSender())
        {
            uint256 number = whitelistNumber[msg.sender];
            if(number > 0)
                number--;
             whitelistNumber[msg.sender]  = number; 
        }
        return tokenId;
    }

   

    function withdraw() onlyOwner public {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
    }   

    function contractURI() public pure returns (string memory) {
       return "https://ipfs.io/ipfs/bafkreic7us6iexpwd6z6gxuhg2icdcbi7c2ovvhlperuusgqutunfeq6rm";
    }

    function checkWhitelistMint(bytes32[] calldata merkleProof) public returns (bool ok ){
        if(whitelistNumber[msg.sender] <= 0)
        {
            if(whitelistClaimed[msg.sender])
               return false;
            require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(msg.sender)),"Invalid proof");
            whitelistClaimed[msg.sender] = true;
            whitelistNumber[msg.sender] = maxMintPerWallect;
        }
        ok = true;
        return ok;
    }

    function canMintNumber() public view  returns (uint256)
    {
        return whitelistNumber[msg.sender];
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function setMerkleRoot(bytes32 newMerkleRoot)
     onlyOwner 
     public  returns(bool )
    {
        merkleRoot  = newMerkleRoot;
        return true;
    }

    function setMerkleRoot2(bytes32 newMerkleRoot,uint256 maxMintPerWallect_)
     onlyOwner 
     public  returns(bool )
    {
        merkleRoot  = newMerkleRoot;
        maxMintPerWallect = maxMintPerWallect_;
        return true;
    }
    function setMerkleRoot3(bytes32 newMerkleRoot,uint256 maxMintPerWallect_,uint256 mintPrice_)
     onlyOwner 
     public  returns(bool )
    {
        merkleRoot  = newMerkleRoot;
        maxMintPerWallect = maxMintPerWallect_;
        mintPrice = mintPrice_;
        return true;
    }
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner() {
        maxTotalSupply = _maxTotalSupply;
    }
}