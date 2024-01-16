// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
Ooglies

Badfroot x SPYR

                         ......                                                           
                       =@%**===%:                                                         
                       .@%+-   -*                                                         
                        .#%+    %                                                         
                          *@:   #:                                                        
                           +@.  ++                                                        
                            *#  +#-.                                                      
                           =%%=.*#-#.   ..:::..                                           
                 .-=*#######- -=:  .##%#*=----=*#%*=:                                     
              -*#+-:.                            .-*%@*=.                                 
           .*%=.                                     .=#@%+.                              
          +%-                                            -*@%+.                           
        :%*                                                 -*@*:                         
       :@=    .:.                            -.               .*@+                        
      .@*    :.     ::         ::             *+                -@*                       
      #@            .:+       +-               *#. .             -@=                      
     :@*             :=*     *-                ==% =              *@                      
     =@=             ::#-   :#                 :-@:+-             -@=                     
     =@=             .:*#   *-                 .=#:*=             .@#                     
     :@*              .+%   #.                 ::% %=             :@%                     
      %@               =#   *:                 = #.@:             *@@                     
      :@+    .        .+:   -+                :.+-=#             :+#@                     
       +@:            .=     *.                :+ #             .+ *@.                    
        #@:          .-       +               := -             .+  -@-                    
         *@-             .     :             --               .=    ##                    
          +@+        .    -                :-                 :     .%+                   
           +@#.      .    :               .                           +*                  
            -@@-                                                       .+=                
             :@@*                                                         ==:             
              :@@%.                                                         .==           
               .%@@:                                                           +=         
                .@%%:                                      .+-.     :-====--:.  -#        
                 :@*%.                                      :#@%+   +@@@@@@@@#==+%*       
                  :@-#:                    .-:                :*@@+  +@@@@@@@@%- :#.      
                   +* --:.                ..                     :=-  -@@@@@@@@@*         
                    %.                                                 .#@@@@@@@@#        
                    =+        .                    :####*=-.  :-:        :@@@@@@@@#       
                     %.       :@*                  :@@@@@@@@@**@@@@#**++=+@@@@@@@@@=      
                     :*    ::. :%@.                 =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
                      :* =@@@@@#==- =*+=:.           -@@@@@@@@@@%++*#%@@@@@====+#@@@=     
                       .*@@#@@@@@@%+*@@@@@@%#+=-.      +@@@@@@@@*      :=#@       .-=     
                         -%: =@@@@@@@@@@@@@@@@@@@@@%#**#@@@@@@@@@-                        
                           =:  =@@@@@@@@#++*%@@@@@+++++**##%%@@@@@=                       
                                 -%@@@@@.     :+#=               ..                       
                                   :+@@@*                                                 
                                      :+%#                                                


https://ooglies.badfroot.com

---

# BADFROOT TEAM

## Badfroot (Jack Davidson)
Artist/Creator of SkullKids
* Website: https://badfroot.com
* Twitter: @theBadfroot


## Jeff Sarris
Brand/Developer
* Website: https://SPYR.me
* Twitter: @jeffSARRIS

---

# BUILDING YOUR OWN NFT PROJECT?

## Need someone to handle the tech?
Work with Jeff at https://RYPS.co

## Need help developing your brand and business?
Work with Jeff at https://SPYR.me

---

Alpha  =^.^=

*/
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";


contract Ooglies is ERC721AQueryable, Ownable, ReentrancyGuard {
    string  public baseURI;
    
    address public proxyRegistryAddress;

    address public badfroot;
    address public spyr;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_TX = 25;

    uint256 public publicPrice = 0.00666 ether;

    bool public publicSaleActive;

    mapping(address => bool) public projectProxy;

    constructor(string memory _setBaseURI,address _proxyRegistryAddress,address _badfroot,address _spyr)
        ERC721A("The Ooglies", "OOGLIES") {
        
        // Init Constants
        baseURI = _setBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        badfroot = _badfroot;
        spyr = _spyr;
    }
    

    // Modifiers
    modifier onlyPublicActive() {
        require(publicSaleActive, "Public sale is not live!");
        _;
    }
    // END Modifiers


    // Set Functions
    function setBaseURI(string memory _setBaseURI) public onlyOwner {
        baseURI = _setBaseURI;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setPayoutAddress(address _badfroot,address _spyr) external onlyOwner {
        badfroot = _badfroot;
        spyr = _spyr;
    }
    // END Set Functions


    // Mint Functions
    function publicMint(uint256 _quantity) external payable onlyPublicActive nonReentrant() {
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 Ooglies per transaction!");
        require(publicPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint( msg.sender, _quantity);
    } 

    // Dev minting function 
    function devMint(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");
        _safeMint(_to, _quantity);
    }
    // END Mint Functions


    // Toggle Sale
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    // END Toggle Sale


    // Override start token in ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // Override _baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // Withdraw Funds to Badfroot and SPYR
    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 percent = _balance / 100;
        
        // 50% to Badfroot (Jack Davidson)
        require(payable(badfroot).send(percent * 50));

        // 50% to SPYR (Jeff Sarris)
        require(payable(spyr).send(percent * 50));
    }


    // Proxy Functions
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }

    // OpenSea Secondary Contract Approval - Removes initial approval gas fee from sellers
    // Allow future contract approval
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || projectProxy[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
    // END Proxy Functions

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}