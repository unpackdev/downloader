// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NftySanta is ERC721, IERC721Receiver, ERC721Holder, Ownable  {

    struct Present {
        IERC721 tokenAddress;
        uint256 tokenID;
        string message;
        address recipient;
    }

    // Counter for token IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDs;

    mapping(uint256 => Present) private _presents;
    mapping(address => bool) private _niceList;

    string private _baseTokenURI;
    uint private _unixChristmas;
    uint private _presentPrice;

    // Events
    event PresentSent(uint256 tokenId);
    event PresentUnwrapped(address tokenAddress, uint256 tokenId, string message);

    constructor(string memory baseTokenURI, uint unixChristmas, uint presentPrice) ERC721("NftySanta", "SANTA") {
        setBaseTokenURI(baseTokenURI);
        setUnixChristmas(unixChristmas);
        setPresentPrice(presentPrice);
    }

    function unwrap(uint256 tokenID) public {
        require(_exists(tokenID), "Present does not exist or has been unwrapped already");
        Present memory present = _presents[tokenID];
        require(present.recipient == msg.sender, "This isn't your present buddy");
        require(block.timestamp >= _unixChristmas, "Not Christmas yet!");

        _burn(tokenID);
        delete _presents[tokenID];
        present.tokenAddress.safeTransferFrom(address(this), present.recipient, present.tokenID);

        emit PresentUnwrapped(address(present.tokenAddress), present.tokenID, present.message);
    }

     /**
     * @dev Main minting/ wrapping function.
     */
    function sendPresent(IERC721 giftedTokenAddress, uint256 giftedTokenId, string memory message, address recipient) public payable {
        // Can only send presents before or on christmas day
        require(block.timestamp < _unixChristmas + 86400, "Christmas is over, wait till next year");
        
        uint mintPrice = isOnNiceList() ? 0 : _presentPrice;
        require(msg.value == mintPrice, "Incorrect ETH sent");

        // We add 1 so that IDs start from 1 and not 0.
        uint256 tokenID = _tokenIDs.current() + 1;
        giftedTokenAddress.safeTransferFrom(msg.sender, address(this), giftedTokenId);
        _presents[tokenID] = Present(giftedTokenAddress, giftedTokenId, message, recipient);
        _safeMint(recipient, tokenID);
        _tokenIDs.increment();

        emit PresentSent(tokenID);
    }

    function isOnNiceList() public view returns (bool) {
        return _niceList[msg.sender];
    }

    function getPresentPrice() public view returns (uint) {
        return _presentPrice;
    }

    function getUnixChristmas() public view returns (uint) {
        return _unixChristmas;
    }

    // onlyOwner ---------------------------

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    } 

    function setUnixChristmas(uint unixChristmas) public onlyOwner {
        _unixChristmas = unixChristmas;
    } 

    function setPresentPrice(uint presentPrice) public onlyOwner {
        _presentPrice = presentPrice;
    } 

    function addToNiceList(address[] memory niceAddresses) public onlyOwner {
        uint256 arrayLength = niceAddresses.length;
        for (uint256 i=0; i < arrayLength; i++) {
            address niceAddress = niceAddresses[i];
            _niceList[niceAddress] = true;
        }

    }

    function removeFromNiceList(address naughtyAddr) public onlyOwner {
        _niceList[naughtyAddr] = false;
    }

    function withdraw(address withdrawAddress) public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    // internal overrides ---------------------------

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If token is being transferred and not minted or burned
        if (from != to && from != address(0) && to != address(0)) {
            _presents[tokenId].recipient = to;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _baseTokenURI;
    }

}
