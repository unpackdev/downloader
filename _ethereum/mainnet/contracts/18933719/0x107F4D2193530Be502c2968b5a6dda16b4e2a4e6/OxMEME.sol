// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";

contract OxMEME is Ownable, ERC20 {

    bool public limited;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("0xMEME", "0xMEME") {
        _mint(msg.sender, 69000000000 ether);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has not started");
            return;
        }

        if (limited && to != uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}