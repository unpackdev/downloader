// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";



pragma solidity ^0.8.7;


contract WickedBullyGoons is Ownable, ERC721A {
    uint256 public maxSupply   = 6000;
    uint256 public maxPerAddress     = 2;
    bool public isMetadataLocked = false;
    string private _baseTokenURI;
    bool public paused=true;

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("WickedBullyGoons", "WBG") {
               _safeMint(msg.sender, 45);

      
    }
modifier mintCompliance() {
        require(!paused, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

      function mint(uint256 _quantity) external mintCompliance()  {
        require(
            maxSupply >= totalSupply() + _quantity,
            "Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddress,
            "Exceeds max mints per address!"
        );

        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }



    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
              string memory baseURI = _baseURI();
              return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';

    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isMetadataLocked,"Metadata has been locked");
        _baseTokenURI = baseURI;
    }
        function burnSupply(uint256 _amount) public onlyOwner {
        maxSupply -= _amount;
    }


    function startSale() public onlyOwner {
        paused = !paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }  
    
   function contractURI() public view returns (string memory) {
        return "ipfs://QmULDnTXsB8LXmhJ38niwgmirdgeuXrLJNENbMgTFYmFKg";
    }

}