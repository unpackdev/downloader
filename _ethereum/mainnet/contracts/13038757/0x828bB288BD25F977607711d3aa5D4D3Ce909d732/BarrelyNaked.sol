//SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract BarrelyNaked is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    // metadata API endpoint  
    string private _metadataAPI;
    
    // Maximum token supply
    uint256 private _MAX_SUPPLY;

    // Date when token starts being available for minting
    uint256 private _saleStartUTS;

    // Tracks number of free minted tokens
    uint256 private _counterFreeMintedTokens;

    // Sets maximum possible purchases per transaction
    uint256 private _maxPurchaseCount = 20;
        
    // Mapping addresses that used their free mint
    mapping(address => bool) private _addressesUsedFreeMint;

    constructor(
        uint256 maxTokenSupply_,
        uint256 initSaleStartUTS_,
        string memory tokenName_,
        string memory tokenSymbol_,
        string memory initMetadataAPI_
    ) ERC721(tokenName_, tokenSymbol_) {

        _MAX_SUPPLY = maxTokenSupply_;
        _metadataAPI = initMetadataAPI_;
        _saleStartUTS = initSaleStartUTS_;

    }

    modifier checkSupplyAvailable(uint256 numberOfTokens_) {
        
        require(totalSupply().add(numberOfTokens_) <= _MAX_SUPPLY, "Exceeds max supply");
        _;

    }


    function withdraw() public onlyOwner {

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

    }
    function setSaleStart(uint256 saleStart_) public onlyOwner {

        _saleStartUTS = saleStart_;

    }

    function setMaxPurchaseCount(uint256 count_) public onlyOwner {

        _maxPurchaseCount = count_;

    }

     function setMetadataAPI(string memory newMetadataAPI_) public onlyOwner {

        _metadataAPI = newMetadataAPI_;

    }
    
    function hasSaleStarted() public view returns(bool) {

        return _saleStartUTS <= block.timestamp;

    }

    function getCurrentMintPrice() public view returns (uint256) {

        return getTokenMintPrice(totalSupply());

    }

    function hasClaimedFreeToken() public view returns(bool) {

        return _addressesUsedFreeMint[msg.sender];

    }

    function getTokenMintPrice(uint256 token_) public pure returns (uint256) {

        if (token_ >= 4000) {

            return 0.05 ether;

        } 
        
        if (token_ >= 3000) {
            
            return 0.04 ether;

        }
        
        if (token_ >= 2000) {

            return 0.03 ether;

        } 
        
        if (token_ >= 1000) {

            return 0.02 ether;

        }
        
        return  0.01 ether;

    }
    
    function getMintPriceForNextTokens(uint256 numberOfTokens_) public view returns (uint256) {

        uint256 requiredMintValue;

        for (uint256 index = 0; index < numberOfTokens_; index++) {
            
            uint256 tokenIndex  = totalSupply().add(index);
            requiredMintValue = requiredMintValue.add(getTokenMintPrice(tokenIndex));
        }

        return requiredMintValue;

    }    
   
    function _mintTokens(uint256 numberOfTokens_) internal {
        
        for (uint256 index = 0; index < numberOfTokens_; index++) {
            _safeMint(msg.sender, totalSupply());
        }

    }

    function claimFreeToken() public checkSupplyAvailable(1)  {
        
        require(hasSaleStarted(), "Sale hasn't started");
        require(!hasClaimedFreeToken(), "Free token claimed");
        require(_counterFreeMintedTokens < 1000, "All free tokens were claimed");
    
        _addressesUsedFreeMint[msg.sender] = true;
        _counterFreeMintedTokens = _counterFreeMintedTokens.add(1);

        _mintTokens(1);

    }

    function mintTokens(uint256 numberOfTokens_) public payable checkSupplyAvailable(numberOfTokens_) {
        
        require(hasSaleStarted(), "Sale hasn't started");
        require(numberOfTokens_ <= _maxPurchaseCount, "Exceeds minting limit");

        uint256 requiredMintPrice;
        uint256 currentMintPrice = getCurrentMintPrice();
        uint256 newTotalSupply = totalSupply().add(numberOfTokens_); 
        uint256 newMintPrice = getTokenMintPrice(newTotalSupply);
        
        if( newMintPrice == currentMintPrice ){

            requiredMintPrice = currentMintPrice.mul(numberOfTokens_);

        }  else {

            requiredMintPrice = getMintPriceForNextTokens(numberOfTokens_);
        }

        require( requiredMintPrice == msg.value,  "Invalid ether value");

        _mintTokens(numberOfTokens_);

        
    }

    function MAX_SUPPLY() public view returns (uint256) {
        return _MAX_SUPPLY;
    }

    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function _baseURI() internal view override returns(string memory) {
        return _metadataAPI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}