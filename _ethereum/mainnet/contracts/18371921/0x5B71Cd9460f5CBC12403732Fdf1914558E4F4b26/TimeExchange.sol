// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./Math.sol";
import "./ITimeToken.sol";
import "./ITimeIsUp.sol";

contract TimeExchange {

    using Math for uint256;

    uint256 private constant FACTOR = 10 ** 18;

    uint256 public constant FEE = 60;
    address public constant DEVELOPER_ADDRESS = 0x731591207791A93fB0Ec481186fb086E16A7d6D0;
    address public immutable timeAddress;
    address public immutable tupAddress;

    mapping (address => uint256) private _currentBlock;
    
    constructor(address time, address tup) {
        timeAddress = time;
        tupAddress = tup;
    }

    receive() external payable {
    }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    /// @notice Modifier to make a function runs only once per block
    modifier onlyOncePerBlock() {
        require(block.number != _currentBlock[tx.origin], "Time Exchange: you cannot perform this operation again in this block");
        _;
        _currentBlock[tx.origin] = block.number;
    }

    /// @notice Swaps native currency for another token
    /// @dev Please refer this function is called by swap() function
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The native currency amount to be swapped
    function _swapFromNativeToToken(address tokenTo, uint256 amount) private {
        IERC20 token = IERC20(tokenTo);
        uint256 comission = amount.mulDiv(FEE, 10_000);
        amount -= comission;
        payable(tokenTo).call{value: amount}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @notice Swaps token for native currency
    /// @dev Please refer this function is called by swap() function
    /// @param tokenFrom The address of the token to be swapped
    /// @param amount The token amount to be swapped
    function _swapFromTokenToNative(address tokenFrom, uint256 amount) private {
        IERC20 token = IERC20(tokenFrom);
        token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceBefore = address(this).balance;
        token.transfer(tokenFrom, amount);
        uint256 balanceAfter = address(this).balance - balanceBefore;
        uint256 comission = balanceAfter.mulDiv(FEE, 10_000);
        balanceAfter -= comission;
        payable(msg.sender).call{value: balanceAfter}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
    }

    /// @notice Swaps a token for another token
    /// @dev Please refer this function is called by swap() function
    /// @param tokenFrom The address of the token to be swapped
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The token amount to be swapped
    function _swapFromTokenToToken(address tokenFrom, address tokenTo, uint256 amount) private {
        IERC20 tokenFrom_ = IERC20(tokenFrom);
        IERC20 tokenTo_ = IERC20(tokenTo);
        tokenFrom_.transferFrom(msg.sender, address(this), amount);
        uint256 balanceBefore = address(this).balance;
        tokenFrom_.transfer(tokenFrom, amount);
        uint256 balanceAfter = address(this).balance - balanceBefore;
        uint256 comission = balanceAfter.mulDiv(FEE, 10_000);
        balanceAfter -= comission;
        payable(tokenTo).call{value: balanceAfter}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
        tokenTo_.transfer(msg.sender, tokenTo_.balanceOf(address(this)));
    }

    /// @notice Query the price of native currency in terms of an informed token
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenTo The address of the token to be queried
    /// @param amount The native currency amount to be queried
    /// @return price The price of tokens to be obtained given some native currency amount
    function _queryPriceFromNativeToToken(address tokenTo, uint256 amount) private view returns (uint256) {
        uint256 price;
        if (tokenTo == timeAddress) 
            price = ITimeToken(payable(tokenTo)).swapPriceNative(amount);
        else
            price = ITimeIsUp(payable(tokenTo)).queryPriceNative(amount);
        return price;
    }

    /// @notice Query the price of an informed token in terms of native currency
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenFrom The address of the token to be queried
    /// @param amount The token amount to be queried
    /// @return price The price of native currency to be obtained given some token amount
    function _queryPriceFromTokenToNative(address tokenFrom, uint256 amount) private view returns (uint256) {
        uint256 price;
        if (tokenFrom == timeAddress) 
            price = ITimeToken(payable(tokenFrom)).swapPriceTimeInverse(amount);
        else
            price = ITimeIsUp(payable(tokenFrom)).queryPriceInverse(amount);
        return price;
    }

    /// @notice Query the price of an informed token in terms of another informed token
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenFrom The address of the token to be queried
    /// @param tokenTo The address of the token to be queried
    /// @param amount The token amount to be queried
    /// @return priceTo The price of tokens to be obtained given some another token amount
    /// @return nativeAmount The amount in native currency obtained from the query
    function _queryPriceFromTokenToToken(address tokenFrom, address tokenTo, uint256 amount) private view returns (uint256 priceTo, uint256 nativeAmount) {
        uint256 priceFrom = _queryPriceFromTokenToNative(tokenFrom, amount);
        nativeAmount = amount.mulDiv(priceFrom, FACTOR);
        if (tokenTo == timeAddress)
            priceTo = ITimeToken(payable(tokenTo)).swapPriceNative(nativeAmount);
        else 
            priceTo = ITimeIsUp(payable(tokenTo)).queryPriceNative(nativeAmount);
        return (priceTo, nativeAmount);
    }

    /// @notice Clean the contract if it has any exceeding token or native amount
    /// @dev It should pass the tokenToClean contract address
    /// @param tokenToClean The address of token contract
    function clean(address tokenToClean) public {
        if (address(this).balance > 0)
            payable(DEVELOPER_ADDRESS).call{value: address(this).balance}("");
        if (tokenToClean != address(0))
            if (IERC20(tokenToClean).balanceOf(address(this)) > 0)
                IERC20(tokenToClean).transfer(DEVELOPER_ADDRESS, IERC20(tokenToClean).balanceOf(address(this)));
    }

    /// @notice Swaps token or native currency for another token or native currency
    /// @dev It should inform address(0) as tokenFrom or tokenTo when considering native currency
    /// @param tokenFrom The address of the token to be swapped
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The token or native currency amount to be swapped
    function swap(address tokenFrom, address tokenTo, uint256 amount) external payable onlyOncePerBlock {
        if (tokenFrom == address(0)) {
            require(tokenTo != address(0) && (tokenTo == timeAddress || tokenTo == tupAddress), "Time Exchange: unallowed token");
            require(msg.value > 0, "Time Exchange: please inform the amount to swap");
            _swapFromNativeToToken(tokenTo, msg.value);
            clean(tokenFrom);
            clean(tokenTo);
        } else if (tokenTo == address(0)) {
            require(amount > 0, "Time Exchange: please inform the amount to swap");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            require(IERC20(tokenFrom).allowance(msg.sender, address(this)) >= amount, "Time Exchange: please approve the amount to swap");
            _swapFromTokenToNative(tokenFrom, amount);
            clean(tokenFrom);
            clean(tokenTo);
        } else {
            require(amount > 0, "Time Exchange: please inform the amount to swap");
            require(tokenTo == timeAddress || tokenTo == tupAddress, "Time Exchange: unallowed token");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            require(IERC20(tokenFrom).allowance(msg.sender, address(this)) >= amount, "Time Exchange: please approve the amount to swap");
            _swapFromTokenToToken(tokenFrom, tokenTo, amount);
            clean(tokenFrom);
            clean(tokenTo);
        }
    }

    /// @notice Query the price of token or native currency in terms of another token or native currency
    /// @dev It should inform address(0) as tokenFrom or tokenTo when considering native currency
    /// @param tokenFrom The address of the token to be queried
    /// @param tokenTo The address of the token to be queried
    /// @param amount The token or native currency amount to be queried
    /// @return price The queried price
    /// @return nativeAmount The native amount in the middle of the query (if the case)
    function queryPrice(address tokenFrom, address tokenTo, uint256 amount) external view returns (uint256, uint256) {
        if (tokenFrom == address(0)) {
            require(tokenTo != address(0) && (tokenTo == timeAddress || tokenTo == tupAddress), "Time Exchange: unallowed token");
            return (_queryPriceFromNativeToToken(tokenTo, amount), 0);
        } else if (tokenTo == address(0)) {
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            return (_queryPriceFromTokenToNative(tokenFrom, amount), 0);
        } else {
            require(tokenTo == timeAddress || tokenTo == tupAddress, "Time Exchange: unallowed token");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            return _queryPriceFromTokenToToken(tokenFrom, tokenTo, amount);
        }        
    }
}