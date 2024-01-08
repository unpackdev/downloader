// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract FortuneTigers is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public maxSupply    = 10000;    // 10000 Fortune Tiger NFTs
    uint256 public maxOwnerMint = 50;       // 50 tokens allowed to mint freely by owner
    uint256 public maxMintPerTX = 20;       // 20 tokens allowed to mint in a transaction
    uint256 public price        = 5e16;     // 0.05 ETH price per token

    uint256 public amountOwnerMinted;
    bool    public isSaleActive;
    bool    public isRevealed;

    string  public notRevealedURI;
    string  public baseURI;


    constructor(string memory _name, string memory _symbol, string memory _notRevealedURI) ERC721(_name, _symbol) {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setSaleState(bool _active) external onlyOwner {
        isSaleActive = _active;
    }

    /* 
        ##################################################
        ################## Interactions ##################
        ##################################################
    */

    function mint(uint256 _amount) payable external {
        bool sentFromOwner = msg.sender == owner();
        uint256 supply = totalSupply();

        require(isSaleActive || sentFromOwner, "FTIG: sale inactive");
        require((msg.value == _amount * price) || sentFromOwner, "FTIG: wrong price supplied");
        require(_amount > 0 && (_amount <= maxMintPerTX || sentFromOwner), "FTIG: invalid token amount");
        require(supply + _amount <= maxSupply, "FTIG: over max supply");

        if (sentFromOwner) {
            amountOwnerMinted += _amount;
            require(amountOwnerMinted <= maxOwnerMint, "FTIG: over owner mint limit");
        }

        uint256 newTokenId = supply + 1;
        for(uint256 i = 0; i < _amount; i++){
            _mint(msg.sender, newTokenId++);
        }
    }

    function withdraw() external {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "FTIG: transfer failed");
    }

    function reveal(bool _newRevealState, string memory _newBaseURI) external onlyOwner {
        isRevealed = _newRevealState;
        baseURI = _newBaseURI;
    }


    /* 
        ####################################################
        ################## View functions ##################
        ####################################################
    */

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!isRevealed) {
            return notRevealedURI;
        }

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString(), ".json")) : "";
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }
}