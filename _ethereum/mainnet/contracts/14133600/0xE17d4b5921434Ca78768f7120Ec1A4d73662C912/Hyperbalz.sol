// SPDX-License-Identifier: MIT
/*
                     :         ,                                                                    
                    .         =                                                                     
                   .~        $.                                                                     
                   -,      .#!                                                       ~              
                  ;!       *@                                                       *               
                  *       -@,            .               ~~~~~~     ,~~~~~~~.      !                
                 #:      -@=            !    !#######,  ~@@@@..    .@@@@@@@$       !                
                -#      ~@@:     ,*.   -!    =#~.:$!    ~@!        .@!!!;@*      ,@-                
                @-     ,@@#  -.    @   @    .@$~@@      @@         @@ ~@@$       @=                 
               != ,:   #@@#@@*     =@;@!    !@=$~      ~@-        -@@!@#~       :#;;*=              
              ;@:@@$  =@@@@@@      -@@@:    @@=        #@, ~@@    !@@@@        ~@@@@@;              
              $@@@@   :::@@@;       :@@    !@!        ,@@@@:,     #@@@~        #::@@:               
             @@@@@!     =@@@,       .@     =$         ~@#=       ,@ :@@           #!                
            ~@*#@@~    ,@@@=        @*    .@,         #@         @;  ~@*         ~@,                
            = .@@#     ;@@@,        @:    @~         ,@$        ,=    ;@-        #.                 
              ;@@,    .@@@=        .@    ,#          $@.        ;      ~$       **                  
              @@@~!@@@@@@@,        ;:    :          .#@@@=**:   ~       ;-     .*                   
             *@@@@@@@@@@@=         ;     ~          -~...      .         ,.    .                    
            .@@@@@@@*$@@@~         .                                           :                    
            ;@@@     @@@@                                                                           
            #@@;    ;@@@-.;                                                                         
           !@@@    .#@@$*@,                                            !-                           
          .@@@; ~~ ;@@@@@#.   ~!               :         -           .#@-                           
          ;@@@.@#  @@@@@@*    #@@.            ,@         #          ~@@$     ...,;@@@@@:            
          #@@@#@: !@@@@@@    -@@@@=.          $@;        #         =@@@$     -~!@@@@@@@             
         ;@@@@@@ .#@@$@@-    ;@$$#@@-.       *@@$        #       -$@#-*$         -$@@#              
        .@@@@@@, *@@:.$$     @@  .#@@;      .@@@@,      ,@      :@@-. *$          =@@.              
        ;@@=$@$ .@=  ,@;    $@-~=@=!        @$ =@-      ~@     ;@@-   *$         *@#                
        @@! ;@; ~.   :@    -@@#@@.         ;#  .@#      ~@     ,@@~  .@$        =@@-                
       :=   @@       @-    !@@@=          .@,   ;@      ~@      ,=@; .@$       *@@!                 
            @       ,$     @@~@@@         @:     =*     $@        *@$.@$      $@@*                  
           @=       *:    =@~ :#@~       ;;      ~=     @@         !@@@.     *@@@-                  
           @;       =    .#=    #@.      :        !,    @@@#,       !@@     $@@@@@@                 
          :@       .~    ~@#!!!!!@@~    ,         ..    @@@@!::      ;@    .;@@@@@@#!               
          ;        ,     ##########=   .           *   !#.            !         ~###@@.             
          !        -                                                                ~~~             
          :                                                                                         
         =                                                                                                                                                                         
*/
// TEAM HYPERXYZ
// Designer @airhead
// Developer @catpluto

pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";


// OpenSea proxy
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}
/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//----------------------------------------------------------------------------
// Main contract
//----------------------------------------------------------------------------
contract Hyperbalz is
    ERC721Enumerable,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;
    uint256 public PUBLIC_SUPPLY = 7700; // Reserve 77
    uint256 public MAX_SUPPLY = 7777;
    uint256 public RESERVE_SUPPLY = MAX_SUPPLY-PUBLIC_SUPPLY;
    uint256 public PUBLIC_MINT_LIMIT = 10;
    uint256 public PRESALE_MINT_LIMIT = 5;
    uint256 public tierLimit = 1000;

    
    bool public isPresale = true;
    bool public isRevealed = false;
    mapping(address => uint256) public mintBalances;
    mapping(uint256 => uint256) public pricelist;

    string internal baseTokenURI;
    address[] internal payees;
    string public PROVENANCE_HASH; // keccak256

    // opensea proxy
    address private immutable proxyRegistryAddress;

    constructor(
        string memory _initialURI,
        address[] memory _payees,
        uint256[] memory _shares,
        address _proxyRegistryAddress
    )
        payable
        ERC721("HYPERBALZ", "HBZ")
        Pausable()
        PaymentSplitter(_payees, _shares)
    {
        
        _pause();
        baseTokenURI = _initialURI;
        payees = _payees;
        proxyRegistryAddress = _proxyRegistryAddress;

        // @dev: initialize the base price tiers
        pricelist[0] = 0.03 ether;
        pricelist[1] = 0.05 ether;
        _initializeEIP712("HYPERBALZ");
    }

    function purchase(uint256 _quantity)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        if(isPresale){
            require(
                _quantity + mintBalances[msg.sender] <= PRESALE_MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }
        else{
            require(
                _quantity + mintBalances[msg.sender] <= PUBLIC_MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }
        _mint(_quantity);
    }
    function _mint(uint256 _quantity) internal {
        uint256 ts = totalSupply();
        uint256 currentPrice = ts < tierLimit
            ? pricelist[0]
            : pricelist[1];

        require(msg.value >= currentPrice * _quantity, "Not enough value");

        require(
            _quantity + ts <= PUBLIC_SUPPLY,
            "Purchase exceeds available supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender, ts + i);
        }

        // @dev: contract state housekeeping
        // for check minted quantity
        mintBalances[msg.sender] += _quantity;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        // @dev: The revealed URI does not add a `/` or a file extesion.
        return
            isRevealed
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : baseURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    /**
     * Convinience function for checking the current price tier
     */
    function getCurrentPrice() external view returns (uint256) {
        uint256 ts = totalSupply();
        return ts < tierLimit ? pricelist[0] : pricelist[1];
    }
    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        uint256 ts = totalSupply();
        require(
            recipients + ts <= MAX_SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i],ts+i);
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function updatePricing(uint256 _tier, uint256 _price) external onlyOwner {
        pricelist[_tier] = _price;
    }

    function updateTierCutoff(uint256 _limit) external onlyOwner {
        tierLimit = _limit;
    }

    function setSaleState(bool _state) external onlyOwner {
        isPresale = _state;
    }

    function setPresaleLimit(uint128 _limit) external onlyOwner {
        PRESALE_MINT_LIMIT = _limit;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _limit;
    }
    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setReveal(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
    function reserve(uint256 n) external onlyOwner {
      require(n < RESERVE_SUPPLY, "Exceed maximum reserve token");
      uint256 ts = totalSupply();
      for (uint256 i = 0; i < n; i++) {
          _safeMint(msg.sender, ts + i);
          RESERVE_SUPPLY--;
      }
    }
}