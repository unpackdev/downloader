// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract MysticalPets is ERC721, ERC721Enumerable, ERC721Burnable, Ownable{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply = 300;
    uint256 public mintPrice = 55500000 gwei;
    uint256 public startingIndexBlock;
    bool public saleIsActive = false;
    string public provenance;
    string public _currentBaseURI;
    bool public breedingIsActive = false;
    bool public changeColorIsActive = false;
    uint256 public startingIndex;
    address private _manager;

    // Mapping from token ID to the amount of claimable eth in gwei
    mapping(uint256 => uint256) private _claimableEth;


    event PaymentReleased(address to, uint256 amount);

    event EthDeposited(uint256 amount);

    event ColorChanged(uint256 firstTokenId, uint256 secondTokenId, uint256 thirdTokenId, uint256 changedPetTokenId);

    event EthClaimed(address to, uint256 amount);
    
    
    constructor() ERC721("MysticalPets", "MYST"){
        setBaseURI("https://mysticalpets.club/api/metadata/");
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }
    function _baseURI() internal view virtual override returns(string memory) {
        return _currentBaseURI;
    }
    function setMaxTokenSupply(uint256 maxPetSupply) public onlyOwner {
        maxTokenSupply = maxPetSupply;
    }
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }
    function flipbreedingState() public onlyOwner {
        breedingIsActive = !breedingIsActive;
    }
    function changeColorState() public onlyOwner {
        changeColorIsActive = !changeColorIsActive;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }


    function mint() internal {
        uint256 tokenId = _tokenIdCounter.current() + 1;
            if (tokenId <= maxTokenSupply) {
                _safeMint(msg.sender, tokenId);
                _tokenIdCounter.increment();
            }
            if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }
    function claim() external payable {
        require(saleIsActive, "Sale must be active to mint pets");
        require(msg.value == mintPrice, "claiming a Mystical Pet costs 0.111 ether");
        mint();
        payable(owner()).transfer(mintPrice);
    }
    /*
    * Set the manager address for deposits.
    */
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }
    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    /*
    * Deposit eth for distribution to token owners.
    */
    function deposit() public payable onlyOwnerOrManager {
        uint256 tokenCount = totalSupply();
        uint256 claimableAmountPerToken = msg.value / tokenCount;

        for(uint256 i = 0; i < tokenCount; i++) {
            // Iterate over all existing tokens (that have not been burnt)
            _claimableEth[tokenByIndex(i)] += claimableAmountPerToken;
        }

        emit EthDeposited(msg.value);
    }
    /*
    * Get the claimable balance of a token ID.
    * Javascript implementation on the front end
    */
    function claimableBalanceOfTokenId(uint256 tokenId) public view returns (uint256) {
        return _claimableEth[tokenId];
    }
    /*
    * Get the total claimable balance for an owner.
    */
    function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = balanceOf(owner);

        for(uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(tokenOfOwnerByIndex(owner, i));
        }

        return balance;
    }
    function claim_owner() public {
        uint256 amount = 0;
        uint256 numTokens = balanceOf(msg.sender);

        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            amount += _claimableEth[tokenId];
            // Empty out all the claimed amount so as to protect against re-entrancy attacks.
            _claimableEth[tokenId] = 0;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        
        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function changePetColor(uint256 firstTokenId, uint256 secondTokenId, uint256 thirdTokenId) public {
        require(changeColorIsActive && !saleIsActive, "Either sale is currently active or changing color is inactive");
        require(_isApprovedOrOwner(_msgSender(), firstTokenId) && _isApprovedOrOwner(_msgSender(), secondTokenId) && _isApprovedOrOwner(_msgSender(), thirdTokenId), "Caller is not owner nor approved");
        
        // burn the 3 tokens
        _burn(firstTokenId);
        _burn(secondTokenId);
        _burn(thirdTokenId);

        // mint new token
        uint256 changedPetTokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, changedPetTokenId);
        _tokenIdCounter.increment();

        // fire event in logs
        emit ColorChanged(firstTokenId, secondTokenId, thirdTokenId, changedPetTokenId);
    }
}


