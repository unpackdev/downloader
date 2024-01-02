// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BackedByParadigm is ERC20, ERC20Burnable, Ownable {
    address private constant _router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public tradingEnabled;

    mapping(address => bool) private _pairs;

    event TradingEnabled();
    event PairsUpdated();

    constructor(
        uint256 maxSupply
    ) ERC20("BackedByParadigm", "BackedByParadigm") {
        _approve(_msgSender(), _router, type(uint256).max);
        _mint(_msgSender(), maxSupply * 10 ** 18);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "BBP: trading already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setPairs(
        address[] calldata pairs,
        bool[] calldata status
    ) external onlyOwner {
        require(!tradingEnabled, "BBP: trading already enabled");
        require(pairs.length == status.length, "BBP: invalid parameters");
        for (uint256 i = 0; i < pairs.length; i++) {
            _pairs[pairs[i]] = status[i];
        }
        emit PairsUpdated();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BBP: transfer from the zero address");
        require(to != address(0), "BBP: transfer to the zero address");

        if (!tradingEnabled) {
            if (_pairs[from] || _pairs[to]) {
                _pairs[from]
                    ? require(to == owner(), "BBP: trading disabled")
                    : require(from == owner(), "BBP: trading disabled");
            }
        }

        super._transfer(from, to, amount);
    }
}
