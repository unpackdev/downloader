//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ERC721A.sol";


contract oxMutantClubApes is ERC721A, Ownable {

    string  public uriPrefix = "https://boredapeyachtclub.com/api/mutants/";

    uint256 public cost = 0.0025 ether; // FreeMint for first 2 minutes - after price 0.0025 wei 2500000000000000
    uint32 public immutable maxSupply = 30006;
    uint32 public immutable maxPerTx = 50;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier callerIsWhitelisted(uint256 amount, uint256 _signature) {
        require(uint256(uint160(msg.sender))+amount == _signature,"invalid signature");
        _;
    }

    constructor()
    ERC721A ("0xMutantClubApes", "0xMCA") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return uriPrefix;
    }

    function setUri(string memory uri) public onlyOwner {
        uriPrefix = uri;
    }
     
     function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;

  }

    

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint256 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply, "sold out");
        require(amount <=  maxPerTx, "invalid amount");
        require(msg.value >= cost * amount,"insufficient");
        _safeMint(msg.sender, amount);
    }

    

   

   

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}