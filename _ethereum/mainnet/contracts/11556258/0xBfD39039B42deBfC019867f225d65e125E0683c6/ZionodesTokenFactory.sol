// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./ZionodesToken.sol";

import "./IZToken.sol";

import "./Pause.sol";

contract ZionodesTokenFactory is Pause {
    using SafeMath for uint256;

    struct ZToken {
        ZionodesToken token;
        uint256 weiPrice;
        bool initialized;
        mapping(address => uint256) prices;
    }

    struct Price {
        uint256 price;
        address addr;
    }

    struct ZTokenInfo {
        address zAddress;
        string zName;
        string zSymbol;
        uint256 decimals;
    }

    address public paymentAddress;

    ZTokenInfo[] public _zTokensInfo;

    mapping(address => ZToken) public _zTokens;
    mapping(string => address) public _zTokenAdressess;

    event ZTokenSold(
        address indexed zAddress,
        address indexed buyer,
        uint256 amount
    );

    modifier zTokenExistsAndNotPaused(address zAddress) {
        require(_zTokens[zAddress].initialized, "Token isn't deployed");
        require(!_zTokens[zAddress].token.paused(), "Token is paused");
        _;
    }

    modifier onlyCorrectAddress(address destination) {
        require(destination != address(0), "Zero address");
        require(destination != address(this), "Identical addresses");
        _;
    }

    constructor ()
        Roles([_msgSender(), address(this), address(0)])
    {
        paymentAddress = address(this);
    }

    function deployZToken
    (
        string memory zName,
        string memory zSymbol,
        uint8 decimals,
        uint256 totalSupply
    )
        external
        onlySuperAdminOrAdmin
        returns (address)
    {
        require(
            _zTokenAdressess[zSymbol] == address(0) ||
            _zTokens[_zTokenAdressess[zSymbol]].token.paused(),
            "Token exists and not paused"
        );

        ZionodesToken tok = new ZionodesToken(
            zName,
            zSymbol,
            decimals,
            totalSupply,
            owner()
        );

        ZToken storage zToken = _zTokens[address(tok)];
        zToken.token = tok;
        zToken.weiPrice = 0;
        zToken.initialized = true;

        _zTokenAdressess[zSymbol] = address(tok);
        _zTokensInfo.push(ZTokenInfo(address(tok), zName, zSymbol, decimals));

        return address(tok);
    }

    function mintZTokens(address zAddress, address account, uint256 amount)
        external
        onlySuperAdminOrAdmin
        zTokenExistsAndNotPaused(zAddress)
    {
        _zTokens[zAddress].token.mint(account, amount);
    }

    function setupWeiPriceForZToken(address zAddress, uint256 weiPrice)
        external
        onlySuperAdminOrAdmin
        zTokenExistsAndNotPaused(zAddress)
    {
        _zTokens[zAddress].weiPrice = weiPrice;
    }

    function setupERC20PricesForZToken
    (
        address zAddress,
        Price[] memory prices
    )
        external
        onlySuperAdminOrAdmin
        zTokenExistsAndNotPaused(zAddress)
    {
        for (uint256 i = 0; i < prices.length; ++i) {
            _zTokens[zAddress].prices[prices[i].addr] = prices[i].price;
        }
    }

    function setPaymentAddress(address paymentAddr)
        external
        onlySuperAdminOrAdmin
    {
        require(paymentAddr != address(0), "Zero address");
        require(paymentAddr != paymentAddress, "Identical addresses");

        paymentAddress = paymentAddr;
    }

    function buyZTokenUsingWei(address zAddress, uint256 amount)
        external
        payable
        zTokenExistsAndNotPaused(zAddress)
        returns (bool)
    {
        require(_zTokens[zAddress].weiPrice > 0, "Price not set");

        uint256 tokenDecimals = _zTokens[zAddress].token.decimals();

        require(msg.value == _zTokens[zAddress].weiPrice.mul(amount), "Not enough wei");

        _zTokens[zAddress].token.transfer(_msgSender(), amount.mul(10 ** tokenDecimals));

        if (paymentAddress != address(this)) {
            address(uint160(paymentAddress)).transfer(msg.value);
        }

        emit ZTokenSold(zAddress, _msgSender(), amount.mul(10 ** tokenDecimals));

        return true;
    }

    function buyZTokenUsingERC20Token
    (
        address zAddress,
        address addr,
        uint256 amount
    )
        external
        zTokenExistsAndNotPaused(zAddress)
        returns (bool)
    {
        require(_zTokens[zAddress].prices[addr] > 0, "Price not set");

        IZToken token = IZToken(addr);
        uint256 tokenDecimals = _zTokens[zAddress].token.decimals();

        token.transferFrom(
            _msgSender(),
            paymentAddress,
            _zTokens[zAddress].prices[addr].mul(amount)
        );
        _zTokens[zAddress].token.transfer(_msgSender(), amount.mul(10 ** tokenDecimals));

        emit ZTokenSold(zAddress, _msgSender(), amount.mul(10 ** tokenDecimals));

        return true;
    }

    function withdrawWei(address destination)
        external
        onlySuperAdminOrAdmin
        onlyCorrectAddress(destination)
        returns (bool)
    {
        address(uint160(destination)).transfer(address(this).balance);

        return true;
    }

    function withdrawERC20Token(address addr, address destination)
        external
        onlySuperAdminOrAdmin
        onlyCorrectAddress(destination)
        returns (bool)
    {
        IZToken token = IZToken(addr);

        return token.transfer(destination, token.balanceOf(address(this)));
    }

    function getZTokenPriceByERC20Token
    (
        address zAddress,
        address addr
    )
        external
        view
        returns (uint256)
    {
        return _zTokens[zAddress].prices[addr];
    }

    function getZTokensInfo()
        external
        view
        returns (ZTokenInfo[] memory)
    {
        return _zTokensInfo;
    }
}
