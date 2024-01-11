// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract StarryBoki is ERC721A, Ownable {

    string public baseURI = "ipfs://QmQVnjsA7XBJyWpLZJuT1xQHhXsyUtaBXsQPRSvSWTHtka/";
    string public constant baseExtension = ".json";

    uint256 public constant MAX_PER_WALLET_FREE = 2;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public price = 0.003 ether;

    bool public paused = false;
    bool public start = false;

    constructor() ERC721A("StarryBoki", "STABOKI") {}
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(start, "Not live!");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
        
        if(_numberMinted(msg.sender) >= MAX_PER_WALLET_FREE) {
            require(msg.value >= _amount * price, "Invalid funds provided");
        } else{
            uint count = _numberMinted(msg.sender) + _amount;
            if(count > MAX_PER_WALLET_FREE){
                require(msg.value >= (count - MAX_PER_WALLET_FREE) * price , "Insufficient funds");
            } 
        }
        _safeMint(_caller, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function config() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setStart(bool _state) external onlyOwner {
        start = _state;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}