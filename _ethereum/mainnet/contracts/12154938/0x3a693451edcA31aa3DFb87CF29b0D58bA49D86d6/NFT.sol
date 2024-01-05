// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IArtSquares.sol";

/**
 *
 * Gallery0 ArtSquares (ARTSQ) Contract
 * Based on HashMasks HashMasks Contract (HM)
 * @dev Extends standard ERC721 contract
 */
contract ArtSquares is ERC721, IArtSquares, Ownable {
  using SafeMath for uint256;
  using Address for address;

  // ArtSquares Enhancement Token address
  address private _g0Address;

  constructor(address g0Address) ERC721("ArtSquares by Gallery0", "ARTSQ") {
      _g0Address = g0Address;
      setBaseURI("https://artsquares.gallery0.org/token/");
  }

  string public constant ARTSQUARES_PROVENANCE = "c8d6a0d83bb9ac7ab60a040fcada134e1e6ac5000ff8e6059acd49d89ea029bf";
  uint256 public constant SALE_START_TIMESTAMP = 1617298740;
  uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (60 * 60 * 24 * 14);
  uint256 public constant MAX_TOKEN_SUPPLY = 15000;
  uint256 public constant NAME_CHANGE_PRICE = 1000 * (10 ** 18);
  uint256 public constant POSITION_CHANGE_PRICE = 500 * (10 ** 18);
  uint256 public constant MAX_POS_X = 220;
  uint256 public constant MAX_POS_Y = 110;
  uint256 public constant MAX_POS_Z = 50;

  // Mapping from token ID to whether the ArtSquare was minted before reveal.
  mapping (uint256 => bool) private _mintedBeforeReveal;

  // Mapping from token ID to name
  mapping (uint256 => string) private _tokenName;

  // Mapping if certain name string has already been reserved
  mapping (string => bool) private _nameReserved;

  // Mapping from token ID to its position vector
  mapping (uint256 => uint256[3]) private _tokenPosition;

  // Mapping from position string to token ID
  mapping (string => bool) private _positionReserved;

  // The block in which the starting index was created.
  uint256 public startingIndexBlock;

  // The index of the item that will become index 1
  uint256 public startingIndex;

  event NameChange (uint256 indexed artSquaresIndex, string newName);
  event PositionChange (uint256 indexed artSquaresIndex, uint256[3] newPosition);

  /**
    * @dev Gets current Artwork Price
    */
  function getNFTPrice() public view returns (uint256) {
    require(block.timestamp >= SALE_START_TIMESTAMP, "Sale not started");
    require(totalSupply() < MAX_TOKEN_SUPPLY, "Sale ended");

    uint currentSupply = totalSupply();

    if (currentSupply >= 13000) {
        return 500000000000000000;  // 13000 - 14999 0.5 ETH
    } else if (currentSupply >= 11000) {
        return 400000000000000000;  // 11000 - 12999 0.4 ETH
    } else if (currentSupply >= 9000) {
        return 300000000000000000;  // 9000 - 10999 0.3 ETH
    } else if (currentSupply >= 7000) {
        return 200000000000000000;  // 7000 - 8999 0.2 ETH
    } else if (currentSupply >= 5000) {
        return 100000000000000000;  // 5000 - 6999 0.1 ETH
    } else if (currentSupply >= 3000) {
        return 80000000000000000;   // 3000 - 4999 0.08 ETH
    } else if (currentSupply >= 1000) {
        return 70000000000000000;   // 1000  - 2999 0.07 ETH
    } else if (currentSupply >= 150) {
        return 50000000000000000;   // 150 - 999 0.05 ETH 
    } else
        return 20000000000000000;   // 0 - 149 0.02 ETH 
  }


  /**
  * @dev Gets max amount of NFTs in a single transaction
  */
  function getArtSquaresMaxAmount() public view returns (uint256) {
      require(block.timestamp >= SALE_START_TIMESTAMP, "Sale not started");
      require(totalSupply() < MAX_TOKEN_SUPPLY, "Sale has already ended");

      uint currentSupply = totalSupply();
      
      if (currentSupply >= 5000) {
          return 20;
      } else if (currentSupply >= 150) {
          return 10;
      } else
          return 2;
  }

  /**
  * @dev Mints ArtSquares
  */
  function mintNFT(uint256 numberOfNfts) public payable {
    require(totalSupply() < MAX_TOKEN_SUPPLY, "Sale has already ended");
    require(numberOfNfts > 0, "numberOfNfts cannot be 0");
    require(numberOfNfts <= getArtSquaresMaxAmount(), "You are not allowed to buy that many ArtSquares in the current Pricing Tier");
    require(totalSupply().add(numberOfNfts) <= MAX_TOKEN_SUPPLY, "Exceeds MAX_TOKEN_SUPPLY");
    require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

    for (uint i = 0; i < numberOfNfts; i++) {
      uint mintIndex = totalSupply();
      if (block.timestamp < REVEAL_TIMESTAMP) {
          _mintedBeforeReveal[mintIndex] = true;
      }
      _safeMint(msg.sender, mintIndex);
    }

    /**
    * Source of randomness for starting Index
    */
    if (startingIndexBlock == 0 && (totalSupply() == MAX_TOKEN_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
      startingIndexBlock = block.number;
    }
  }

  /**
  * @dev Returns if the Artsquare was minted before reveal phase.
  */
  function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
      return _mintedBeforeReveal[index];
  }

  /**
    * @dev Withdraw ether from this contract (Callable by owner)
  */
  function withdraw() onlyOwner public {
      uint balance = address(this).balance;
      msg.sender.transfer(balance);
  }

  function setBaseURI(string memory baseURI_) onlyOwner public {
      _setBaseURI(baseURI_);
  }

  /**
    * @dev Finalize starting index
    */
  function finalizeStartingIndex() public {
      require(startingIndex == 0, "Starting index is already set");
      require(startingIndexBlock != 0, "Starting index block must be set");
      
      startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKEN_SUPPLY;
      // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
      if (block.number.sub(startingIndexBlock) > 255) {
          startingIndex = uint(blockhash(block.number-1)) % MAX_TOKEN_SUPPLY;
      }
      // Prevent default sequence
      if (startingIndex == 0) {
          startingIndex = startingIndex.add(1);
      }
  }

  /**
    * @dev Changes the name for ArtSquares tokenId
    */
  function changeName(uint256 tokenId, string memory newName) public {
      address owner = ownerOf(tokenId);

      require(_msgSender() == owner, "ERC721: caller is not the owner");
      require(validateName(newName) == true, "Not a valid new name");
      require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
      require(isNameReserved(newName) == false, "Name already reserved");

      IERC20(_g0Address).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);
      // If already named, dereserve old name
      if (bytes(_tokenName[tokenId]).length > 0) {
          toggleReserveName(_tokenName[tokenId], false);
      }
      toggleReserveName(newName, true);
      _tokenName[tokenId] = newName;
      IERC20(_g0Address).burn(NAME_CHANGE_PRICE);
      emit NameChange(tokenId, newName);
  }

  /**
    * @dev Converts the string to lowercase
    */
  function toLower(string memory str) public pure returns (string memory) {
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
          // Uppercase character
          if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
              bLower[i] = bytes1(uint8(bStr[i]) + 32);
          } else {
              bLower[i] = bStr[i];
          }
      }
      return string(bLower);
  }

  /**
    * @dev Returns if the name has been reserved.
    */
  function isNameReserved(string memory nameString) public view returns (bool) {
      return _nameReserved[toLower(nameString)];
  }

  /**
    * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
    */
  function toggleReserveName(string memory str, bool isReserve) internal {
      _nameReserved[toLower(str)] = isReserve;
  }

  /**
    * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    */
  function validateName(string memory str) public pure returns (bool) {
      bytes memory b = bytes(str);
      if(b.length < 1) return false;
      if(b.length > 25) return false; // Cannot be longer than 25 characters
      if(b[0] == 0x20) return false; // Leading space
      if (b[b.length - 1] == 0x20) return false; // Trailing space

      bytes1 lastChar = b[0];

      for(uint i; i<b.length; i++){
          bytes1 char = b[i];

          if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

          if(
              !(char >= 0x30 && char <= 0x39) && //9-0
              !(char >= 0x41 && char <= 0x5A) && //A-Z
              !(char >= 0x61 && char <= 0x7A) && //a-z
              !(char == 0x20) //space
          )
              return false;

          lastChar = char;
      }

      return true;
  }

  /**
  * @dev Changes the position for ArtSquares in Gallery0
  */
  function changePosition(uint256 tokenId, uint256 posX, uint256 posY, uint256 posZ) public {
      address owner = ownerOf(tokenId);

      require(_msgSender() == owner, "ERC721: caller is not the owner");
      require(posX < MAX_POS_X, "posX is too large");
      require(posY < MAX_POS_Y, "posY is too large");
      require(posZ < MAX_POS_Z, "posZ is too large");

      string memory posXStr = uint2str(posX);
      string memory posYStr = uint2str(posY);
      string memory posZStr = uint2str(posZ);

      string memory posStr = string(abi.encodePacked(posXStr, ",", posYStr, ",", posZStr));

      require(isPositionReserved(posStr) == false, "Position already taken");

      string memory oldPosStr;

      // check if position is already set
      if (_tokenPosition[tokenId].length == 3) {
          string memory oldPosXStr = uint2str(_tokenPosition[tokenId][0]);
          string memory oldPosYStr = uint2str(_tokenPosition[tokenId][1]);
          string memory oldPosZStr = uint2str(_tokenPosition[tokenId][2]);

          oldPosStr = string(abi.encodePacked(oldPosXStr, ",", oldPosYStr, ",", oldPosZStr));
      }

      IERC20(_g0Address).transferFrom(msg.sender, address(this), POSITION_CHANGE_PRICE);
      // If already reserved, dereserve old name
      if (bytes(oldPosStr).length > 0) {
          unreservePosition(oldPosStr);
      }

      uint256[3] memory newPosition = [posX, posY, posZ];

      setReservePosition(posStr);
      _tokenPosition[tokenId] = newPosition;
      IERC20(_g0Address).burn(POSITION_CHANGE_PRICE);
      emit PositionChange(tokenId, newPosition);
  }

  /**
    * @dev Returns if the Position has been reserved.
    */
  function isPositionReserved(string memory positionString) public view returns (bool) {
      return _positionReserved[toLower(positionString)];
  }

  /**
    * @dev Reserves the Position if isReserve is set to true, de-reserves if set to false
    */
  function setReservePosition(string memory positionString) internal {
      _positionReserved[toLower(positionString)] = true;
  }

  /**
    * @dev Reserves the Position if isReserve is set to true, de-reserves if set to false
    */
  function unreservePosition(string memory positionString) internal {
      delete _positionReserved[toLower(positionString)];
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint256 j = _i;
      uint256 len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint256 k = len - 1;
      while (_i != 0) {
          bstr[k--] = byte(uint8(48 + _i % 10));
          _i /= 10;
      }
      return string(bstr);
  }

}