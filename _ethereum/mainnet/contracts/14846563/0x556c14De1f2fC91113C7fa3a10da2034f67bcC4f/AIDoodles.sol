// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AIDoodles is ERC721A, Ownable {

    string public baseURI = "ipfs://QmQ2EzJs36M7iK12qyiYpLX3eCAjYq9xnSevS9ayfvMZ7h";
    string public constant baseExtension = ".json";

    uint256 public constant MAX_PER_TX_FREE = 5;
    uint256 public constant FREE_MAX_SUPPLY = 1000;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public MAX_SUPPLY = 6000;
    uint256 public price = 0.003 ether;

    bool public paused = false;
    bool public start = false;

    constructor() ERC721A("AIDoodles", "AIDDL") {}

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(start, "Not live!");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
        
      if(FREE_MAX_SUPPLY >= totalSupply()){
            require(MAX_PER_TX_FREE >= _amount , "Excess max per free tx");
        }else{
            require(MAX_PER_TX >= _amount , "Excess max per paid tx");
            require(_amount * price == msg.value, "Invalid funds provided");
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

    function setMAX_SUPPLY(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
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