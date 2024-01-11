// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//   $$$$$$\   $$$$$$\  $$$$$$$$\        $$$$$$\            $$\ $$\                       $$\     $$\                      
//  $$  __$$\ $$  __$$\ $$  _____|      $$  __$$\           $$ |$$ |                      $$ |    \__|                     
//  $$ /  $$ |$$ /  $$ |$$ |            $$ /  \__| $$$$$$\  $$ |$$ | $$$$$$\   $$$$$$$\ $$$$$$\   $$\ $$\    $$\  $$$$$$\  
//  $$ |  $$ |$$ |  $$ |$$$$$\          $$ |      $$  __$$\ $$ |$$ |$$  __$$\ $$  _____|\_$$  _|  $$ |\$$\  $$  |$$  __$$\ 
//  $$ |  $$ |$$ |  $$ |$$  __|         $$ |      $$ /  $$ |$$ |$$ |$$$$$$$$ |$$ /        $$ |    $$ | \$$\$$  / $$$$$$$$ |
//  $$ |  $$ |$$ |  $$ |$$ |            $$ |  $$\ $$ |  $$ |$$ |$$ |$$   ____|$$ |        $$ |$$\ $$ |  \$$$  /  $$   ____|
//   $$$$$$  | $$$$$$  |$$ |            \$$$$$$  |\$$$$$$  |$$ |$$ |\$$$$$$$\ \$$$$$$$\   \$$$$  |$$ |   \$  /   \$$$$$$$\ 
//   \______/  \______/ \__|             \______/  \______/ \__|\__| \_______| \_______|   \____/ \__|    \_/     \_______|
                                                                                                                       

import "./ERC721A.sol";
import "./Ownable.sol";

contract pxVeeConFriends is ERC721A, Ownable {
    uint256 public MAX_PER_WALLET = 2;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public MINT_PRICE = 0 ether;
    
    mapping(address => uint8) private qtyMinted;

    bool public mintIsActive = false;

    string public baseURI = "ipfs://QmdJqW3QVAc8o557dLh8YLmoS7MdRAYwhne8A5gjsTh9mz/";

    constructor() ERC721A("pxVeeConFriends", "pxVCF") {}

    function mint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintIsActive, "Mint must be active to mint");
        require(quantity > 0 && quantity + qtyMinted[msg.sender] <= MAX_PER_WALLET, "Max per wallet reached");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        
        qtyMinted[msg.sender] += quantity; //tracking minted
        _safeMint(msg.sender, quantity);
        
    }


    function ownerMint(address[] calldata addresses, uint8 quantity) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
            _safeMint(addresses[i], quantity, "");
        }
    }

    function setPrice(uint256 price) external onlyOwner 
    {
        MINT_PRICE = price;
    }

    function setMaxMints(uint256 max) external onlyOwner 
    {
        MAX_PER_WALLET = max;
    }

    function flipLiveState() external onlyOwner
    {
        mintIsActive = !mintIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}