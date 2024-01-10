//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./IERC721Receiver.sol";
import "./console.sol";

contract Wordle is ERC721, Ownable, IERC721Receiver {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  // TODO: update
  address public serverAddress = 0xFB9764a957ddE05Ec16ba3ad6f2F9232794F7f54;

  mapping(uint256 => uint256[8]) public gameHistories;
  mapping(uint256 => address) private _deposits;

  Counters.Counter private supply;

  uint256 public publicCost = .05 ether;
  uint256 public maxMintAmountPlusOne = 11;
  uint256 public maxSupplyPlusOne = 5001;

  bool public saleIsActive;

  address payable public immutable mAddress = payable(0x5A7AD550fe60453Bc967190398C20bd5C81dc596);

  constructor(address _serverAddress) ERC721("Web3Wordle", "W3RDL") {
    saleIsActive = false;
    serverAddress = _serverAddress;
    _mintLoop(0xc2f9bC67cc2a3695d5F581c3afCD19Bd65Cc4039, 101);
  }

  function depositTokens(uint256[] calldata tokenIds) external {
    setApprovalForAll(address(this), true);

    for (uint256 i; i < tokenIds.length; i++) {
        this.safeTransferFrom(
            msg.sender,
            address(this),
            tokenIds[i],
            ""
        ); 
        _deposits[tokenIds[i]] = msg.sender;
    }
  }

  function withdrawTokens(uint256[] calldata tokenIds) external {
    for (uint256 i; i < tokenIds.length; i++) {
      require(
          _deposits[tokenIds[i]] == msg.sender,
          "Staking: token not deposited"
      );

      this.safeTransferFrom(
          address(this),
          msg.sender,
          tokenIds[i],
          ""
      );
      _deposits[tokenIds[i]] = address(0);
    }
  }

  function ownerOfStaked(uint256 tokenId) external view returns(address) {
    require(_exists(tokenId), "must be for an existing nft");
    if (_deposits[tokenId] != address(0)) {
      return _deposits[tokenId];
    }
    return address(0);
  }

  function depositsOf(address account, bool onlyStaked)
    external 
    view 
    returns (uint256[] memory)
  {
    uint256[] memory tokenIdsOwned = new uint256[](totalSupply());
    uint256 index = 0;
    for (uint256 tokenid; tokenid <= totalSupply(); tokenid++) {
      if (onlyStaked) {
        if (_deposits[tokenid] == account) {
          tokenIdsOwned[index] = tokenid;
          index++;
        }
      } else {
        if (_exists(tokenid) && (ownerOf(tokenid) == account)) {
          tokenIdsOwned[index] = tokenid;
          index++;
        }
      }
    }

    uint256[] memory trimmedResult = new uint256[](index);
    for (uint j = 0; j < trimmedResult.length; j++) {
        trimmedResult[j] = tokenIdsOwned[j];
    }

    return trimmedResult;
  }

  function onERC721Received(
      address,
      address,
      uint256,
      bytes calldata
  ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
  }

  function updateScore(uint256 tokenId, bytes32 score, bytes memory ownerSig, bytes memory serverSig) public {
    require(_exists(tokenId), "must be for an existing nft");
    require(_deposits[tokenId] == msg.sender, "You have to stake this NFT!");

    require(score.toEthSignedMessageHash().recover(ownerSig) == msg.sender, "you did not sign this message");
    require(score.toEthSignedMessageHash().recover(serverSig) == serverAddress, "server did not sign this message");
    
    uint256 scoreSeqTemp = uint256(score);
    uint i = 0;
    uint256 nftId = 0;
    while (scoreSeqTemp > 1) {
      if (i == 0) {
        nftId = scoreSeqTemp % 1_000_000;
        require(nftId == tokenId, "you are attempting to update the wrong NFT!");
        scoreSeqTemp = scoreSeqTemp / 1_000_000;
      } else if (i == 1) {
        gameHistories[nftId][7] = scoreSeqTemp % 1_000_000;
        scoreSeqTemp = scoreSeqTemp / 1_000_000;
      } else if (i == 2) {
        gameHistories[nftId][6] = scoreSeqTemp % 1_000_000;
        scoreSeqTemp = scoreSeqTemp / 1_000_000;
      } else {
        gameHistories[nftId][8-i] = scoreSeqTemp % 1_000_000;
        scoreSeqTemp = scoreSeqTemp / 1_000_000;
      }
      i += 1;
    }
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function _scoreConcat(uint256 tokenId) internal view returns (string memory) {
    uint256[8] memory countsForGuesses = gameHistories[tokenId];
    return (string(abi.encodePacked(
      '{ "trait_type": "LongestStreak", "value": ',
      toString(countsForGuesses[7]),
      ' }, { "trait_type": "Losses", "value": ',
      toString(countsForGuesses[6]),
      ' }, { "display_type": "number", "trait_type": "1Try", "value": ',
      toString(countsForGuesses[0]),
      ' }, { "display_type": "number", "trait_type": "2Tries", "value": ',
      toString(countsForGuesses[1]),
      ' }, { "display_type": "number", "trait_type": "3Tries", "value": ', 
      toString(countsForGuesses[2]),
      ' }, { "display_type": "number", "trait_type": "4Tries", "value": ', 
      toString(countsForGuesses[3]),
      ' }, { "display_type": "number", "trait_type": "5Tries", "value": ', 
      toString(countsForGuesses[4]),
      ' }, { "display_type": "number", "trait_type": "6Tries", "value": ', 
      toString(countsForGuesses[5]),
      ' } ]'
    )));
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
      require(_exists(tokenId), "Token doesn't exist.");
      string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"Web3Wordl #',
      toString(tokenId),
        '","image":"https://ipfs.io/ipfs/QmbRwxoWigi6LX4jq7E5MDiVZNadEBq7uRgCX9Zc2Yzsiq","collection_name":"Web3Wordl","platform":"Web3Wordl","curation_status":"curated","series":"1","description":"Web3Wordl is an on-chain word game based on opensourced code. Play online to save your score here: https://w3w.lol/game/',
        toString(tokenId),
        '", "external_url":"https://w3w.lol/game/',
        toString(tokenId),
        '/","animation_url":"https://w3w.lol/game/',
        toString(tokenId),
        '","interactive_nft":{"code_uri":"https://w3w.lol/game/',
        toString(tokenId),
        '","version":"1.0"}, "attributes":[',
        _scoreConcat(tokenId),
        '}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
  }

  // TODO: update
  // function mint(uint256 _mintAmount) public {
  function mint(uint256 _mintAmount) public payable {
    require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
    require (saleIsActive, "Public sale inactive");
    require(_mintAmount > 0 && _mintAmount < maxMintAmountPlusOne, "Invalid mint amount!");
    require(supply.current() + _mintAmount < maxSupplyPlusOne, "Max supply exceeded!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setPublicCost(uint256 _newCost) public onlyOwner {
    publicCost = _newCost;
  }

  function lowerSupply(uint256 newSupply) public onlyOwner {
    maxSupplyPlusOne = newSupply;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      Address.sendValue(mAddress, balance);
      // Address.sendValue(mAddress, balance.mul(35).div(100));
      // Address.sendValue(bAddress, balance.mul(35).div(100));
      // Address.sendValue(nAddress, balance.mul(30).div(100));
  }
     /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);
        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}