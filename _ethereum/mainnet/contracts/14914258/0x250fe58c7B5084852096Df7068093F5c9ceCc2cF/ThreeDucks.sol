
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ThreeDucks is ERC721A, Ownable {

    string public baseURI = "ipfs://QmaJ5jGj7A2xmAKtejKDUiCaUN1zh5iCUXE8ZwWx9xmgJA/";
    string public constant baseExtension = ".json";
    uint256 public constant MAX_PER_ADDR_FREE = 1;
    uint256 public constant MAX_PER_TRX = 10;
    uint256 public MAX_DUCKS = 4333;
    uint256 public PRICE = 0.004 ether;
    bool public _stop = false;
    bool public duck = false;

    constructor() ERC721A("ThreeDucks", "TDUCK") {}

    function quack(uint256 _amount) external payable {
        require(!_stop, "STOP!");
        require(duck, "Not Duck Yet!");
        require(_amount > 0 && _amount <= MAX_PER_TRX,"Too many ducks!");
        require(totalSupply() + _amount <= MAX_DUCKS,"No More Ducks!");

        if(_numberMinted(msg.sender) > 0) {
            require(msg.value >= _amount * PRICE, "Poor guy detected!");
        } else{
            require(msg.value >= (_amount - MAX_PER_ADDR_FREE) * PRICE , "Poor guy detected!");
        }
        _safeMint(_msgSender(), _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner {
        uint256 total = totalSupply();
        require(total + _amount <= MAX_DUCKS, "No More Ducks!");
        _safeMint(_to, _amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function master() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function stop(bool _state) external onlyOwner {
        _stop = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function duckyou(bool _state) external onlyOwner {
        duck = _state;
    }

    function setPrice(uint newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function getPrice() external view returns (uint256){
        return PRICE;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}