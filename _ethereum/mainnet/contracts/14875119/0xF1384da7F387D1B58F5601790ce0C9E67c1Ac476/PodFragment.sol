// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Interfaces.sol";

contract PodFragment is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    uint256 public constant MAX_SUPPLY = 4100;

    address public wormholeAddress;
    address public descriptorAddress;

    uint256 public mintCount;

    constructor() ERC1155("Anonymice Pod Fragments") {}

    function mintMany(address to, uint256 amount) external {
        require(msg.sender == wormholeAddress, "not allowed");
        if (mintCount == MAX_SUPPLY) return;
        uint256 safeAmount = amount;

        if (mintCount + amount > MAX_SUPPLY) {
            safeAmount = MAX_SUPPLY - mintCount;
        }
        mintCount += safeAmount;
        return _mint(to, 1, safeAmount, "");
    }

    function setAddresses(address _wormholeAddress, address _descriptorAddress) external onlyOwner {
        wormholeAddress = _wormholeAddress;
        descriptorAddress = _descriptorAddress;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return IDescriptor(descriptorAddress).tokenURI(_id);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
