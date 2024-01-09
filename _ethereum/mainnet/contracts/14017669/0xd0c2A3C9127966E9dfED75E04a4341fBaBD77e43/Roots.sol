//SPDX-License-Identifier: Unlicense
/// @title: Roots by Sam King
/// @author: Sam King (samking.eth)

/**          

      `7MM"""Mq.                     mm           
        MM   `MM.                    MM           
        MM   ,M9  ,pW"Wq.   ,pW"Wq.mmMMmm ,pP"Ybd 
        MMmmdM9  6W'   `Wb 6W'   `Wb MM   8I   `" 
        MM  YM.  8M     M8 8M     M8 MM   `YMMMa. 
        MM   `Mb.YA.   ,A9 YA.   ,A9 MM   L.   I8 
      .JMML. .JMM.`Ybmd9'   `Ybmd9'  `MbmoM9mmmP' 
            
      https://roots.samking.photo

*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Roots is ERC721, Ownable {
    // samkingstudio.eth by default, but can be updated later
    address private _royaltyReceiver = 0x71b90C1AE3FB19aA2f8cB1e4fd3f062A0642116C;

    uint256 public price = 0.1 ether;
    string private _baseTokenURI;

    error IncorrectPaymentAmount();
    error InvalidTokenId();
    error NotAuthorized();
    error TransferFailed();

    constructor(string memory baseTokenURI) ERC721("Roots by Sam King", "ROOTS") {
        _baseTokenURI = baseTokenURI;
    }

    function mint(uint256 tokenId) public payable {
        if (tokenId == 0 || tokenId > 40) revert InvalidTokenId();
        if (price != msg.value) revert IncorrectPaymentAmount();
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) public {
        if (ownerOf[tokenId] != msg.sender) revert NotAuthorized();
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf[tokenId] == address(0)) revert InvalidTokenId();
        return string(abi.encodePacked(_baseTokenURI, toString(tokenId)));
    }

    function withdrawAvailableBalance() public payable onlyOwner {
        uint256 bal = address(this).balance;
        (bool success, ) = msg.sender.call{value: bal}(new bytes(0));
        if (!success) revert TransferFailed();
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * 500) / 10_000; // 5% royalty
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function updateRoyaltyReceiver(address receiver) public onlyOwner {
        _royaltyReceiver = receiver;
    }

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
