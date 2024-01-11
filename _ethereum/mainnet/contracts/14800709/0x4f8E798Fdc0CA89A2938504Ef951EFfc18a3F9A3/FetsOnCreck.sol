// SPDX-License-Identifier: Unlicensed

// ███████╗███████╗████████╗░██████╗  ░█████╗░███╗░░██╗  ░█████╗░██████╗░███████╗░█████╗░██╗░░██╗
// ██╔════╝██╔════╝╚══██╔══╝██╔════╝  ██╔══██╗████╗░██║  ██╔══██╗██╔══██╗██╔════╝██╔══██╗██║░██╔╝
// █████╗░░█████╗░░░░░██║░░░╚█████╗░  ██║░░██║██╔██╗██║  ██║░░╚═╝██████╔╝█████╗░░██║░░╚═╝█████═╝░
// ██╔══╝░░██╔══╝░░░░░██║░░░░╚═══██╗  ██║░░██║██║╚████║  ██║░░██╗██╔══██╗██╔══╝░░██║░░██╗██╔═██╗░
// ██║░░░░░███████╗░░░██║░░░██████╔╝  ╚█████╔╝██║░╚███║  ╚█████╔╝██║░░██║███████╗╚█████╔╝██║░╚██╗
// ╚═╝░░░░░╚══════╝░░░╚═╝░░░╚═════╝░  ░╚════╝░╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚═╝

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract FetsOnCreck is ERC721A, Ownable {

    using SafeMath for uint256;

    bool public saleIsActive;
    string internal _baseTokenURI;
    uint256 public MAX_TOKENS = 6969;
    uint256 public tokenPrice = 0.002 ether;

    constructor() ERC721A("FetsOnCreck", "FOC") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function mintOwner(address to, uint quantity) external onlyOwner {    
        uint supply = totalSupply();
        require(supply.add(quantity) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale NOT active yet");
        require(quantity < 11, "max of 10 NFTs per transaction");
        require(supply.add(quantity) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        if(supply.add(quantity) > 969) {  require(tokenPrice.mul(quantity) <= msg.value, "Ether value sent is not correct"); }
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(owner(), balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    fallback() external payable { }
    receive() external payable { }

}
