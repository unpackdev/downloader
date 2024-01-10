// SPDX-License-Identifier: MIT
//...............................................................................................................................................................
//...........................akkk......................llll............................................................ttt.......................................
//...........................akkk......................llll...........................................................tttt.......................................
//...........................akkk......................llll...........................................................tttt.......................................
//.mmmmmmmmmmmmmm....aaaaaa..akkk..kkkk..eeeeee........llll...oooooo..ovvv..vvvv..eeeeee........nnnnnnnn.....oooooo.ootttttt... ww..wwww..wwww.aaaaaa..arrrrrr..
//.mmmmmmmmmmmmmmm..aaaaaaaa.akkk.kkkk..eeeeeeee.......llll.ooooooooo.ovvv..vvvv.eeeeeeee.......nnnnnnnnn..oooooooooootttttt.... www.wwwww.wwwwaaaaaaaa.arrrrrr..
//.mmmmm.mmmmmmmmm.maaa.aaaaaakkkkkkk..keee.eeee.......llll.oooo.oooooovvv.vvvv.veee.eeee.......nnnn.nnnnn.oooo.ooooo.tttt...... www.wwwwwwwwwwaaa.aaaaaarrrr....
//.mmmm..mmmm..mmmm....aaaaaaakkkkkk...keee..eeee......lllllooo...oooo.vvvvvvvv.veee..eeee......nnnn..nnnnnooo...oooo.tttt...... wwwwwwwwwwwww....aaaaaaarrr.....
//.mmmm..mmmm..mmmm.aaaaaaaaaakkkkkkk..keeeeeeeee......lllllooo...oooo.vvvvvvvv.veeeeeeeee......nnnn..nnnnnooo...oooo.tttt.......wwwwwwwwwwwww.aaaaaaaaaarrr.....
//.mmmm..mmmm..mmmmmaaaaaaaaaakkkkkkk..keeeeeeeee......lllllooo...oooo.vvvvvvv..veeeeeeeee......nnnn..nnnnnooo...oooo.tttt.......wwwwwwwwwwww.waaaaaaaaaarrr.....
//.mmmm..mmmm..mmmmmaaa.aaaaaakkkkkkkk.keee............lllllooo...oooo..vvvvvv..veee............nnnn..nnnnnooo...oooo.tttt.......wwwwwwwwwwww.waaa.aaaaaarrr.....
//.mmmm..mmmm..mmmmmaaa.aaaaaakkk.kkkk.keee..eeee......llll.oooo.ooooo..vvvvvv..veee..eeee......nnnn..nnnn.oooo.ooooo.tttt........wwwwwwwwwww.waaa.aaaaaarrr.....
//.mmmm..mmmm..mmmmmaaaaaaaaaakkk..kkkk.eeeeeeee.......llll.ooooooooo...vvvvv....eeeeeeee.......nnnn..nnnn.ooooooooo..tttttt......wwwww.wwww..waaaaaaaaaarrr.....
//.mmmm..mmmm..mmmm.aaaaaaaaaakkk..kkkk..eeeeee........llll...oooooo.....vvvv.....eeeeee........nnnn..nnnn...oooooo...tttttt......wwww..wwww...aaaaaaaaaarrr.....
//...............................................................................................................................................................
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
contract Howlmfers is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supplymfers;
    uint256 public freemfers;
    uint256 public maxPerTxn = 101;
    uint256 public wL = 100;
    uint256 public price   = 0.0069 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("Howlmfers", "Howlmfers", 500) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < supplymfers, "Excedes max supply.");
        require(totalSupply() + 1  > freemfers, "Public sale is not live yet.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function mintt() public payable {
        require(totalSupply() + 1 <= freemfers, "cant mint this now");
        require(!walletCount[msg.sender], " cant mint");
         _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
    }

    function whitelist_reserved() external onlyOwner {
            _safeMint(_msgSender(), wL);
    }
      
    function setSupply(uint256 _newSupplymfers) public onlyOwner {
        supplymfers = _newSupplymfers;
    }

    function setfreemfers(uint256 _newfreemfers) public onlyOwner {
        freemfers = _newfreemfers;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setWL(uint256 _newWL) public onlyOwner {
        wL = _newWL;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}