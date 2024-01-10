//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Token is ERC1155, Ownable, Pausable {
    struct Item {
        string name;
        uint256 price;
        uint64 limit;
    }

    bool private saleIsActive;

    mapping(uint8 => Item) private items;
    mapping(uint256 => uint256) private totalSupply;

    constructor(string memory _url) ERC1155(_url) {}    

    function withdraw() external onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }    

    function addItem(uint8 _id, Item memory _item) external onlyOwner {
        items[_id] = _item;
    }

    function mint(uint8 _id, uint8 _amount) external payable {
        require(saleIsActive, "sale is not active");
        require(!paused(), "it should not be paused");

        Item memory item = items[_id];
        require(item.limit == 0 || item.limit >= totalSupply[_id] + _amount, "your purchase exceeds maximum tokens limit");

        require(item.price > 0, "item price should be >= 0");
        require(msg.value >= item.price * _amount, "amount sent is not enough for purchase");

        totalSupply[_id] += _amount;
        _mint(msg.sender, _id, _amount, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "token transfer while paused");
    }    
}
