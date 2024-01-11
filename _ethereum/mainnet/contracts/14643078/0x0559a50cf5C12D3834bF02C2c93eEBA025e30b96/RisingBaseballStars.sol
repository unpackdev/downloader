// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract  RisingBaseballStars is ERC721, Ownable, ERC721Enumerable{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // MVP incrementor
    Counters.Counter private _MVPCounter;
    // HOF incrementor
    Counters.Counter private _HOFCounter;
    // TC incrementor
    Counters.Counter private _TCCounter;

    // MVP Reserve incrementor
    Counters.Counter private _MVPReserveCounter;
    // HOF Reserve incrementor
    Counters.Counter private _HOFReserveCounter;
    // TC Reserve incrementor
    Counters.Counter private _TCReserveCounter;
    
    // Constant public variables //
    // Prices // 
    uint256 public MVP_PRICE = 0.1 ether;
    uint256 public HOF_PRICE = 1 ether;
    uint256 public TC_PRICE = 2 ether;
    // Supply //
    uint16 public MVP_PRESALE_SUPPLY = 160;
    uint16 public MVP_MAX_SUPPLY = 1500 + MVP_PRESALE_SUPPLY;
    uint16 public MVP_RESERVE_SUPPLY = 1420;
    
    uint16 public HOF_PRESALE_SUPPLY = 30;
    uint16 public HOF_MAX_SUPPLY = 450 + HOF_PRESALE_SUPPLY;
    uint16 public HOF_RESERVE_SUPPLY = 520;
    
    uint16 public TC_PRESALE_SUPPLY = 20;
    uint16 public TC_MAX_SUPPLY = 10 + TC_PRESALE_SUPPLY;      
    uint16 public TC_RESERVE_SUPPLY = 30;
    
    uint16 public MAX_SUPPLY = MVP_MAX_SUPPLY + MVP_RESERVE_SUPPLY + HOF_MAX_SUPPLY + HOF_RESERVE_SUPPLY + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY;
    
    // Toggles ///
    bool public PRESALE_ACTIVE;
    bool public PUBLIC_SALE_ACTIVE;
    bool public RESERVE_SALE_ACTIVE;
    
    // Max Mint // 
    uint8 public MAX_MINT_PER_WALLET = 30;
    mapping(address => uint256) public MINTED_BALANCE;

    // Payments
    address payable public payments; 

    // Metadata Handling
    string private customBaseURI;
    
    // Constructor 
    constructor(address _payments) 
        ERC721("Rising Baseball Stars Membership", "RBS") {
            
            // Payment Splitter
            payments = payable(_payments);
        }    


    function updatePayment(address _payments) public onlyOwner{
        payments = payable(_payments);
    }

    /* --------- PRESALE MINT FUNCTIONS ------------- */

    // Triple Crown Presale
    function mintPresaleTC(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= TC_PRICE * _quantity, "Not enough ether sent.");
        require((2*_quantity) + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PRESALE_ACTIVE, "Presale is not yet live.");
        require(_TCCounter.current() < TC_PRESALE_SUPPLY, "Whitelist is sold out for this member type.");
        if(_quantity > 1){
            require(_TCCounter.current() + _quantity < TC_PRESALE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _TCCounter.increment();
            _safeMint(msg.sender, _TCCounter.current());
            MINTED_BALANCE[msg.sender]++;
            _TCCounter.increment();
            _safeMint(msg.sender, _TCCounter.current());
        }
    }
    // Hall of Fame Presale
    function mintPresaleHOF(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= HOF_PRICE * _quantity, "Not enough ether sent.");
        require((2*_quantity) + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PRESALE_ACTIVE, "Presale is not yet live.");
        require(_HOFCounter.current() < HOF_PRESALE_SUPPLY, "Whitelist is sold out for this member type.");
        if(_quantity > 1){
            require(_HOFCounter.current() + _quantity < HOF_PRESALE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _HOFCounter.increment();
            uint256 tokenCounter = _HOFCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY;
            _safeMint(msg.sender, tokenCounter);
            MINTED_BALANCE[msg.sender]++;
            _HOFCounter.increment();
            tokenCounter += 1;  
            _safeMint(msg.sender, tokenCounter);
        }
    }
    
    // MVP Presale
    function mintPresaleMVP(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= MVP_PRICE * _quantity, "Not enough ether sent.");
        require((2*_quantity) + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PRESALE_ACTIVE, "Presale is not yet live.");
        require(_MVPCounter.current() < MVP_PRESALE_SUPPLY, "Whitelist is sold out for this member type.");
        if(_quantity > 1){
            require(_MVPCounter.current() + _quantity < MVP_PRESALE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _MVPCounter.increment();
            uint256 tokenCounter = _MVPCounter.current()+ TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY + HOF_RESERVE_SUPPLY; 
            _safeMint(msg.sender, tokenCounter);
            MINTED_BALANCE[msg.sender]++;
            _MVPCounter.increment();
            tokenCounter += 1; 
            _safeMint(msg.sender, tokenCounter);   
        }
    }

    /* --------- PUBLIC SALE MINT FUNCTIONS ------------- */

    // Triple Crown Public Sale
    function mintPublicTC(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= TC_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PUBLIC_SALE_ACTIVE, "Public mint is not yet live.");
        require(_TCCounter.current() < TC_MAX_SUPPLY, "Public mint is sold out for this member type.");
        if(_quantity > 1){
            require(_TCCounter.current() + _quantity < TC_MAX_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _TCCounter.increment();  
            _safeMint(msg.sender, _TCCounter.current());
        }
    }
    
    // Hall of Fame Public Sale
    function mintPublicHOF(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= HOF_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PUBLIC_SALE_ACTIVE, "Public mint is not yet live.");
        require(_HOFCounter.current() < HOF_MAX_SUPPLY, "Public mint is sold out for this member type.");
        if(_quantity > 1){
            require(_HOFCounter.current() + _quantity < HOF_MAX_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _HOFCounter.increment();
            _safeMint(msg.sender, _HOFCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY);  
        }
    }
    
    // MVP Public Sale
    function mintPublicMVP(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= MVP_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(PUBLIC_SALE_ACTIVE, "Public mint is not yet live.");
        require(_MVPCounter.current() < MVP_MAX_SUPPLY, "Public mint is sold out for this member type.");
        if(_quantity > 1){
            require(_MVPCounter.current() + _quantity < MVP_MAX_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _MVPCounter.increment();
            _safeMint(msg.sender, _MVPCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY + HOF_RESERVE_SUPPLY);
        }
    }
    
    /* --------- PUBLIC RESERVE MINT FUNCTIONS ------------- */

    // Triple Crown Reserve 
    function mintReserveTC(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= TC_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(RESERVE_SALE_ACTIVE, "Reserve mint is not live.");
        require(_TCReserveCounter.current() < TC_RESERVE_SUPPLY, "This member type has no more reserves.");
        if(_quantity > 1){
            require(_TCReserveCounter.current() + _quantity < TC_RESERVE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _TCReserveCounter.increment();
            _safeMint(msg.sender, _TCReserveCounter.current() + TC_MAX_SUPPLY);
        }
    }

    // Hall of Fame Reserve 
    function mintReserveHOF(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= HOF_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(RESERVE_SALE_ACTIVE, "Reserve mint is not live.");
        require(_HOFReserveCounter.current() < HOF_RESERVE_SUPPLY, "This member type has no more reserves.");
        if(_quantity > 1){
            require(_HOFReserveCounter.current() + _quantity < HOF_RESERVE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _HOFReserveCounter.increment();
            _safeMint(msg.sender, _HOFReserveCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY);
        }
    }

    // MVP Reserve 
    function mintReserveMVP(uint8 _quantity) public payable {
        require(_quantity > 0, "You must purchase at least one membership.");
        require(msg.value >= MVP_PRICE * _quantity, "Not enough ether sent.");
        require(_quantity + MINTED_BALANCE[msg.sender] <= MAX_MINT_PER_WALLET, "Maximum tokens per wallet exceeded.");
        require(RESERVE_SALE_ACTIVE, "Reserve mint is not live.");
        require(_MVPReserveCounter.current() < MVP_RESERVE_SUPPLY, "This member type has no more reserves.");
        if(_quantity > 1){
            require(_MVPReserveCounter.current() + _quantity < MVP_RESERVE_SUPPLY, "Not enough memberships available, lower the quantity");
        }
        for (uint i = 0; i < _quantity; i++) {
            MINTED_BALANCE[msg.sender]++;
            _MVPReserveCounter.increment();
            _safeMint(msg.sender, _MVPReserveCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY + HOF_RESERVE_SUPPLY + MVP_MAX_SUPPLY);
        }
    }

            
    // RESERVE MINT FUNCTIONS //
    function reserveMVPMint(address to) public onlyOwner {
        require(_MVPReserveCounter.current() < MVP_RESERVE_SUPPLY, "This member type has no more reserves.");
        _MVPReserveCounter.increment();
        _safeMint(to, _MVPReserveCounter.current() +  TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY + HOF_RESERVE_SUPPLY + MVP_MAX_SUPPLY);
    }
    function reserveHOFMint(address to) public onlyOwner {
        require(_HOFReserveCounter.current() < HOF_RESERVE_SUPPLY, "This member type has no more reserves.");
        _HOFReserveCounter.increment();
        _safeMint(to, _HOFReserveCounter.current() + TC_MAX_SUPPLY + TC_RESERVE_SUPPLY + HOF_MAX_SUPPLY);    
     
    }
    function reserveTCMint(address to) public onlyOwner {
        require(_TCReserveCounter.current() < TC_RESERVE_SUPPLY, "This member type has no more reserves.");
        _TCReserveCounter.increment();
        _safeMint(to, _TCReserveCounter.current()  + TC_MAX_SUPPLY);
        
    }  
         
    // SEND FUNDS TO PaymentSplitter CONTRACT //
    function withdraw() public onlyOwner{
        require(address(this).balance > 0, "Balance is 0.");
        (bool success,) = payable(payments).call{value: address(this).balance}("");
        require (success);
    }

    // STATE HANDLING //
    function toggleWhitelist() external onlyOwner{
        PRESALE_ACTIVE = !PRESALE_ACTIVE;
    }
    function togglePublicSale() external onlyOwner{
        PUBLIC_SALE_ACTIVE = !PUBLIC_SALE_ACTIVE;
    }
    function toggleReserveSale() external onlyOwner{
        RESERVE_SALE_ACTIVE = !RESERVE_SALE_ACTIVE;
    }

    // URI HANDLING //
    function baseTokenURI() public view returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }
    
    // Override tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(customBaseURI, tokenId.toString(), ".json")) : "";
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}