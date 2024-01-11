// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ETHWalkersMintPass is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint8 public constant maxMintPassPurchase = 20;
    uint8 public saleState = 0;
    uint public maxMintPass = 3000;
    uint private _EWMPReserve = 100;
    address payable public payoutsAddress = payable(address(0x2608b7D6D6E7d98f1b9474527C3c1A0eD54bE399));
    uint public publicSale = 1651098600;

    uint256 private _MintPassPrice = 150000000000000000; // 0.15 ETH
    string private baseURI;

    constructor() ERC721A("ETH Walkers Mint Pass", "EWMP") { }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _MintPassPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _MintPassPrice;
    }

    function setSaleTimes(uint _newTime) external onlyOwner {
        publicSale = _newTime;
    }

    function reserveWalkerPass(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && _reserveAmount <= _EWMPReserve, "Reserve limit has been reached");
        require(totalSupply().add(_reserveAmount) <= maxMintPass, "No more tokens left to mint");
        _EWMPReserve = _EWMPReserve.sub(_reserveAmount);
        _safeMint(_to ,_reserveAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setSaleState(uint8 newSaleState) public onlyOwner {
        saleState = newSaleState;
    }

    function mintETHWalkerMintPass(uint numberOfTokens) external payable {
        require(saleState >= 1, "Sale must be active to mint");
        require(numberOfTokens > 0 && numberOfTokens <= maxMintPassPurchase, "Oops - you can only mint 20 passes at a time");
        require(msg.value >= _MintPassPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= maxMintPass, "Purchase exceeds max supply of passes");
        require(block.timestamp >= publicSale, "Public sale not started");

        _safeMint(msg.sender, numberOfTokens);

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}