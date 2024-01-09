// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";

abstract contract BearHoodInterface {
    function openBox(address to) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract BlindBox is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    string public name;
    string public symbol;

    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 public TotalAmount = 10000;
    uint256 private tokenPrice = 10000000000000000; // 0.01 ETH
    uint256 minPrice = 10000000000000000;

    address bearhoodContractAddress;

    mapping (address => mapping (uint256 => bool)) openedBoxes;

    event BearRevealed(address indexed owner, uint256 indexed bearId);
                                
    bool salesStarted = false;
    bool openBoxStarted = false;

    //Price Adjustment
    uint256 increaseBuffer;
    uint256 decreaseBuffer;
    uint256 increaseRate = 20000000000000000; // 0.02 ETH
    uint256 decreaseRate = 10000000000000000; // 0.01 ETH

    constructor(
        string memory _uri
    ) ERC1155(_uri) {
        name = "BearBox";
        symbol = unicode"❣";
        increaseBuffer = block.timestamp;
        decreaseBuffer = block.timestamp;
    }

    function totalSupply() public view returns(uint256) {
        return amountMinted;
    }

    function setBearContract(address contractAddress) public onlyOwner {
        bearhoodContractAddress = contractAddress;
    }
    function toggleSales() public onlyOwner {
        salesStarted = !salesStarted;
    }

    function toggleBoxOpen() public onlyOwner {
        openBoxStarted = !openBoxStarted;
    }

    function buyBox(uint256 _amount) public payable returns(uint256) {
        require(salesStarted == true, "Sales have not started");
        uint256 current = currentPrice();
        require(msg.value >= current.mul(_amount), "Not enough money");
        require(_amount + amountMinted <= TotalAmount, "Limit reached");
        amountMinted = amountMinted + _amount;
        _mint(msg.sender, tokenId, _amount, "");
        _priceAdjustment();
        return amountMinted;
    }

    function airdrop(address[] memory receivers, uint256[] memory amounts) public onlyOwner {
        for(uint256 i; i<receivers.length; i++){
            require(amounts[i] + amountMinted <= TotalAmount, "Limit reached");
            amountMinted = amountMinted + amounts[i];
            _mint(receivers[i], tokenId, amounts[i], "");
        }
    }

    function revealBear() public returns(uint256) {
        require(openBoxStarted == true, "OpenBox has not started");
        require(balanceOf(msg.sender, tokenId) > 0, "Doesn't own the token");
        burn(msg.sender, tokenId, 1);
        BearHoodInterface bearhoodContract = BearHoodInterface(bearhoodContractAddress);
        uint256 mintedId = bearhoodContract.openBox(msg.sender);
        emit BearRevealed(msg.sender, mintedId);
        return mintedId;
    }

    function currentPrice() public view returns(uint256) {
        uint256 timeGap = block.timestamp.sub(decreaseBuffer);
        uint256 range = timeGap.div(28800);
        if(range.mul(decreaseRate) >= tokenPrice.add(minPrice)){
            return minPrice;
        } else {
            return tokenPrice.sub(range.mul(decreaseRate));
        }
    }

    function _priceAdjustment() internal returns(uint256) {
        uint256 current = currentPrice();
        uint256 increaseGap = block.timestamp.sub(increaseBuffer);
        if(increaseGap >= 28800){
            tokenPrice = current.add(increaseRate);
            increaseBuffer = block.timestamp;
            decreaseBuffer = block.timestamp;
        } else {
            decreaseBuffer = block.timestamp;
        }
        return tokenPrice;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }
    
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
    