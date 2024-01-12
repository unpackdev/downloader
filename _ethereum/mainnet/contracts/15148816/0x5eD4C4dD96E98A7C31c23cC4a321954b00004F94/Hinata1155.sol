// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Strings.sol";
import "./ERC1155Supply.sol";

contract Hinata1155 is ERC1155Supply {
    using Strings for uint256;

    string public name;
    string public symbol;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Hinata1155: NOT_OWNER");
        _;
    }

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_
    ) ERC1155("") {
        require(owner_ != address(0), "Hinata1155: INVALID_OWNER");
        owner = owner_;
        name = name_;
        symbol = symbol_;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return
            (string)(
                abi.encodePacked(
                    "https://api.hinata.io/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/",
                    id.toString()
                )
            );
    }
}
