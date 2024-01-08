// Contract created by Carton and owned by Sunland.
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Sunland is ERC721Enumerable, Ownable {
    address public constant vaultAddress = 0x634bd516EA946241c2cBaD6A355D0Fb41F608De6;

    uint256 public price = 1000000000000000000; // Default price of 1 ETH, may change at release date

    string public baseURI = "";

    bool public isSaleActive = false;

    constructor() ERC721("Sunland", "Sunland") {}

    function launch(string memory _base) public onlyOwner {
        baseURI = _base;
        isSaleActive = true;
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function withdrawAllToVault() public onlyOwner {
        address payable vault = payable(vaultAddress);
        vault.transfer(address(this).balance);
    }

    function withdraw(uint256 value) public onlyOwner {
        address payable ownerAdr = payable(msg.sender);
        ownerAdr.transfer(value);
    }

    function mint() public payable {
        require(isSaleActive, "Lands minting is not yet available" );
        require(msg.value >= price, "Insuffisant Eth");

        uint256 newItemId = totalSupply() + 1;

        require(newItemId <= 177, "Exceeds maximum tokens available for purchase");
        _safeMint(msg.sender, newItemId);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getAllOwnerAndToken() public view returns(address[] memory) {
        address[] memory adrs = new address[](totalSupply() + 1);
        address defaut;
        adrs[0] = defaut;
        for (uint i = 1; i <= totalSupply(); i++) {
            adrs[i] = ownerOf(i);
        }
        return adrs;
    }
}
