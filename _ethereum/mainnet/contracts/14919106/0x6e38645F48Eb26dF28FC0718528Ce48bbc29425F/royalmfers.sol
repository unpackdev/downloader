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
import "./ERC1155.sol";
import "./Ownable.sol";

contract RoyalMFers is ERC721A, Ownable {
    uint256 public MAX_PER_WALLET = 20;
    uint256 public MAX_PER_TXN = 20;
    uint256 FREE_PER_WALLET = 1; //for OOF Pass Holders only
    uint256 public MAX_SUPPLY = 7070;
    uint256 public MINT_PRICE = 0.002 ether;
	
	address OOF = 0x0F5aC1716d088B52869A3Cfe28F10ddfcC565e94;
    
    mapping(address => uint8) private qtyMinted;

    bool public mintIsActive = false;

    string public baseURI = "ipfs://QmS2HXhNv4xFVvbmtBrxsNJNvovtpBx9ia2wWBPXFKJ9Mr/";

    constructor() ERC721A("RoyalMFers", "RMF") {}

    function mint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintIsActive, "Mint must be active to mint");
        require(quantity > 0 && quantity < (MAX_PER_TXN + 1), "Max per transaction exceeded");
		require(quantity + qtyMinted[msg.sender] < (MAX_PER_WALLET + 1), "Max per wallet reached");
        require(totalSupply() + quantity < (MAX_SUPPLY + 1), "Exceeds max supply");

        uint256 mintedByAddress = qtyMinted[msg.sender];

        //Free mint for OOF Collective holders, paid otherwise
        if (!isOOFHolder(msg.sender)) {
            require(msg.value >= MINT_PRICE * quantity, "Not enough ETH for transaction, check MINT_PRICE");
        }
        else if (mintedByAddress < FREE_PER_WALLET && quantity <= (FREE_PER_WALLET - mintedByAddress)  ) {
            require(msg.value == 0, "Wallets holding OOF get 1 free mint");
        }
        else if (mintedByAddress >= FREE_PER_WALLET) {
            require(msg.value == MINT_PRICE * quantity, "Ether sent is incorrect");
        }
        else {
            require(msg.value == MINT_PRICE * (quantity + mintedByAddress - FREE_PER_WALLET), "Ether sent is incorrect");
        }
        
        qtyMinted[msg.sender] += quantity; //tracking minted
        _safeMint(msg.sender, quantity);
        
    }


    function ownerMint(address[] calldata addresses, uint8 quantity) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + quantity < MAX_SUPPLY + 1, "Exceeds max supply");
            _safeMint(addresses[i], quantity, "");
        }
    }

    function setPrice(uint256 price) external onlyOwner 
    {
        MINT_PRICE = price;
    }

    function setWalletLimit(uint256 newWalletLimit) external onlyOwner 
    {
        MAX_PER_WALLET = newWalletLimit;
    }

    function setTxnLimit(uint256 newTxnLimit) external onlyOwner 
    {
        MAX_PER_TXN = newTxnLimit;
    }

    function flipMintActiveState() external onlyOwner
    {
        mintIsActive = !mintIsActive;
    }

    function isOOFHolder(address addr) public view returns (bool) {
        
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