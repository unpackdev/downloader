// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//       $$$$$$\   $$$$$$\  $$$$$$$$\       $$$$$$$\  $$\        $$$$$$\ $$\     $$\  $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\ $$\   $$\ $$$$$$$\  
//      $$  __$$\ $$  __$$\ $$  _____|      $$  __$$\ $$ |      $$  __$$\\$$\   $$  |$$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |$$$\  $$ |$$  __$$\ 
//      $$ /  $$ |$$ /  $$ |$$ |            $$ |  $$ |$$ |      $$ /  $$ |\$$\ $$  / $$ /  \__|$$ |  $$ |$$ /  $$ |$$ |  $$ |$$$$\ $$ |$$ |  $$ |
//      $$ |  $$ |$$ |  $$ |$$$$$\          $$$$$$$  |$$ |      $$$$$$$$ | \$$$$  /  $$ |$$$$\ $$$$$$$  |$$ |  $$ |$$ |  $$ |$$ $$\$$ |$$ |  $$ |
//      $$ |  $$ |$$ |  $$ |$$  __|         $$  ____/ $$ |      $$  __$$ |  \$$  /   $$ |\_$$ |$$  __$$< $$ |  $$ |$$ |  $$ |$$ \$$$$ |$$ |  $$ |
//      $$ |  $$ |$$ |  $$ |$$ |            $$ |      $$ |      $$ |  $$ |   $$ |    $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |
//       $$$$$$  | $$$$$$  |$$ |            $$ |      $$$$$$$$\ $$ |  $$ |   $$ |    \$$$$$$  |$$ |  $$ | $$$$$$  |\$$$$$$  |$$ | \$$ |$$$$$$$  |
//       \______/  \______/ \__|            \__|      \________|\__|  \__|   \__|     \______/ \__|  \__| \______/  \______/ \__|  \__|\_______/ 

import "./ERC721A.sol";
import "./Ownable.sol";

contract CockBlockz is ERC721A, Ownable {
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public MAX_SUPPLY = 500;
    uint256 public MINT_PRICE = 0.0033 ether;
    
    mapping(address => uint8) private qtyMinted;

    bool public mintIsActive = false;

    string public baseURI = "ipfs://QmWdeD9jixF8k1DPmZvNHQCRai7KGrAQU85cxuHdqjEfgD/";

    constructor() ERC721A("CockBlockz", "CB") {}

    function mint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintIsActive, "Mint must be active to mint");
        require(quantity > 0 && quantity + qtyMinted[msg.sender] <= MAX_PER_WALLET, "Max per wallet reached");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");

        //Free mint for OOF Collective holders, paid otherwise
        if (!isOOFHolder(msg.sender)) {
            require(msg.value >= MINT_PRICE * quantity, "Not enough ETH for transaction, check MINT_PRICE");
        }
        
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

    function flipSaleState() external onlyOwner
    {
        mintIsActive = !mintIsActive;
    }

    function isOOFHolder(address addr) public view returns (bool) {
        address OOF = 0x0F5aC1716d088B52869A3Cfe28F10ddfcC565e94;
        return
            ERC721A(OOF).balanceOf(addr) > 0;
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