// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
contract RavensHollow is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Pausable, ReentrancyGuard, Ownable, RoyaltiesV2Impl {

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string baseURI;
    string public baseExtension = ".json";

    uint256 private _cost = 0.1 ether;
    uint256 private _costFirst500 = 0.07 ether;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 15;

    address payable royaltiesRecipientAddress;
    uint96 private percentageBasisPoints;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    // In case Eth goes crazy
    function setCost(uint256 _newCost) public onlyOwner() {
        _cost = _newCost;
    }

    function getCost() public view returns (uint256) {
        return _cost;
    }

    // In case Eth goes crazy
    function setCostFirst500(uint256 _newCostFirst500) public onlyOwner() {
        _costFirst500 = _newCostFirst500;
    }

    function getCostFirst500() public view returns (uint256) {
        return _costFirst500;
    }

    function setRoyaltyPercentage(uint96 _initRoyaltiesPercentage) public onlyOwner() {
        setRoyaltyPercentageBasisPoints(_initRoyaltiesPercentage*100);
    }

    constructor(string memory _initBaseURI, uint96 _initRoyaltiesPercentage) ERC721("Raven's Hollow", "RVH") {
        setBaseURI(_initBaseURI);
        setRoyaltyPercentageBasisPoints(_initRoyaltiesPercentage*100);
        setRoyaltyRecipientAddress(payable(owner()));
        _tokenIdCounter.increment();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to, uint256 numberOfTokens) public whenNotPaused payable nonReentrant {
        uint256 current = _tokenIdCounter.current();
        require(totalSupply() + numberOfTokens <= maxSupply,            "Exceeds maximum supply");

        if (msg.sender != owner()) {
            require(balanceOf(to) + numberOfTokens  <= maxMintAmount,   "You can't mint that many");
            if(current < 600 ) {
                require(msg.value >= _costFirst500 * numberOfTokens ,    "Not enough ETH sent");
            } else {
                require(msg.value >= _cost * numberOfTokens ,            "Not enough ETH sent");
            }
        }        
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if(tokenId < maxSupply) {
                _safeMint(to, tokenId);                
                _setTokenURI(tokenId, tokenURI(tokenId));
                setRoyalties(tokenId, royaltiesRecipientAddress, percentageBasisPoints);
                _tokenIdCounter.increment();
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal        
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721 ,ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function withdraw() public onlyOwner {
            address _owner = owner();
            uint256 amount = address(this).balance;
            (bool sent, ) = _owner.call{value: amount}("");
            require(sent, "Failed to send Ether");
    }            
    
    function setRoyaltyPercentageBasisPoints(uint96 _percentageBasisPoints) internal {
        percentageBasisPoints = _percentageBasisPoints;
    }

    function setRoyaltyRecipientAddress(address payable _royaltiesRecipientAddress) public onlyOwner {
        royaltiesRecipientAddress = _royaltiesRecipientAddress;
    }

    function setTokenRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner() {
        _updateRoyalties(_tokenId, _royaltiesRecipientAddress, _percentageBasisPoints);
    }

    //configure royalties for Rariable etc
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    function supportsInterface(bytes4 interfaceId) 
        public
        view 
        virtual 
        override(ERC721, ERC721Enumerable) 
        returns (bool) 
    {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if(interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }

        return super.supportsInterface(interfaceId);
    }    
}