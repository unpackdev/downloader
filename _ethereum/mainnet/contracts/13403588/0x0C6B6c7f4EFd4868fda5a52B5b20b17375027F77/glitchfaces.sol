// contracts/glitchfaces.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// Inspired by BAKC

abstract contract Blockfaces {
  function walletOfOwner(address _owner) public virtual view returns(uint256[] memory);
}

contract glitchfaces is ERC721, Ownable {
    
    Blockfaces private blockface;
    using SafeMath for uint256;
    bool public hasSaleStarted;
    
    // The IPFS hash
    string public METADATA_PROVENANCE_HASH = "";

    // Truth?　
    string public constant R = "glitchfaces - glitch with me";

    constructor(string memory baseURI) ERC721("glitchfaces","GFACES")  {
        setBaseURI(baseURI);   
        blockface = Blockfaces(0x8Ab89E0191F71903F97709d4b4653922D62e6Bfb);
        
    }
    
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function glitchmyface() public {
        uint256[] memory blockfaceids;
        blockfaceids = blockface.walletOfOwner(msg.sender);
        uint256 balance = blockfaceids.length;
        bool facetoglitch;
        require(hasSaleStarted,                         "sale is paused");
        require(balance > 0,                            "need at least 1 blockface");
    
    // check if any ids are available to glitch    
        for(uint256 j; j < balance; j++){
            uint256 checktokenid = blockfaceids[j];
            if(!_exists(checktokenid)){
                facetoglitch = true;
                break;
            }
        }
    // mint any ids that don't exist    
        for(uint256 i; i < balance; i++){
            uint256 tokenid = blockfaceids[i];
            require(facetoglitch == true,                "all your faces are glitched");
            if (!_exists(tokenid)){
                _safeMint(msg.sender, tokenid);
            }
        }
    }
    
    // God Mode
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}