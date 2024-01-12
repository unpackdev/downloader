// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MetaQueens is Initializable, ERC1155Upgradeable, OwnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    struct Price {
        uint256 basic;
        uint256 platinum;
    }
    uint256 public constant PLATINUM = 1;
    Price public price;
    uint256 public platinumPeriodTime;

    function initialize(string memory uri, uint256 basicPrice, uint256 platinumPrice, uint256 platinumTimestamp) initializer public {
        __ERC1155_init(uri);
        __Ownable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        price = Price(basicPrice, platinumPrice);
        platinumPeriodTime = platinumTimestamp;
    }

    function mint(uint256 amount) public payable {
        mintTo(msg.sender, amount);
    }

    function mintTo(address to, uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than zero");
        if (msg.sender != owner()) {
            require(msg.value >= currentPrice() * amount, "Not enough ether");
        }
        uint256 id = block.timestamp >= platinumPeriodTime ? PLATINUM : randomId();
        _mint(to, id, amount, "");
    }

    function randomId() private view returns (uint256) {
        // random in [2, 3, 4]
        return (block.timestamp % 3) + 2;
    }

    function currentPrice() public view virtual returns (uint256) {
        return block.timestamp >= platinumPeriodTime ? price.platinum : price.basic;
    }

    function setPrice(uint256 basic, uint256 platinum) public onlyOwner {
        price = Price(basic, platinum);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setPlatinumPeriodTime(uint256 timestamp) public onlyOwner {
        platinumPeriodTime = timestamp;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
