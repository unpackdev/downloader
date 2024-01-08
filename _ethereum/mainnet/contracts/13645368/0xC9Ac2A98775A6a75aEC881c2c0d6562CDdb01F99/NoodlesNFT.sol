// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract NoodlesNFT is ERC721Enumerable, PaymentSplitter, Ownable {

    using SafeMath for uint256;

    string private _tokenURI;
    bool public mintActive;
    uint256 public maxSupply;
    uint256 public itemPrice;
    uint256 public maxPerWallet;
    
    address[] private _team = [0x4598374023728206194e36d52680fcE9f96C5d85, 0xD1b120f0592B4335d9a3319C9F71509fAEd36E3b, 0x2da423A97d64a2417CD4407eBa82137FEcbECbFb, 0x1F9eC16c861A9513CE5ad8A25231D31d5E345BC6, 0x031b527d92649bDb4b07ebD3494C21b17136Ed17, 0x9c18a72b7310aF06ba941225aa2fa6c73f81FeA3];
    uint256[] private _shares = [1, 1, 1, 1, 1, 1];

    constructor() ERC721("NoodlesNFT", "NOODS") PaymentSplitter(_team, _shares) {
        _tokenURI = "";
        mintActive = false;
        itemPrice = 8e16;
        maxPerWallet = 2;
    }

    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }    

    function mint(uint256 amount) public payable {
        uint256 ts = totalSupply();
        require(mintActive, "Sale not acitve!");
        require(balanceOf(msg.sender).add(amount) <= maxPerWallet, "Amount exeed max token per wallet!");
        require(ts.add(amount) <= maxSupply, "Amount exeeds max supply!");
        require(itemPrice.mul(amount) == msg.value, "Not enough ETH");
        for (uint256 i = ts + 1; i <= ts + amount; i++) {
            _safeMint(msg.sender, i);
        }        
    }

    function giveaway(address _address, uint256 amount) public onlyOwner{
        uint256 ts = totalSupply();
        require(ts.add(amount) <= maxSupply, "Amount exeeds max supply!");
        for (uint256 i = ts + 1; i <= ts + amount; i++) {
            _safeMint(_address, i);
        }        
    }

    function setMintActive(bool _active) public onlyOwner {
        mintActive = _active;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _tokenURI = _uri;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply <= 3333, "Too high");
        maxSupply = _maxSupply;
    }

    function setItemPrice(uint256 _itemPrice) public onlyOwner {
        itemPrice = _itemPrice;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }
}
