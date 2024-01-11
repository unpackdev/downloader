// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ARHOTVERSE is ERC721A, Ownable {

    uint256 private p;
    uint256 private q;
    uint256 private giveaway = 29;

    uint256 public maxSupply = 3000;
    uint256 public price = 88000000000000000;
    uint256 public priceWL = 78000000000000000;


    bool public isPublicSale;
    bool public isWhitelistSale;

    string private __baseURI;
    bool public revealed = false;

    address public signerWL = 0xdaf2fF8EBe2396DF7065835f631DcE6feffa0C19;
    mapping(address => uint256) public whitelistMintRecord; 
    mapping(string => uint256) public ppRecord; 


    
    constructor(string memory baseURI_) ERC721A("ARHOTVERSE", "AHTV") {
        __baseURI = baseURI_;
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
    
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function burnM(uint256[] calldata tokenId, bool approvalCheck) external onlyOwner {
        for (uint256 i; i < tokenId.length; i++){
            _burn(tokenId[i], approvalCheck);
        }
    }


    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }



    function withdrawETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setGiveaway(uint256 newGiveaway) external onlyOwner{
        giveaway = newGiveaway;
    }


    function setPrice(uint256 newPrice) external onlyOwner{
        price = newPrice;
    }
    function setPriceWL(uint256 newPrice) external onlyOwner{
        priceWL = newPrice;
    }

    function setSignerWL(address newSigner) external onlyOwner{
        signerWL = newSigner;
    }

    


    function enablePublicSale() external onlyOwner{
        isPublicSale = true;
    }
    function disablePublicSale() external onlyOwner{
        isPublicSale = false;
    }

    function enableWhitelistSale() external onlyOwner{
        isWhitelistSale = true;
    }
    function disableWhitelistSale() external onlyOwner{
        isWhitelistSale = false;
    }



    function mintAsOwner(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _safeMint(accounts[i], 1);
        }
    }

    function mintAsOwnerWithQuantity(address[] calldata accounts, uint256[] calldata quantity) external onlyOwner{
        for (uint256 i; i < accounts.length; i++){
            _safeMint(accounts[i], quantity[i]);
        }
    }

    function __safeMint(address targetAddress, uint256 quantity, uint256 totalCharge) internal {
        require(msg.value >= totalCharge, "Not enough eth");

        require(totalMinted() + quantity <= maxSupply, "Exceed max supply");        

        _safeMint(targetAddress, quantity);

        uint256 returnValue = (msg.value - totalCharge);
        if (returnValue > 0){
            payable(msg.sender).transfer(returnValue);
        }

    }

    function publicMint(uint256 quantity) external payable {
        require(isPublicSale, "Public sale not start yet");
        __safeMint(msg.sender, quantity, price * quantity);
    }

    function whitelistMint(uint256 quantity, bytes32 r, bytes32 s, uint8 v, uint256 quota) external payable {
        
        require(isWhitelistSale, "Whitelist sale not start yet");

        // Check whitelist quota
        uint256 userMinted_and_quantity = whitelistMintRecord[msg.sender] + quantity;
        require(userMinted_and_quantity <= quota, "Exceed quota");
        whitelistMintRecord[msg.sender] = userMinted_and_quantity;

        // Check authorization
        address signer = digestSign(r, s, v, quota);
        require(signer == signerWL, "Incorrect signer");

        __safeMint(msg.sender, quantity, priceWL * quantity);
    }


    function paypalMintPublic(address targetAddress, uint256 quantity, string memory TID) external {
        require(isPublicSale, "Public sale not start yet");

        require(msg.sender == signerWL, "Require paypal signer");

        // Record Paypal Transaction ID
        require(ppRecord[TID]==0, "Minted already");
        ppRecord[TID] = totalMinted();

        __safeMint(targetAddress, quantity, 0);
    }


    function paypalMintWhitelist(address targetAddress, uint256 quantity, uint256 quota, string memory TID) external {

        require(isWhitelistSale, "Whitelist sale not start yet");

        // Check whitelist quota
        uint256 userMinted_and_quantity = whitelistMintRecord[targetAddress] + quantity;
        require(userMinted_and_quantity <= quota, "Exceed quota");
        whitelistMintRecord[targetAddress] = userMinted_and_quantity;

        require(msg.sender == signerWL, "Require paypal signer");

        // Record Paypal Transaction ID
        require(ppRecord[TID]==0, "Minted already");
        ppRecord[TID] = totalMinted();

        __safeMint(targetAddress, quantity, 0);
    }


    function digestSign(bytes32 r, bytes32 s, uint8 v, uint256 quota) internal view returns (address){
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, quota));
        address signer = ecrecover(digest, v, r, s);
        return signer;
    }



    function reveal(string calldata baseURI_, uint256 a, uint256 b) external onlyOwner {
        p = a;
        q = b;

        __baseURI = baseURI_;
        revealed = true;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;
    }



    function tokenURI(uint256 tokenId) public view override returns (string memory){
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        
        // return blind uri if Not reveal
        if (!revealed) { 
            return baseURI; 
        }
        // return real uri if revealed
        return string(abi.encodePacked(baseURI, Strings.toString(getShuffled(tokenId))));
    }

    function getShuffled(uint256 token_id) internal view returns (uint256){
        if (token_id >= giveaway){
            uint256 shuffled = token_id - giveaway;
            for (uint256 i; i < p; i++){
                shuffled = (shuffled ** p + q) % (maxSupply - giveaway) ;
            }
            return shuffled + giveaway;
        }
        return token_id;
    }



}