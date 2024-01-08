pragma solidity 0.8.6;

/*
  \ \
   \ \
  __\ \
  \  __\
$VOLT SupShop'
  \  __\
   \ \
    \ \
     \/   
 */

/**
*  SPDX-License-Identifier: UNLICENSED
*/

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";

interface IVoltage {
	function balanceOf(address user) external returns(uint);
    function spend(address user, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

contract SupShop is ERC1155Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    address public KingFrogs;
    IVoltage public Voltage;
    string private baseURI;
    uint256 public numTypes;

    mapping(uint256 => uint256) public itemTypePrices;
    mapping(uint256 => uint256) public totalSupplies;
    mapping(uint256 => uint256) public maxSupplies;

    function mint(uint256 id, uint256 amount) external {
        require(totalSupplies[id] + amount <= maxSupplies[id], "no supply remaining");
        Voltage.spend(msg.sender, itemTypePrices[id] * amount);
        Voltage.mint(owner(), itemTypePrices[id] * amount / 20); // 5% community allocation
        _mint(msg.sender, id, amount, "");
        totalSupplies[id] += amount;
    }

    function burnItem(address burnTokenAddress, uint256 typeId, uint256 amount) external {
        require(msg.sender == KingFrogs, "Invalid burner address");
        _burn(burnTokenAddress, typeId, amount);
    }

    function addItemType(uint256 itemTypeId, uint256 itemTypePrice, uint256 supply) external onlyOwner {
        itemTypePrices[itemTypeId] = itemTypePrice;
        maxSupplies[itemTypeId] = supply;
        numTypes++;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setVoltage(address voltAddy) external onlyOwner{
		Voltage = IVoltage(voltAddy);
	}

    function setFrog(address KingFrogsAddress) external onlyOwner {
        KingFrogs = KingFrogsAddress;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(maxSupplies[typeId] > 0, "URI requested for invalid item type");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString())) : baseURI;
    }

    function totalSupply(uint256 typeId) public view returns (uint256) {
        require(itemTypePrices[typeId] > 0, "URI requested for invalid item type");
        return totalSupplies[typeId];
    }

    function initialize() initializer public {
        __ERC1155_init("https://api.supducks.com/shop/metadata/");
        __Ownable_init();

        baseURI = "https://api.supducks.com/shop/metadata/";
        itemTypePrices[0] = 500 ether;
        itemTypePrices[1] = 1000 ether;
        itemTypePrices[2] = 2500 ether;
        itemTypePrices[3] = 5000 ether;
        maxSupplies[0] = 7500;
        maxSupplies[1] = 3500;
        maxSupplies[2] = 500;
        maxSupplies[3] = 100;
        numTypes = 4;
    }
}