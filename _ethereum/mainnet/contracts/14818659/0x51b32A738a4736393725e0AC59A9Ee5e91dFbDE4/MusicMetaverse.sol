// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

/// @author Sergio Martell - Motley Ds (www.motleyds.com)

/**
* @notice This contract establishes the base assets for BAND NFTs Music Metaverse.
*/

contract MusicMetaverse is ERC1155, ReentrancyGuard, Ownable {
    string public name;
    string public symbol;
    address public wallet = 0xA60Ff71261dE3eabc6D2536142266B5092613ea6;
    address private _wallet1 = 0xF636A92991DFC7f842E04fd4A67588226e37DBc6;
    address private _wallet2 = 0x0F04Fb7De73f11d2B04Bfd0B50f27dd5d5E81B98;
    IERC20 public ryltToken;
    
    string private _uri = "https://ipfs.io/ipfs/QmRwK972xNSm2u5L6cupscesfxgwLYbLLGtSBShr7HQ64m/";

    mapping (uint256 => uint256) private _prices;
    mapping (uint256 => uint256) private _ryltPrice;
    mapping (uint256 => uint256) private _supplies;
    mapping (uint256 => uint256) private _minted;
    mapping (uint256 => bool) private _saleActive;

    event TokenMinted(address sender, uint256 quantity, uint256 tokenId);

    constructor() ERC1155(""){
        name = "BAND Music Metaverse";
        symbol = "BMMV";
        ryltToken = IERC20(0x56ff962f6eD95Db6fee659Abca15d183527405E4);
        // Creation of Band Concert Hall VIP Metatickets
        _prices[0] = .177 ether;
        _ryltPrice[0] = 2500 * 10 ** 18;
        _supplies[0]= 3000;
        _saleActive[0] = false;

        // Creation of Band Concert Hall Regular Metatickets
        _prices[1] = .033 ether;
        _ryltPrice[1] = 500 * 10 ** 18;
        _supplies[1] = 7000;
        _saleActive[1] = false;
    }

    // Owner Only functions.

    function setSaleState(uint256 tokenId, bool _saleFlag) external onlyOwner {
        _saleActive[tokenId] = _saleFlag;
    }

    // Owner Mint, will reflect on totalSupply

    function ownerMint(uint256 id, uint256 amount)
        public
        onlyOwner
        {
            require(_minted[id]+amount <= _supplies[id], "This release has reached it's limited supply");
            _mint(msg.sender, id, amount, "");
            _minted[id]+= amount;
        }

    function changeBaseURI(string memory bURI) public onlyOwner {
        _uri = bURI;
    }

    function changePrice(uint256 price, uint256 tokenId) public onlyOwner {
        _prices[tokenId] = price;
    }

    function changeRYLTPrice(uint256 price, uint256 tokenId) public onlyOwner {
        _ryltPrice[tokenId] = price;
    }

    function expandMetaverse (uint256 tokenId, uint256 supply, uint256 price,  uint256 ryltPrice, bool active, string memory bURI) public onlyOwner{
        _uri = bURI;
        _supplies[tokenId] = supply;
        _prices[tokenId] = price;
        _ryltPrice[tokenId] = ryltPrice;
        _saleActive[tokenId] = active;
    }

    function changeWallet1(address newWallet) public onlyOwner {
        _wallet1 = newWallet;
    }

    function changeWallet2(address newWallet) public onlyOwner {
        _wallet2 = newWallet;
    }

    function disburse() external onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 _five = _balance * 5/100;
        uint256 _twentytwo = _balance * 22/100;
        (bool success, ) = payable(_wallet1).call{value: _five}('');
        require(success, "five percent transfer failed");
        (bool success1, ) = payable(_wallet2).call{value: _twentytwo}('');
        require(success1, "22 percent transfer failed"); 
        (bool success2, ) = payable(wallet).call{value: address(this).balance}('');
        require(success2, "Transfer for main wallet failed"); 
    }
    

    function disburseRYLT() external onlyOwner {
        uint256 _balance = ryltToken.balanceOf(address(this));
        uint256 _five = _balance * 5/100;
        uint256 _twentytwo = _balance * 22/100;
        ryltToken.transfer(_wallet1, _five);
        ryltToken.transfer(_wallet2, _twentytwo);
        ryltToken.transfer(msg.sender, ryltToken.balanceOf(address(this)));
    }

    function emergencyWithdraw() external onlyOwner {
    (bool success, ) = payable(wallet).call{ value: address(this).balance }(
      ''
    );
    require(success);
    }  

    // API

    function mint(uint256 id, uint256 amount) public payable nonReentrant {
        require(_saleActive[id], "Sale for this item is not active");
        require(_supplies[id]>0, "This item doesn't exist");
        require(_minted[id]+ amount <= _supplies[id], "This item has reached it's limited supply!");
        require(msg.value >= amount * _prices[id], "The amount sent doesn't cover the price for the asset");
        _mint(msg.sender, id, amount, "");
        _minted[id]+= amount;
        emit TokenMinted(msg.sender, amount, id);
    }

    function royalMint(uint256 id, uint256 amount, uint256 value) public nonReentrant {
        require(_saleActive[id], "Sale for this item is not active");
        require(_supplies[id]>0, "This item doesn't exist");
        require(_minted[id]+ amount <= _supplies[id], "This item has reached it's limited supply!");
        require(value >= amount *_ryltPrice[id],"The amount sent doesn't cover the price for the asset");
        ryltToken.transferFrom(msg.sender, address(this), value);
        _mint(msg.sender, id, amount, "");
        _minted[id]+= amount;
        emit TokenMinted(msg.sender, amount, id);
    }  

    function totalSupply(uint256 id) public view returns (uint256 supply){
        return _minted[id];
    }

    /**
    * @dev Returns the URI to the contract metadata as required by OpenSea
    */

    function contractURI() public pure returns (string memory){
        return "ipfs://QmRg5gHud3nHjMfVM14PAEBHdMM5V6AHB1KSUGn8SUr2Di";
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(string(abi.encodePacked( _uri, Strings.toString(tokenId))));
    }

    // fallback functions to handle someone sending ETH to contract

    fallback() external payable {}

    receive() external payable {}

}