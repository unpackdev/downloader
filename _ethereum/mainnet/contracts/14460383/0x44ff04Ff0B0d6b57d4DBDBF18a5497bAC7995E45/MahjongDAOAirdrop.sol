// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./IERC165.sol";

interface IERC1155ERC20 is IERC20, IERC1155 {}

interface IAirdropChecker {
    function airdropAmount(address account, uint256 id) external view returns (uint256);
}

contract MahjongDAOAirdrop is Ownable, ERC165, IERC1155Receiver {
    IERC1155ERC20 private immutable token;
    IAirdropChecker private checker;

    mapping(uint256 => uint256) public airdrops;

    event AirdropChecker(address checker);
    event Claim(address account, uint256 id, uint256 amount);
    event Received(address operator, address from, uint256 id, uint256 value, bytes data, uint256 gas);
    event BatchReceived(address operator, address from, uint256[] ids, uint256[] values, bytes data, uint256 gas);

    constructor(IERC1155ERC20 _token) {
        token = _token;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function setAirdrop(uint256 id, uint256 amount)  external onlyOwner {
        airdrops[id] = amount;
    }

    function setAirdropChecker(IAirdropChecker _checker)  external onlyOwner {
        checker = _checker;
        emit AirdropChecker(address(_checker));
    }

    function withdraw(uint256 id, uint256 amount) external onlyOwner {
        if (id == 0) {
            token.transfer(msg.sender, amount);
        } else {
            token.safeTransferFrom(address(this), msg.sender, id, amount, "");
        }
    }

    function airdropAmount(uint256 id) public view returns (uint256) {
        uint256 amount = airdrops[id];
        if (amount > 0) {
            // simple airdrop mode
            require(token.balanceOf(msg.sender, id) == 0, "condition not met");
        } else {
            // functional airdrop mode
            require(address(checker) != address(0), "airdrop not exists");
            amount = checker.airdropAmount(msg.sender, id);
        }
        return amount;
    }

    function claim(uint256 id) external {
        uint256 amount = airdropAmount(id);
        require(token.balanceOf(address(this), id) >= amount, "insufficient funds");

        if (id == 0) {
            token.transfer(msg.sender, amount);
        } else {
            token.safeTransferFrom(address(this), msg.sender, id, amount, "");
        }
        emit Claim(msg.sender, id, amount);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        emit Received(operator, from, id, value, data, gasleft());
        return bytes4(0xf23a6e61);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        emit BatchReceived(operator, from, ids, values, data, gasleft());
        return bytes4(0xbc197c81);
    }
}