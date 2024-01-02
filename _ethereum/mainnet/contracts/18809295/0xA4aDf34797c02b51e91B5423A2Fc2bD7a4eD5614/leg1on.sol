// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface DystoPunks {
    function tokensOfOwner(address ownwer) external view returns (uint256[] memory);
}

interface EncodeGraphics {
    function tokensOfOwner(address ownwer) external view returns (uint256[] memory);
}

interface DystoPunksVX {
    function balanceOf(address ownwer) external view returns (uint256);
}
 
contract Legion is  Ownable, ERC721Enumerable {

    address constant public DystoAddress = 0xbEA8123277142dE42571f1fAc045225a1D347977;
    address constant public EncodeAddress = 0xCBA5AC55D5e1c56Cf16482456aD0a47f27D38a62;
    address constant public VXAddress = 0xf91523Bc0ffA151ABd971f1b11D2567d4167DB3E;

    uint constant TOKEN_PRICE = 0.07 ether;
    uint constant WL_TOKEN_PRICE = 0.05 ether;
    uint constant MAX_TOKENS = 7777;
    bool public hasSaleStarted = false;
    bool public hasPrivateSaleStarted = false;
    bool public stoped = false;
    mapping(uint => bool) public claimedDysto;
    mapping(uint => bool) public claimedKey;
    mapping(address => bool) private _allowList;
    mapping(address => bool) private _freeList;
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("LEG1ON","LEG1ON")  {
        setBaseURI(baseTokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function publicMint(uint num) public payable {
        require(totalSupply() < MAX_TOKENS, "Sale has already ended");
        require(stoped == false, "Sale is stoped");
        require(hasSaleStarted == true, "Sale has not already started");
        require(num < 8, "You can mint minimum 1, maximum 7");
        require(totalSupply() + num <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(msg.value >= TOKEN_PRICE * num, "Ether value sent is below the price");
        for (uint i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply());
        }

    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    function chekAllowMint(address addr) public view returns (bool) {
        return _allowList[addr];
    }

    function mintAllowList(uint num) public payable {
        require(stoped == false, "Sale is stoped");
        require(num < 8, "7 max tokens");
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(totalSupply() + num <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(msg.value >= WL_TOKEN_PRICE * num, "Ether value sent is below the price");
        require(_allowList[msg.sender] == true, "Not whitelisted");
        for (uint i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function checkDystoToClaim(uint id) public view returns (bool) {
         return claimedDysto[id];
    }
    

    function availableDystoToClaim(address ownwer) public view returns (uint[] memory) {
         uint[] memory punks = DystoPunks(DystoAddress).tokensOfOwner(ownwer);

         uint arrayPunksLength = punks.length;
         uint x=0;
         for (uint i=0; i<arrayPunksLength; i++) {
              uint256 id = punks[i];
              if (claimedDysto[id]==false) {
                  x++;
              }
         }
         uint[] memory tokensavAliable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayPunksLength; i++) {
              if (claimedDysto[punks[i]]==false) {
                  tokensavAliable[x]=punks[i];
                  x++;
              }
         }
         return tokensavAliable;
    }

    function DystoClaim(uint[] calldata ids) public {
        uint[] memory punks = availableDystoToClaim(msg.sender);
        uint arrayIdsLength = ids.length;
        uint arrayPunksLength = punks.length;
        require(arrayPunksLength >= 1, "Nothing to claim");
        require(hasPrivateSaleStarted == true, "Sale has not already started");
        bool mintdystos=true;
        for (uint i=0; i<arrayIdsLength; i++) {
              bool inArray=false;
              for (uint j=0; i<arrayPunksLength; j++) {
                  if (punks[j]==ids[i]) {
                       inArray=true;
                       break;
                  }
              }
              if (inArray==false) {
                  mintdystos=false;
              }
        }
        if (mintdystos) {
            for (uint i=0; i < arrayIdsLength; i++) {
                  _safeMint(msg.sender, totalSupply());
                  claimedDysto[ids[i]] = true;
            }
        }
    }

    function checkKeyClaim(uint id) public view returns (bool) {
         return claimedKey[id];
    }

    function availableKeyClaim(address ownwer) public view returns (uint[] memory) {
         uint[] memory keys = EncodeGraphics(EncodeAddress).tokensOfOwner(ownwer);

         uint arrayKeysLength = keys.length;
         uint x=0;
         for (uint i=0; i<arrayKeysLength; i++) {
              uint256 id = keys[i];
              if (claimedKey[id]==false) {
                  x++;
              }
         }
         uint[] memory tokensavAliable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayKeysLength; i++) {
              if (claimedKey[keys[i]]==false) {
                  tokensavAliable[x]=keys[i];
                  x++;
              }
         }
         return tokensavAliable;
    }

    function KeyClaim(uint[] calldata ids) public {
        uint[] memory keys = availableKeyClaim(msg.sender);
        uint arrayIdsLength = ids.length;
        uint arrayKeysLength = keys.length;
        require(arrayKeysLength >= 1, "Nothing to claim");
        require(hasPrivateSaleStarted == true, "Sale has not already started");
        bool mintkeys=true;
        for (uint i=0; i<arrayIdsLength; i++) {
              bool inArray=false;
              for (uint j=0; i<arrayKeysLength; j++) {
                  if (keys[j]==ids[i]) {
                       inArray=true;
                       break;
                  }
              }
              if (inArray==false) {
                  mintkeys=false;
              }
        }
        if (mintkeys) {
            for (uint i=0; i < arrayIdsLength; i++) {
                 if (ids[i]<51) {
                     _safeMint(msg.sender, totalSupply()); 
                     _safeMint(msg.sender, totalSupply()); 
                     _safeMint(msg.sender, totalSupply()); 
                     _safeMint(msg.sender, totalSupply()); 
                 } else if (ids[i]<451) {
                     _safeMint(msg.sender, totalSupply()); 
                     _safeMint(msg.sender, totalSupply()); 
                 } else if (ids[i]<1451) {
                     _safeMint(msg.sender, totalSupply()); 
                 }  
                 claimedKey[ids[i]] = true;
            }
            
        }
    }

    function checkVxToClaim() public view returns (bool) {
         uint256 vx = DystoPunksVX(VXAddress).balanceOf(msg.sender);
         if (vx > 0) {
            return true;
         } else {
            return false;
         }
         
    }

    function mintVXList(uint num) public payable {
        require(stoped == false, "Sale is stoped");
        uint256 vx = DystoPunksVX(VXAddress).balanceOf(msg.sender);
        require(num < 8, "7 max tokens");
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(totalSupply() + num <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(msg.value >= WL_TOKEN_PRICE * num, "Ether value sent is below the price");
        require(vx > 0, "Not whitelisted");
        for (uint i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply());
        }
       
    }

    function setFreeList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeList[addresses[i]] = true;
        }
    }

    function chekFreeMint(address addr) public view returns (bool) {
        return _freeList[addr];
    }

    function mintFreeList() public  {
        require(stoped == false, "Sale is stoped");
        require(hasPrivateSaleStarted == true, "Private sale has not already started");
        require(totalSupply() + 1 <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(_freeList[msg.sender] == true, "Not freelisted");
        _safeMint(msg.sender, totalSupply());
        _freeList[msg.sender] = false;
    }

    function reserveAirdrop(uint num, address addr) public onlyOwner {
        require(stoped == false, "Sale is stoped");
        require(totalSupply() < MAX_TOKENS, "Exceeds MAX_TOKENS");
        for (uint i = 0; i < num; i++) {
            _safeMint(addr, totalSupply());
        }

    }
    

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function startPrivateSale() public onlyOwner {
        hasPrivateSaleStarted = true;
    }

    function pausePrivateSale() public onlyOwner {
        hasPrivateSaleStarted = false;
    }

    function stopSale(uint num) public onlyOwner {
        require(num == 2077, "Invalid");
        stoped = true;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

}