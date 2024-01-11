//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

// import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract downtowndrugons is ERC721A, Ownable {

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public publicSaleOpen;
    bool public freeSaleOpen;
    string public baseURI = "ipfs://QmYfPR2aC574R3Y6XxvkqwiY4VVS6LZfXH4CWsDm36kHoV/";  
    string public baseExtension = ".json";
    
 
    uint256 public  MAX_FREE_PER_TX = 1;    
    uint256 public  MAX_FREE_SUPPLY = 2000; 

    uint256 public  MAX_PER_TX = 4;              
    uint256 public  MAX_PER_WALLET = 10;                
    uint256 public  MAX_SUPPLY = 10000;                  
    uint256 public  cost = 0.005 ether;                

    mapping(address => bool) public userMintedFree;

    constructor() ERC721A("Downtown Drugans", "DTD") {
        publicSaleOpen = false;
        freeSaleOpen = false;
        
        
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");
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

    function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
    MAX_SUPPLY = _MAX_SUPPLY;
    }
    
    function setMAX_FREE_SUPPLY(uint256 _MAX_FREE_SUPPLY) public onlyOwner {
    MAX_FREE_SUPPLY = _MAX_FREE_SUPPLY;
    }

    function setMAX_PER_WALLET(uint256 _MAX_PER_WALLET) public onlyOwner {
    MAX_PER_WALLET = _MAX_PER_WALLET;
    }

    function setMAX_PER_TX(uint256 _MAX_PER_TX) public onlyOwner {
    MAX_PER_TX = _MAX_PER_TX;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleOpen = !(publicSaleOpen);
    }

    function toggleFreeSale() public onlyOwner {
        freeSaleOpen = !(freeSaleOpen);
    }

    function publicMint(uint256 numOfTokens) external payable callerIsUser {
        require(publicSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= MAX_PER_TX, "Can't claim more in a tx");
        require(numberMinted(msg.sender) + numOfTokens <= MAX_PER_WALLET, "Cannot mint this many");
        require(msg.value >= cost * numOfTokens, "Insufficient ether provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function freeMint(uint256 numOfTokens) external callerIsUser {
        require(freeSaleOpen, "Free Sale is not active yet");
        require(!userMintedFree[msg.sender], "User max free limit");
        require(totalSupply() + numOfTokens < MAX_FREE_SUPPLY, "Exceed max free supply, use publicMint to mint"); 
        require(numOfTokens <= MAX_FREE_PER_TX, "Can't claim more for free");

        userMintedFree[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function retrieveFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to retrieve");
        
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
        return publicSaleOpen;
    }

    function isFreeSaleOpen() public view returns (bool) {
        return freeSaleOpen && totalSupply() < MAX_FREE_SUPPLY;
    }


}