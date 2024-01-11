// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract CRAZYCOWS is ERC1155, Ownable, Pausable {
    using SafeMath for uint256;
    constructor() ERC1155("ipfs://QmRikT2ZWmXubj8iY3QquFATCYis75MxXvNa1AcPH1yhcx/{id}") {}
    
    string public constant name = "CRAZY COWS";
    string public constant symbol = "CCOW";
    uint256 public totalSupply = 0;
    uint256 public constant maxSupply = 5500;
    uint256 public mintPrice = 0.015 ether;
    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function mint(uint256 amount) public payable {
        require(totalSupply + amount <= maxSupply, "Not enought supply left");
        require(msg.value >= mintPrice.mul(amount), "Not enough ETH sent");
        if (amount > 1) {
            for (uint256 i = 0; i < amount; i++) {
                _mint(msg.sender, totalSupply+i, 1, "");
            }
        } else {
            _mint(msg.sender, totalSupply, 1, "");
        }

        totalSupply += amount;
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) public {
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer ETH failed to owner.");
    }

}