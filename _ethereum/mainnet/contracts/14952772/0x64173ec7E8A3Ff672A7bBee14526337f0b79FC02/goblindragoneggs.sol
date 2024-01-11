//SPDX-License-Identifier: MIT
//by kevlabs

//              _     _ _                            
//             | |   | (_)                           
//   __ _  ___ | |__ | |_ _ __   ___  __ _  __ _ ___ 
//  / _` |/ _ \| '_ \| | | '_ \ / _ \/ _` |/ _` / __|
// | (_| | (_) | |_) | | | | | |  __/ (_| | (_| \__ \
//  \__, |\___/|_.__/|_|_|_| |_|\___|\__, |\__, |___/
//   __/ |                            __/ | __/ |    
//  |___/                            |___/ |___/     


pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract GoblinDragonEggs is ERC721A, Ownable { //change

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public paidSaleOpen;
    bool public freeSaleOpen;
    bool public revealed = false;
    string public hiddenMetadataUri;
    string public baseURI = "";  
    string public uriSuffix = ".json";
    
    
 
    uint256 public  maxFreePerAdress = 2;    
    uint256 public  maxFreeSupply = 2000; 

    uint256 public  maxPerTx = 4;              
    uint256 public  maxPerWallet = 10;                
    uint256 public  maxSupply = 7000;                  
    uint256 public  cost = 0.005 ether;                

    mapping(address => bool) public userMintedFree;

    constructor() ERC721A("goblindragoneggs.wtf", "GDE") {     
        paidSaleOpen = true;
        freeSaleOpen = true;
        setHiddenMetadataUri("ipfs://QmYNao65YrEqhM2CmcMWT2d4XbeBBKWk7BYmU2Yw5CxCDb/nothatched.json");
       
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    }

    function seturiSuffix(string memory _newuriSuffix) public onlyOwner {
    uriSuffix = _newuriSuffix;
    }

    function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
    }

    function setMaxFreePerAdress(uint256 _maxFreePerAdress) public onlyOwner {
    maxFreePerAdress = _maxFreePerAdress;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
    }
    
    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
    maxFreeSupply = _maxFreeSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
    maxPerTx = _maxPerTx;
    }

      function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId), ".json"
            )
        ) : "";
    }

    function _startTokenId() internal pure override returns (uint) {
	return 1;
    }

    function togglePaidSale() public onlyOwner {
        paidSaleOpen = !(paidSaleOpen);
    }

    function toggleFreeSale() public onlyOwner {
        freeSaleOpen = !(freeSaleOpen);
    }

    function paidMint(uint256 numOfTokens) external payable callerIsUser {
        require(paidSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < maxSupply, "Exceed max supply"); 
        require(numOfTokens <= maxPerTx, "Can not claim more in a txn");
        require(numberMinted(msg.sender) + numOfTokens <= maxPerWallet, "Can not mint this many");
        require(msg.value >= cost * numOfTokens, "Insufficient funds provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMint(uint256 numOfTokens) external callerIsUser {
        require(freeSaleOpen, "Free Sale is not active yet");
        require(totalSupply() + numOfTokens < maxFreeSupply, "Exceed max free supply, use paidMint to mint"); 
        require(numOfTokens <= maxFreePerAdress, "Can't claim more for free");
        require(numberMinted(msg.sender) + numOfTokens <= maxFreePerAdress, "Can not mint this many");

        userMintedFree[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to withdraw");
        
        _withdraw(payable(msg.sender), balance);
    }

    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function accountBalance() internal view returns(uint256) {
        return address(this).balance;
    }

    function ownerMint(address mintTo, uint256 numOfTokens) external onlyOwner {
        _safeMint(mintTo, numOfTokens);
    }

    function isSaleOpen() public view returns (bool) {
        return paidSaleOpen;
    }

    function isFreeSaleOpen() public view returns (bool) {
        return freeSaleOpen && totalSupply() < maxFreeSupply;
    }
}