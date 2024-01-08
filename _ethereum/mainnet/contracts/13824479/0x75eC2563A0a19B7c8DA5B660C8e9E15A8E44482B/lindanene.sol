// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Tradable.sol";
import "./SafeMath.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title LindaNene
 * WhoIsSamot - an 1155 contract for LindaNene
 */
contract LindaNene is ERC1155Tradable {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress
    ) ERC1155Tradable(_name, _symbol, _uri, _proxyRegistryAddress) {
        }

    function createId(
        address _creator,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri
    ) public onlyOwner {
        create(_creator, _id, _initialSupply, _uri, "");
    }

    function reserve(
        address account,
        uint256 _id,
        uint256 _quantity
    ) public onlyOwner {
        _mint(account, _id, _quantity, "");
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}

