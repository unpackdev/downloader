// SPDX-License-Identifier: MIT
/*
        ___    ___                  ___                                                          ___        ___      
       (   )  (   )                (   )                                                        (   )      (   )     
  .---. | |_   | |_    .---.  .--.  | |   ___   .--.    .-..   .--. ___ .-.  ___ .-. .-.   .--.  | |___  ___| |.-.   
 / .-, (   __)(   __) / .-, \/    \ | |  (   )/  _  \  /    \ /    (   )   \(   )   '   \ /    \ | (   )(   | /   \  
(__) ; || |    | |   (__) ; |  .-. ;| |  ' / . .' `. ;' .-,  |  .-. | ' .-. ;|  .-.  .-. |  .-. ;| || |  | ||  .-. | 
  .'`  || | ___| | ___ .'`  |  |(___| |,' /  | '   | || |  . |  | | |  / (___| |  | |  | |  |(___| || |  | || |  | | 
 / .'| || |(   | |(   / .'| |  |    | .  '.  _\_`.(___| |  | |  |/  | |      | |  | |  | |  |    | || |  | || |  | | 
| /  | || | | || | | | /  | |  | ___| | `. \(   ). '. | |  | |  ' _.| |      | |  | |  | |  | ___| || |  | || |  | | 
; |  ; || ' | || ' | ; |  ; |  '(   | |   \ \| |  `\ || |  ' |  .'.-| |      | |  | |  | |  '(   | || |  ; '| '  | | 
' `-'  |' `-' ;' `-' ' `-'  '  `-' || |    \ ; '._,' '| `-'  '  `-' | |      | |  | |  | '  `-' || |' `-'  /' `-' ;  
`.__.'_. `.__.  `.__.`.__.'_.`.__,'(___ ) (___'.___.' | \__.' `.__.(___)    (___)(___)(___`.__,'(___)'.__.'  `.__.   
                                                      | |                                                            
                                                     (___)                                                           
*/                                                                                          
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SpermStrings.sol";

contract AttackSpermClub is ERC721, ERC721Enumerable, Ownable {

    bool public saleIsActive = false;
    bool public innerSaleIsActive = false;
    uint8 public saleStage = 0;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant PRE_SUPPLY = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 4;
    uint256 public constant PRICE_PER_TOKEN = 0.01 ether;

    mapping(address => uint8) private _allowList;
    mapping(address=> uint8) private _mintList;

    string private _baseURIStr;
    string private _contractURIStr;
    

    constructor() ERC721("AttackSpermsClub", "ASP") {
    }

    //#Switch For Owenr#
    //set Sale Stage
    function setSaleStage(uint8 _saleStage) external onlyOwner{
        saleStage = _saleStage;
    }

    // Set Inner Sale
    function setInnerSaleState(bool _innerSaleIsActive) external onlyOwner {
        innerSaleIsActive = _innerSaleIsActive;
        saleStage = 1;
    }

    //Set Public Sale
    function setPublicSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
        saleStage = 2;
    }

    //Set White List
    function setWhiteSaleList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    //Get Address's Can Mint Count
    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    // mint NFT
    function mint(uint8 numberOfTokens) external payable{
        uint256 ts = totalSupply();
        uint8 mintCount = _mintList[msg.sender];

        require(saleStage>0, "Sale Is Not Ready!");
        require(saleStage<4,  "All Sperm NFT Token has been sold out!");
        require(ts + numberOfTokens <= MAX_SUPPLY, "The mint quantity has exceeded the issuance limit");
        require(mintCount + numberOfTokens <= MAX_PUBLIC_MINT, "The mint quantity cannot exceed the maximum mint quantity: [4]");

        if(saleStage == 1)//inner sale
        {
            require(innerSaleIsActive, "Inner Sale is not active");
            // require(numberOfTokens <= _allowList[msg.sender], "You donot have enough mint quantity");
            // _allowList[msg.sender] -= numberOfTokens;

            require(ts + numberOfTokens <= PRE_SUPPLY,"The mint quantity has exceeded the pre-sale limit");
            _mintList[msg.sender] += numberOfTokens;

            for (uint256 i = 1; i <= numberOfTokens; i++) {
                _safeMint(msg.sender, ts + i);
            }
        }
        else if(saleStage == 2)//public sale
        {
            require(saleIsActive, "The public sale has not yet begun");            
            require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "You need to pay enough eth");

            _mintList[msg.sender] += numberOfTokens;
            for (uint256 i = 1; i <= numberOfTokens; i++) {
                _safeMint(msg.sender, ts + i);
            }
        }

        ts = totalSupply();
        if(ts==MAX_SUPPLY)
        {
            saleStage = 3;
        }
    }

    // return contractURI
    function contractURI() public view returns (string memory) {
        return _contractURIStr;
    }

    //set ContractURI
    function setContractURI(string memory contractURI_) external onlyOwner() {
        _contractURIStr = contractURI_;
    }

    //fetch tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(bytes(_baseURIStr).length > 0)
        {
            return string(abi.encodePacked(_baseURIStr, Strings.toString(tokenId)));
        }
        else
        {
            return "";
        }
    }

    //set baseURI
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIStr = baseURI_;
    }

    //fetch baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIStr;
    }

    //mint for owner
    function reserve(uint256 n) public onlyOwner {
      uint256 supply = totalSupply();
      uint256 i;
      for (i = 1; i <= n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    //withdraw
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}