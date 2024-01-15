// SPDX-License-Identifier: MIT
/*                                             
                         .@tG@GL08C.                         
                       8i;;;;;;;;;;;i@                         
                     1@;;;;;;;;;;;;;;;@;                       
                    tL;;;;;;;iii;;;;;;;0:                      
                   0i;;;;1@@@@@@@@L;;;;;CG.                    
                 1@;;;;;8@@@@@@@@@@@;;;;;;00,                  
               t8t;;;;;0@@@@@@@@@@@@@1;;;;;;G0,                
              8t;;;;;G@@@@@@@@@@@@@@@@G;;;;;;i@1               
            ,81;;;;i8@@@@@@@@@@@@@@@@@@0;;;;;;;@:              
            i@;;;;;t@@@@@@@@@@@@@@@@@@@@;;;;;;;@:              
            t@;;;;;t@@@@@@@@@@@@@@@@@@@8;;;;;;;G               
             0L;;;;;G@@@@@@@@@@@@@@@@@C;;;;;;i0                
          .18800fi;;;;;C8@@@@@@@@@Gt;;;;ttL@0LfG8G.            
        t@f;;;;;;iLG@Gf;;;8@@@@81;;L@GL1;;;;;;;;;;G0           
      1@t;;;;;;;;;;;;;;t@L;i@@L;f0f;;;;;;;;;;;;;;;;1@:         
     i@;;;;;;;;;10;;;;;;;18iitf8i;;;;;;;;;;;;;;;;;;;LC         
     8;;;;;;;;;;;@1;;;;1;;;8L8L;;;;f8;;;;;;;G;;;;;;;;@.        
    fC;;;;;;t@;;;1t;;;;@;;;;@@;;;;GC;;;L;;;;C;;;;;;;;CC        
   .0t;;;;;;f8;;;tC;;;;Ci;;;@i;;;t@;;;i8;;;;L8;;;;;;;f8.       
   ;@;;;;;;;fL;;;G1;;;;;0;;;0;;;;01;;;i@;;;;L8;;;;;;;;@:       
   81;;;;;;;ft;;;@1;;;;;8i;;0;;;;8i;;;i8;;;;L8;;;;;;;;0f       
   @i;;;;;;;f8;;;@1;;;;;8i;;0i;;tG;;;;;0;;;;Lt;;;;;;;;10       
  tG;;;;;;;;;8t;;@1;;;;;@1;;0f;;GG;;;;;Gi;18f;;;;;;;;;10       
  LG;;;;;;;;;;C0;@1;;;;;@1;;LC;;GG;;;;;0@@@@@80Gi;;;;;81       
  .0;;;;;;i8@@Ci18@@@@@88i;;fL;;;t8@@i;;;;;;;;;;;;;;;;@:       
   :@;;;;1;;;;;;;;;;;;;;;188@8880;;;;;;;;;;;;;;;;;;;;8t        
     0t;;;;;;;;;;;;;;;;;;;;1;;C;;ti;;;;;;;;;;;;;;;;t@,         
       L@Lt;;;;;;;;;;;;;;;i8;;Cf;tL;;;;;;;;;;;;;tCGi           
           ;C0@0Lfi;;;;;;;Ci;;L8;;LC;;;;;;;LC@C1.              
            1i;;;1@G@Gt;;CG;;;L8;;;LC;C88Li;;@i                
            1i;;;;0;;;1@0f;;;;CL;;;C@f;;18;;;@i                
            ii;;;;0t;;;;1@8i;;@;i88G;;;;i8;;;@:                
            it;;;;0C;;;;iL;;8@@81;;0;;;;;01;;8                 
            i0;;;;0C;;;;iL;;;@f;;;;ft;;;;0C;18                 
            i8;;;;0t;;;;1f;;;@f;;;;ft;;;;0C;18                 
            i8;;;;0;;;;;ft;;;@f;;;;G;;;;;0C;i8                 
            i0;;;1@;;;;;@t;;;@f;;;;@;;;;;0C;;8                 
            iL;;;01;;;;;@t;;;@f;;;;G;;;;;0C;;@;                
            ii;;t0;;;;;;@1;;;@f;;;0C;;;;;tC;;@i                
            Li;;G;;;;;;f0;;;;@f;;i8;;;;;;iC;;Li                
            @i;iG;;;;;;C1;;;;@f;;;;;;;;;;CC;;i0                
            C;;@f;;;;;;8;;;;;@f;;;;;;;;;;0f;;i@                
           GC;;8;;;;;;@t;;;;;@t;;;;;;;;;18;;;;C1               
          .0;;L8;;;;;L8;;;;;;@;;;t1;;;;i8i;;;;1G               
          :L;;L8;;;;tG;;;;;;1@;;;@i;;;i81;;;;;;8:              
          @1;;L8;;;1@;;;;;;;f@;;LG;;;;0t;;;;;;;1@              
         L0;;;;@t;;;;;;;;;;;8;;i8;;;;L8;;;;;;;;;0L             
        ,8;;;;;;8;;;;;;;;;;iC;;0t;;;;@;;;;;;;;;;;8.            
       i8;;;;;;;C0;;;;;;;;;81;f8;;;;LL;;;;;;;;1;;i8,           
      ;0;;;;;;;;;01;;;;;;;tC;;Ct;;;;@f;;;;;;i@1;;;;0           
     i@;;C1;;;;;;1@;;;;;;;@i;;8;;;;i@;;;;;;;Gi;;;;;f8          
    t0;;;C0;;;;;;;0L;;;;;GG;;;@;;;;f@;;;;;;iC;;;;;;;tG         
   ;@;;;;;0;;;;;;;0G;;;;;G;;;;@;;;;f@;;;;;;8f;;;;;;;;LG        
   0;;;;;;8i;;;;;;1G;;;;i@;;;;G;;;;f8;;;;;1@;;;;;;;;;;18       
  CG;;;;;;8i;;;;;;;G;;;;i@;;;;;;;;;f@;;;;;iG;;;;;;;;;;;CC      
  LG;;;;;;L;;;;;;;iG;;;;;C0i;;;;;;;;;;;;;;;;;;;;;;;;;;;iG.     
   t8@@88@@@Gti;;;;;;;;1tC@CCCC0@0tti;;;itC@CCLttCCC00Cf       
              ;tttffff1             ,ttt:                                                                                          
*/
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Counters.sol";
import "./Strings.sol";

contract TheBeginningIsNear is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_FREE = 2;
    uint256 public MAX_PER_WALLET = 6;
    uint256 public MAX_SUPPLY = 6666;
    uint256 public PRICE = 0.005 ether;
    bool public revealed = false;
    bool public initialize = false;
    string public baseURI = "";

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("The Beginning Is Near", "TBIN") {}

    function freeMint(uint256 quantity) external
    {
        uint256 cost = PRICE;
        bool free = (qtyFreeMinted[msg.sender] + quantity <= MAX_FREE);
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += quantity;
            require(quantity < MAX_FREE + 1, "Max free reached.");
        }

        require(initialize, "The tale has not begun.");
        require(_numberMinted(msg.sender) + quantity <= MAX_FREE, "You may mint more for a price.");
        require(totalSupply() + quantity < MAX_SUPPLY + 1, "None left. The tale unfolds in the metadata.");

        _safeMint(msg.sender, quantity);
    }

    function mintMore(uint256 quantity) external payable
    {
        require(initialize, "The tale has not begun.");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "You have already minted. Watch the tale unfold.");
        require(msg.value >= quantity * PRICE, "Please send the exact amount.");
        require(totalSupply() + quantity < MAX_SUPPLY + 1, "None left. The tale unfolds in the metadata.");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI_ = _baseURI();

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        } else {
            return string(abi.encodePacked(baseURI_, ""));
        }
    }
    
    function withdraw() external onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_WALLET = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE = _limit;
    }

}