/**********************************************************************************************  


     ▄▄▄▄    ▄▄▄       ▄▄▄▄    ▄▄▄      ▒███████▒ ▒█████   ███▄ ▄███▓ ▄▄▄▄    ██▓▓█████ 
    ▓█████▄ ▒████▄    ▓█████▄ ▒████▄    ▒ ▒ ▒ ▄▀░▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▓██▒▓█   ▀ 
    ▒██▒ ▄██▒██  ▀█▄  ▒██▒ ▄██▒██  ▀█▄  ░ ▒ ▄▀▒░ ▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██▒▒███   
    ▒██░█▀  ░██▄▄▄▄██ ▒██░█▀  ░██▄▄▄▄██   ▄▀▒   ░▒██   ██░▒██    ▒██ ▒██░█▀  ░██░▒▓█  ▄ 
    ░▓█  ▀█▓ ▓█   ▓██▒░▓█  ▀█▓ ▓█   ▓██▒▒███████▒░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓░██░░▒████▒
    ░▒▓███▀▒ ▒▒   ▓▒█░░▒▓███▀▒ ▒▒   ▓▒█░░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒░▓  ░░ ▒░ ░
    ▒░▒   ░   ▒   ▒▒ ░▒░▒   ░   ▒   ▒▒ ░░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░  ░      ░▒░▒   ░  ▒ ░ ░ ░  ░
     ░    ░   ░   ▒    ░    ░   ░   ▒   ░ ░ ░ ░ ░░ ░ ░ ▒  ░      ░    ░    ░  ▒ ░   ░   
     ░            ░  ░ ░            ░  ░  ░ ░        ░ ░         ░    ░       ░     ░  ░
          ░                 ░           ░                                  ░           

                                        . . . . .                                        
                        .** . . . . . .**** . . . .****************                        
                 ****************** .** . . .**************************** .                
            . . . . .************** . . . .******************************** . . .          
        . . . . . .************** . . . . .********************************** . . .        
      . . . . . .************ . . . . . . .******** .************************ . . . . .    
   . . . . . . . .****** .** . . . . . . .********************************** . . . . . . .  
  . . . . . . . . .****** .** . . . . . .******************** .**** .**** .** . . . . . . .
. . . . . . . . . . . .******** . . . . .****************** . . .** . .** . . . . . . . . .
. . . . . . . . . . . . .******** . . . . . . .********** . . . . . .******** . . . . . . .
. . . . . . . . . . . . .************ . . . . . .****** . . . . . . . .****** .**** . . . .
  . . . . . . . . . . . .************ . . . . . .********** . . . . . . . . .****** . . . .
  . . . . . . . . . . . . .********** . . . . . .******** . . . . . . . .********** . . .  
    . . . . . . . . . . . . .****** . . . . . . .**** . . . . . . . . .************ . .    
      . . . . . . . . . . . .**** . . . . . . . . . . . . . . . . . . . . . .** . .**      
          . . . . . . . . . .**** . . . . . . . . . . . . . . . . . . . . . . .** .        
              . . . . . . . . . .** . . . . . . . . . . . . . . . . . . . . .              
                    . . . . . . . . . . . . . . . . . . . . . . . . . . .                  
                                . . . . . . . . . . . . . .



BabaZ is a web3 zombie world.
You can earn money, make friends and play games in this metaverse.

web: https://babaz.io
twitter: https://twitter.com/babaz_nft
discord: https://discord.com/invite/Baburefype

email: babaz.nft@gmail.com


**********************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Ownable
import "./Ownable.sol";

// local contract
import "./Withdrawable.sol";
import "./ERC721Opensea.sol";
import "./PublicSalesActivation.sol";
import "./Whitelist.sol";
import "./PreSalesActivation.sol";

// BabaZ contract
contract BabaZ is
    Ownable,
    PublicSalesActivation,
    PreSalesActivation,
    Whitelist,
    Withdrawable,
    ERC721Opensea  
    
{
    // quantitative restrictions
    uint256 public constant TOTAL_MAX_QTY = 4000;
    uint256 public constant GIFT_MAX_QTY = 233;
    uint256 public constant PRESALES_MAX_QTY = 1200;
    uint256 public constant MAX_QTY_PER_MINTER = 2; 
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;

    // price
    uint256 public constant PRE_SALES_PRICE = 0.049 ether;
    uint256 public constant PUBLIC_SALES_START_PRICE = 0.07 ether;

    // minter
    mapping(address => uint256) public preSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    // sales
    uint256 public preSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;

    // init
    constructor() ERC721("BabaZombie", "BBZ") Whitelist("BabaZombie", "1") {}

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _; 
    } 

    // pre mint
    function preSalesMint(
        uint256 _mintQty,
        bytes memory _signature
    )
        external
        payable
        isPreSalesActive
        isSenderWhitelisted( _signature )
        callerIsUser
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            preSalesMintedQty + _mintQty <= PRESALES_MAX_QTY,
            "Exceed pre max limit"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(
            msg.value >= _mintQty * PRE_SALES_PRICE,
            "Insufficient ETH"
        );

        preSalesMinterToTokenQty[msg.sender] += _mintQty;
        preSalesMintedQty += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
    }

    // public mint
    function publicSalesMint(uint256 _mintQty)
        external
        payable
        isPublicSalesActive
        callerIsUser
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <=  MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(
            msg.value >= _mintQty * PUBLIC_SALES_START_PRICE, 
            "Insufficient ETH"
        );

        publicSalesMinterToTokenQty[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // airdrop
    function gift(address[] calldata receivers) external onlyOwner {
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );

        giftedQty += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }

    } 


}
