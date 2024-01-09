// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SeoulApes is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    
    bool public saleIsActive = false;
    bool public isRevealed = false;
    bool public canMintFree = true;

    string private _baseURIextended;

    mapping (uint256 => string) private _specialEditionTokenURI;

    uint256 public NUM_FREE_MINT = 555;
    uint256 public numSpecialEditions;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_FREE_MINT = 2;
    uint256 public constant PRICE_PER_TOKEN = 0.02 ether;

    constructor() ERC721("Seoul Apes", "SAPES") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (!isRevealed) {
            return "";
        } 
        
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            string memory base = _baseURI();
            
            if (!isRevealed) {
                string memory uri_start = "{\"description\": \"Seoul Apes is a collection of 5555 unique cyberpunk apes, inspired by the dazzling city nightscape of Seoul, Korea. By owning a Seoul Ape, members are granted access to vote on how they want their Seoul experience to look - funded by the Seoul Ape Community Treasury. See you in Seoul!\", \"image\": \"ipfs://QmVZUYNrpwGkaUEq9XVbdKFWT8AJpg2sz7sopXb6bjyCXe\", \"name\": \"Seoul Ape #";
                string memory uri_end = "\", \"attributes\": [{\"trait_type\": \"Status\", \"value\": \"Unrevealed\"}]}";
                string memory metadata = string(abi.encodePacked(uri_start, tokenId.toString(),uri_end));

                return string(abi.encodePacked("data:application/json;base64, ", base64(bytes(metadata))));
            } else if (tokenId >= MAX_SUPPLY) {
                return _specialEditionTokenURI[tokenId];
            }
            
            return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mintSpecialEdition(string memory uri) public onlyOwner {
      uint tokenId = MAX_SUPPLY + numSpecialEditions;
      _specialEditionTokenURI[tokenId] = uri;
      numSpecialEditions += 1;
      _safeMint(msg.sender, tokenId);

    }

    function updateSpecialEditionMetadata(uint256 tokenId, string memory uri) public onlyOwner {
        _specialEditionTokenURI[tokenId] = uri;
    }


    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setRevealedState(bool newState) public onlyOwner {
        isRevealed = newState;
    }
    
    function canMintFreeState(bool newState) public onlyOwner {
        canMintFree = newState;
    }

    function increaseFreeMint(uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens > NUM_FREE_MINT, "Can only increase");
        NUM_FREE_MINT = numberOfTokens;
    }


    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function mintFree(uint numberOfTokens) public {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_FREE_MINT, "Exceeded max token purchase");
        require(canMintFree, "Free Mint no longer active");

        if  (ts + numberOfTokens > NUM_FREE_MINT) {
            canMintFree = false;
            _safeMint(msg.sender, ts);
        } else {
            for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }

        }
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


  /** BASE 64 - Written by Brech Devos */
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }
}