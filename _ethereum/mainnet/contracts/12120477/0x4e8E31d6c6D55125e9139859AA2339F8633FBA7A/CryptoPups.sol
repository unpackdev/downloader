pragma solidity ^0.5.0;
import "./ERC721Full.sol";
import "./ERC721MetadataMintable.sol";

contract CryptoPup is ERC721Full, ERC721MetadataMintable {
   
    uint16 public maxSupply = 1014;
    bool genesisMinted = false;
    uint256 public currentPuppyPrice = 50000000000000000; // start at 0.05 ETH
    address payable account1 = 0xEf04cA3341734A8617AF4D3a2e6198a4Ed9aD69F;
    address payable account2 = 0x2762CE5910e7E61082CCA249619ba2682fc7c4bf;
   
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721Full("CryptoPups Gen 0", "PUP") public {
    }
    
    // mint genesis puppies
    function mintGenesis(address recipient)
    public
    returns (uint256)
    {
        require(genesisMinted == false, "Genesis pups already minted.");
        uint i=0;
        for (i = 0; i <= 14; i++) { 
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(recipient, newItemId);
            _setTokenURI(newItemId, currentPupURI());       
        }
        genesisMinted = true;
    }
    
    // update pup price
    function updatePupPrice() private {
        uint256 totalMinted = totalSupply();
        if (totalMinted > 0 && totalMinted <= 250) {
            currentPuppyPrice = 50000000000000000;
        }
        else if (totalMinted > 250 && totalMinted <= 500) {
            currentPuppyPrice = 100000000000000000;
        }
        else if (totalMinted > 500 && totalMinted <= 750) {
            currentPuppyPrice = 150000000000000000;
        }
        else {
            currentPuppyPrice = 200000000000000000;
        }
    }
    
    // buy a pup
    function deposit(address recipient, bool pack) payable external {
        
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require(totalMinted < maxSupply, "Puppies sold out.");
        
        if (pack) {
            uint256 packPrice = (currentPuppyPrice * 4);
            require(msg.value >= packPrice, "Puppy price changed.");
            mintPupPack(recipient);
        }
        else if (!pack && msg.value >= currentPuppyPrice) {
            uint256 singlePrice = (currentPuppyPrice);
            require(msg.value >= singlePrice, "Puppy price changed");
            mintPup(recipient);
        }
        payAccounts();
        updatePupPrice(); 
    }
    
    // mint a puppy pack of 5 puppies
    function mintPupPack(address recipient)
    private
    returns (uint256)
    {
 
        // mint puppy pack
        uint i=0;
        for (i = 0; i < 5; i++) { 
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(recipient, newItemId);
            _setTokenURI(newItemId, currentPupURI());     
        }
    }
    
    // mint a puppy
    function mintPup(address recipient)
    private
    returns (uint256)
    {
        // require deposit more than or equal to current puppy price.
        // require(msg.value >= (currentPuppyPrice * 1));
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        
        _setTokenURI(newItemId, currentPupURI());
        
        return newItemId;
    }
    
    function currentPupURI() public returns (string memory) {
        string memory pupID = uint2str(_tokenIds.current());
        string memory processed = stringConcat("https://gateway.pinata.cloud/ipfs/QmVuMdFsY5EHTyFWXrGJXXczvZa9U8iEk9XdkimkTnUZbV/puppy_data/", pupID, ".json");
        return processed;
    }
    
    function stringConcat(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    // send contract balance to addresses 1 and 2
    function payAccounts() public {
        uint256 balance = address(this).balance;
        account1.transfer((balance * 70 / 100));
        account2.transfer((balance * 30 / 100));
    }
}
