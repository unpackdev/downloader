pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract Starchain is ERC721PresetMinterPauserAutoId {
    
    using Strings for uint256;
   
    uint16 public maxSupply = 11111;
    uint256 public price = 70000000000000000; // start at 0.07ETH
    address payable account1 = payable(0x551E0713059896774721025e9953FCBE073AB4cE); // amun-ra
    address payable account2 = payable(0x221728354433C8329481c9CB413fBAE7A0F6C6d3); // cybersage
    address payable account3 = payable(0x3258E64Cf0C51BA9099472c2ADc8D83Fa13831D9); // lazerhawk5000
    string URIRoot = "https://starchainnft.mypinata.cloud/ipfs/QmXz7v5cB1gJ1pZtxj4sQeHdTeWZfHxRQm5XbWAZdvhnq8/";
   
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Starchain PFP", "SCPFP", URIRoot) {
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }
    
    function updateURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function buy(uint pack) payable external {
        
        // single
        if (pack == 0) {
            uint256 p = (price);
            require(msg.value >= p, "Not enough ETH.");
            mintNFT(1);
        }
        
        // pack
        else if (pack == 1) {
            uint256 p = (price * 5);
            require(msg.value >= p, "Not enough ETH.");
            mintNFT(5);
        }
        
        // whalepack
        else if (pack == 2) {
            uint256 p = (price * 30);
            require(msg.value >= p, "Not enough ETH.");
            mintNFT(30);
        }
        payAccounts();
    }
    
    function mintNFT(uint16 amount)
    private
    {
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require((totalMinted + amount) <= maxSupply, "Sold out.");
        
        for (uint i = 0; i < amount; i++) { 
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    
    function mintAirdrop() public {
        uint16 amount = 80;
        uint256 totalMinted = totalSupply();
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        require((totalMinted + amount) <= maxSupply, "Sold out.");
        for (uint i = 0; i < amount; i++) { 
            _mint(account2, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(URIRoot, tokenId.toString())) : "";
    }
    
    // send contract balance to addresses 1 and 2
    function payAccounts() public payable {
        uint256 balance = address(this).balance;
        if (balance != 0) {
            account1.transfer((balance * 33 / 100));
            account2.transfer((balance * 33 / 100));
            account3.transfer(balance * 33 / 100);
        }
    }
}