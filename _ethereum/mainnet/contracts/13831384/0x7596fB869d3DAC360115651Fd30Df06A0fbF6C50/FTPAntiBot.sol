// SPDX-License-Identifier: MIT
// po-dev
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract FTPAntiBot is Context, Ownable {
    bool private m_TradeOpen = true;
    mapping(address => bool) private m_IgnoreTradeList;
    mapping(address => bool) private m_WhiteList;
    mapping(address => bool) private m_BlackList;

    address private m_UniswapV2Pair;
    address private m_UniswapV2Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event addressScanned(
        address _address,
        address safeAddress,
        address _origin
    );
    event blockRegistered(address _recipient, address _sender);

    function setUniswapV2Pair(address pairAddress) external onlyOwner {
        m_UniswapV2Pair = pairAddress;
    }

    function getUniswapV2Pair() external view returns (address) {
        return m_UniswapV2Pair;
    }

    function setWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = true;
    }

    function removeWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = false;
    }

    function isWhiteListed(address _address) external view returns (bool) {
        return m_WhiteList[_address];
    }

    function setBlackList(address _address) external onlyOwner {
        m_BlackList[_address] = true;
    }

    function removeBlackList(address _address) external onlyOwner {
        m_BlackList[_address] = false;
    }

    function isBlackListed(address _address) external view returns (bool) {
        return m_BlackList[_address];
    }

    function setTradeOpen(bool tradeOpen) external onlyOwner {
        m_TradeOpen = tradeOpen;
    }

    function getTradeOpen() external view returns (bool) {
        return m_TradeOpen;
    }

    function scanAddress(
        address _address,
        address safeAddress,
        address _origin
    ) external returns (bool) {
        emit addressScanned(_address, safeAddress, _origin);
        return false;
    }

    function registerBlock(address _sender, address _recipient) external {
        if (!m_TradeOpen)
            require(!_isTrade(_sender, _recipient), "Can't Trade");

        require(
            !m_BlackList[_sender] && !m_BlackList[_recipient],
            "Address is in blacklist"
        );
        emit blockRegistered(_recipient, _sender);
    }

    function _isBuy(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _sender == m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router) &&
            !m_WhiteList[_recipient];
    }

    function _isSale(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _recipient == m_UniswapV2Pair &&
            _sender != address(m_UniswapV2Router) &&
            !m_WhiteList[_sender];
    }

    function _isTrade(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return _isBuy(_sender, _recipient) || _isSale(_sender, _recipient);
    }
}
