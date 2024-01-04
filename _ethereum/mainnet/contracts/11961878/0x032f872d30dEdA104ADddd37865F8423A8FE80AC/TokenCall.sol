// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IOracle.sol";
import "./Ownable.sol";

contract TokenCall is Ownable {
    struct TokenData {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint256 price;
        uint256 balance;
    }

    IOracle public oracle;

    constructor (IOracle _oracle) {
        oracle = _oracle;
    }

    function getToken(IERC20 _asset, address _account) public view returns (TokenData memory) {
        string memory _name = _asset.name();
        string memory _symbol = _asset.symbol();
        uint8 _decimals = _asset.decimals();
        uint256 _totalSupply = _asset.totalSupply();
        uint256 _balance = _asset.balanceOf(_account);
        uint256 _price = oracle.getPriceUSD(address(_asset));
        return TokenData({
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            totalSupply: _totalSupply,
            price: _price,
            balance: _balance
        });
    }

    function getTokens(IERC20[] calldata _assets, address _account) external view returns (TokenData[] memory data) {
        data = new TokenData[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            data[i] = getToken(_assets[i], _account);
        }
    }

    function setOracle(IOracle _oracle) external onlyOwner {
        oracle = _oracle;
    }
}