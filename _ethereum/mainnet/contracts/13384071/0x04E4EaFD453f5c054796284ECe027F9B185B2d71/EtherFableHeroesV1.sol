// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";

contract EtherFableHeroesV1 is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;

    uint256 public tokenIdCounter = 0;
    string public currentBaseUri = "https://etherfable.com/api/v1/heroes/";
    uint256 public currentPrice = 20000000000000000;
    bool public saleActive = true;
    
    event BaseUriUpdated(string _newBaseURI);
    event PriceUpdated(uint256);
    event SaleActivated();
    event SaleDeactivated();
    
    constructor() ERC721("EtherFableHeroesV1", "EFHERO") {}
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return currentBaseUri;
    }
    
    function updateBaseURI(string memory newBaseUri) public onlyOwner {
        currentBaseUri = newBaseUri;
        emit BaseUriUpdated(currentBaseUri);
    }
    
    function updatePrice(uint256 newPrice) public onlyOwner {
        currentPrice = newPrice;
        emit PriceUpdated(currentPrice);
    }
    
    function setSaleActive() public onlyOwner {
        require(!saleActive, "Sale is already active.");
        saleActive = true;
        emit SaleActivated();
    }
    
    function setSaleInactive() public onlyOwner {
        require(saleActive, "Sale is already inactive.");
        saleActive = false;
        emit SaleDeactivated();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function ownerMint(address to, uint256 quantity) public onlyOwner {
        for(uint i = 0; i < quantity; i++) {
            _safeMint(to, tokenIdCounter);
            tokenIdCounter += 1;
        }
    }
    
    function mint(uint256 quantity) public payable {
        require(saleActive, "Sale is not active.");
        require(msg.value >= currentPrice.mul(quantity), "Ether value sent is not correct.");

        for(uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenIdCounter);
            tokenIdCounter += 1;
        }
    }
    
    function tokensOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner);
        if (ownerTokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](ownerTokenCount);
            uint256 index;
            for (index = 0; index < ownerTokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    struct AddressRecipientCount {
        address recipient;
        uint256 count;
    }
    
    uint256 public airdropIdCounterForAddresses = 0;
    
    struct AddressAirdrop {
        uint256 counter;
        uint256 limit;
        uint256 price;
        mapping(address => uint256) recipients;
        bool active;
    }
    
    mapping(uint256 => AddressAirdrop) public airdropIdForAddressToAddressAirdrop;
    
    event AirdropForAddressesCreated(uint256 addressAirdropId, uint256 counter, uint256 limit, uint256 price);
    event AirdropForAddressesCoreUpdated(uint256 addressAirdropId, uint256 price, bool active);

    
    function createAirdropForAddresses(uint256 airdropCount, uint256 airdropPrice) public onlyOwner {
        uint256 counter = tokenIdCounter;
        tokenIdCounter += airdropCount;
        uint256 limit = tokenIdCounter;
        
        AddressAirdrop storage addressAirdrop = airdropIdForAddressToAddressAirdrop[airdropIdCounterForAddresses];
        addressAirdrop.counter = counter;
        addressAirdrop.limit = limit;
        addressAirdrop.price = airdropPrice;
        addressAirdrop.active = true;
        
        emit AirdropForAddressesCreated(airdropIdCounterForAddresses, counter, limit, airdropPrice);
        
        airdropIdCounterForAddresses += 1;
    }
    
    function updateAirdropForAddressesCore(uint256 addressAirdropId, uint256 airdropPrice, bool airdropActive) public onlyOwner {
        require(airdropIdForAddressToAddressAirdrop[addressAirdropId].active, "Address airdrop with that ID doesn't exist.");
        airdropIdForAddressToAddressAirdrop[addressAirdropId].price = airdropPrice;
        airdropIdForAddressToAddressAirdrop[addressAirdropId].active = airdropActive;
        emit AirdropForAddressesCoreUpdated(addressAirdropId, airdropPrice, airdropActive);
    }
  
    function updateRecipientsForAddressesAirdrop(uint256 addressAirdropId, AddressRecipientCount[] memory recipients) public onlyOwner {
        require(airdropIdForAddressToAddressAirdrop[addressAirdropId].active, "Address airdrop with that ID doesn't exist.");
        for(uint i = 0; i < recipients.length; i++) {
            airdropIdForAddressToAddressAirdrop[addressAirdropId].recipients[recipients[i].recipient] = recipients[i].count;
        }
    }

    function claimAirdropWithAddress(uint256 addressAirdropId, uint256 quantity) public payable {
        require(getAirdropQuantityWithAddress(addressAirdropId, msg.sender) > 0, "No registered airdrops with that address.");
        require(airdropIdForAddressToAddressAirdrop[addressAirdropId].active, "Airdrop not active.");
        require(quantity > 0, "Address airdrop quantity must be greater than 0.");
        require(msg.value >= airdropIdForAddressToAddressAirdrop[addressAirdropId].price.mul(quantity), "Ether value sent is not correct.");
        require(quantity <= airdropIdForAddressToAddressAirdrop[addressAirdropId].recipients[msg.sender], "Requested quantity exceeds supply for address.");
        require(airdropIdForAddressToAddressAirdrop[addressAirdropId].counter.add(quantity) <= airdropIdForAddressToAddressAirdrop[addressAirdropId].limit, "Quantity would exceed total allocated airdrop supply.");
        
        for(uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, airdropIdForAddressToAddressAirdrop[addressAirdropId].counter);
            airdropIdForAddressToAddressAirdrop[addressAirdropId].recipients[msg.sender] = airdropIdForAddressToAddressAirdrop[addressAirdropId].recipients[msg.sender] -= 1;
            airdropIdForAddressToAddressAirdrop[addressAirdropId].counter += 1;
        }
    }
    
    function getAirdropQuantityWithAddress(uint256 addressAirdropId, address recipient) public view returns(uint quantity) {
        require(airdropIdForAddressToAddressAirdrop[addressAirdropId].active, "Address airdrop with that ID doesn't exist.");
        return airdropIdForAddressToAddressAirdrop[addressAirdropId].recipients[recipient];
    }
    
    struct TokenIdCount {
        uint256 id;
        uint256 count;
    }
    
    uint256 public airdropIdCounterForTokenIds = 0;
    
    struct TokenIdAirdrop {
        uint256 counter;
        uint256 limit;
        uint256 price;
        mapping(uint256 => uint256) recipients;
        bool active;
    }
    
    mapping(uint256 => TokenIdAirdrop) public airdropIdForTokenIdsToTokenIdAirdrop;
    
    event AirdropForTokenIdsCreated(uint256 tokenAirdropId, uint256 counter, uint256 limit, uint256 price);
    event AirdropForTokenIdsCoreUpdated(uint256 tokenAirdropId, uint256 price, bool active);
    
    function createAirdropForTokenIds(uint256 airdropCount, uint256 airdropPrice) public onlyOwner {
        uint256 counter = tokenIdCounter;
        tokenIdCounter += airdropCount;
        uint256 limit = tokenIdCounter;
        
        TokenIdAirdrop storage tokenIdAirdrop = airdropIdForTokenIdsToTokenIdAirdrop[airdropIdCounterForTokenIds];
        tokenIdAirdrop.counter = counter;
        tokenIdAirdrop.limit = limit;
        tokenIdAirdrop.price = airdropPrice;
        tokenIdAirdrop.active = true;
        
        emit AirdropForTokenIdsCreated(airdropIdCounterForTokenIds, counter, limit, airdropPrice);
        
        airdropIdCounterForTokenIds += 1;
    }
    
    function updateAirdropForTokenIdsCore(uint256 tokenAirdropId, uint256 airdropPrice, bool airdropActive) public onlyOwner {
        require(airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].active, "Token airdrop with that ID doesn't exist.");
        airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].price = airdropPrice;
        airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].active = airdropActive;
        emit AirdropForTokenIdsCoreUpdated(tokenAirdropId, airdropPrice, airdropActive);
    }
    
    function updateRecipientsForTokenIdsAirdrop(uint256 tokenAirdropId, TokenIdCount[] memory recipients) public onlyOwner {
        require(airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].active, "Token airdrop with that ID doesn't exist.");
        for(uint i = 0; i < recipients.length; i++) {
            airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].recipients[recipients[i].id] = recipients[i].count;
        }
    }
    
    function claimAirdropWithTokenId(uint256 tokenAirdropId, uint256 tokenId, uint256 quantity) public payable {
        require(getAirdropQuantityWithTokenId(tokenAirdropId, tokenId) > 0, "No registered airdrops with that token ID.");
        require(airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].active, "Airdrop not active.");
        require(quantity > 0, "Address airdrop quantity must be greater than 0.");
        require(ownerOf(tokenId) == msg.sender, "Message sender is not the owner of token ID.");
        require(msg.value >= airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].price.mul(quantity), "Ether value sent is not correct.");
        require(quantity <= airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].recipients[tokenId], "Requested quantity exceeds supply for that token ID.");
        require(airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].counter.add(quantity) <= airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].limit, "Quantity would exceed total allocated airdrop supply.");
        
        for(uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].counter);
            airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].recipients[tokenId] = airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].recipients[tokenId] -= 1;
            airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].counter += 1;
        }
    }
    
    function getAirdropQuantityWithTokenId(uint256 tokenAirdropId, uint256 tokenId) public view returns(uint quantity) {
        require(airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].active, "Token airdrop with that ID doesn't exist.");
        return airdropIdForTokenIdsToTokenIdAirdrop[tokenAirdropId].recipients[tokenId];
    }
}










