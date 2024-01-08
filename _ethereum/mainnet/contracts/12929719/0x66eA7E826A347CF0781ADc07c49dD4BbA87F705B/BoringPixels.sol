pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License

// How boring can you get?
// Check https://www.boringpixels.com
//
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// XXXXXXXXXXXXXXXXXXKxc:::::::::::::::::::
// kkkkkkkkkkkkkkkkkkkdoooooooooooooooooooo
// ;;;;;;;;;;;;;;;;;;:d00KKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK
// ;;;;;;;;;;;;;;;;;;;d0KKKKKKKKKKKKKKKKKKK

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BoringPixels is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public fee;

    string public baseUri;

    event Minted(address to, uint id, string uri);

    event PriceUpdated(uint newPrice);

    constructor() ERC721("BoringPixels", "BPX") {
      fee = 10000000000000000 wei; //0.01 ETH
      baseUri = "ipfs://QmbGCimQVxo7kWsFXGQAeU2zoqcpsPfC5EGCsBrVzdWXNT/";
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

    /*
    * Mint BoringPixels
    */
    function mint(address player, uint numberOfMints)
        public payable
        returns (uint256)
    {
        require(_tokenIds.current() + numberOfMints <= 10000, "Maximum amount of tokens already minted.");
        require(msg.value >= fee * numberOfMints, "Fee is not correct.");  //User must pay set fee.

        for(uint i = 0; i < numberOfMints; i++) {

            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            string memory tokenURI = string(abi.encodePacked(baseUri, toString(newItemId),  ".json"));
            _mint(player, newItemId);
            _setTokenURI(newItemId, tokenURI);

            //removed Mint event here bc of gas intensity.
        }

        return _tokenIds.current();
    }

    function updateFee(uint newFee) public onlyOwner{
      fee = newFee;

      emit PriceUpdated(newFee);
    }

    function getFee() public view returns (uint) {
      return fee;
    }

    function cashOut() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }
}
