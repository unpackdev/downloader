// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract PixelCatGroup is ERC721A, Ownable {

    string public baseURI = "ipfs://bafybeifwbiftoqy25io4qxkx2hegf2cdqm2pc3aue7uwv63nl5gasyc4te/";
    string public contractURI = "ipfs://bafybeifwbiftoqy25io4qxkx2hegf2cdqm2pc3aue7uwv63nl5gasyc4te/";
    string public constant baseExtension = ".json";

    uint256 public constant MAX_PER_TX_FREE = 2;
    uint256 public free_max_supply = 333;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public max_supply = 1111;
    uint256 public price = 0.005 ether;

    bool public paused = false;

    constructor() ERC721A("Pixel Cat Group", "PixelCat") {}

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(max_supply >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
        
      if(free_max_supply >= totalSupply()){
            require(MAX_PER_TX_FREE >= _amount , "Excess max per free tx");
        }else{
            require(MAX_PER_TX >= _amount , "Excess max per paid tx");
            require(_amount * price == msg.value, "Invalid funds provided");
        }


        _safeMint(_caller, _amount);
    }

  
    function out() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function collect(uint256 quantity) external onlyOwner {
        _safeMint(_msgSender(), quantity);
    }


    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function configPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function configmax_supply(uint256 newSupply) public onlyOwner {
        max_supply = newSupply;
    }

    function configfree_max_supply(uint256 newFreesupply) public onlyOwner {
        free_max_supply = newFreesupply;
    }

    //for future utility

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