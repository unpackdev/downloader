// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/** 
    @@
    ,@,
     ,@,
     ;@@;
      ,@,                     &@@@@@             ;@@@@@@@@@@@@&
      l@@;                   ,@,  @@@
       ,@@o                 ,@,    &@,
        ,@,      @@@@      &@,      ,@&        ;,              
         @@;    @@  @,    ;@@        @@       &@@@@@@@@@@@@@@@&
         ;@@   @@,  ,@&   @@:        &@,     :@@
          &@, ,@&    @@& @@,          ,@,    ,@&
           &@@@&      @@@@;           :@@    @@@@@@@@@@@@@@@@@&
                                       &@,  &@,
                                        ,@, @@;
                                         ,@@@,
                                          *@&
    
    WAAVE DIGITAL (https://twitter/Waave__)
    HLBDG Contract (made by @BettanRaphael)
**/

import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

contract HOLOBADGE is ERC721A, ERC721AQueryable, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint;

    enum Steps {
        Before,
        Sale,
        SoldOut
    }

    uint private constant MAX_SUPPLY = 555;
    uint private constant MAX_PUBLIC = 500;
    uint public price = 0.03 ether;

    Steps public sellingStep;
    string public baseURI;
    uint private teamLength;

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address[] memory _team, uint[] memory _shares)
    ERC721A(_name, _symbol)
    PaymentSplitter(_team, _shares) {
        sellingStep = Steps.Before;
        baseURI = _baseURI;
        teamLength = _team.length; 
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function waave(address _account, uint _quantity) external payable callerIsUser nonReentrant{
        require(price != 0, "Price is 0");
        require(sellingStep == Steps.Sale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_PUBLIC, "Max supply exceeded");
        require(msg.value >= getPrice(_quantity), "Not enought funds");

        if (totalSupply() + _quantity == MAX_PUBLIC) {
            sellingStep = Steps.SoldOut;   
        }

        if (msg.value > getPrice(_quantity)) {
            payable(msg.sender).transfer(msg.value - getPrice(_quantity));
        }

        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function tokenURI(uint _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, "metadata.json"));
    }

    function getPrice(uint _quantity) public view returns(uint) {
        return price * _quantity;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Steps(_step);
    }

    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }
}
