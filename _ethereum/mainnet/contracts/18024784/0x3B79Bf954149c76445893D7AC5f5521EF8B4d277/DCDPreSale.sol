// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";
import "./Withdrawable.sol";

contract DCDPreSale is Ownable, Pausable, ReentrancyGuard, Withdrawable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public s_usdt;

    address public i_eth_usd_priceFeed;
    address public i_usdt_usd_priceFeed;
    address public s_dcdtoken;

    uint256 public s_usdtPrice = 110000;
    uint256 public s_tokensForSale = 2_600_000 ether;
    uint256 public s_tokenSold;

    uint256 public s_claimDate = 1696024795;

    uint256 public s_totalUSDTRaised;

    mapping(address => uint256) public s_investemetByAddress;
    mapping(address => bool) public s_managers;

    address public fundDistributor = 0x34a5C36Edd481458a89401Ee6CaAa8bEc5b0Dd54;

    event BoughtWithNativeToken(address user, uint256 amount, uint256 time);
    event BoughtWithUSDT(address user, uint256 amount, uint256 time);
    event BoughtWithAPI(address user, uint256 amount, uint256 time);

    modifier onlyManager() {
        require(s_managers[msg.sender], "Only manager function");
        _;
    }

    constructor() {
        s_managers[msg.sender] = true;

        if (block.chainid == 1) {
            _transferOwnership(0xAa96D1A2d3D5E6c6276270c96e921F3C3d359F3e);
            i_eth_usd_priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
            i_usdt_usd_priceFeed = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
            s_usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
            s_dcdtoken = 0x0f55372B560401886B094b64058287B857c20d7A;
        } else {
            i_eth_usd_priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
            i_usdt_usd_priceFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
            s_usdt = IERC20(0xB61Da7334046f2B962C12742061295E328fA0e46);
            s_dcdtoken = 0xEC6cf22A5244cdbA68974097A552a345D68cfc56;
        }
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    receive() external payable {}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function _getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) internal view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = _scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = _scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function _scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function ETH_DCD(uint256 ETHAmount) public view returns (uint256) {
        uint256 eth_usdt_price = uint256(_getETHPriceInUSDT());

        uint256 eth_amount_usdt_price = ETHAmount.mul(eth_usdt_price).div(
            s_usdtPrice
        );

        uint256 eth_dcd = eth_amount_usdt_price.div(1e18);
        return eth_dcd.mul(1e18);
    }

    function USDT_DCD(uint256 USDTAmount) public view returns (uint256) {
        uint256 DCD_USDT_PRICE = _getTokensForUSDT(USDTAmount);
        return DCD_USDT_PRICE.mul(1e18);
    }

    function _getETHPriceInUSDT() internal view returns (int256) {
        return _getDerivedPrice(i_eth_usd_priceFeed, i_usdt_usd_priceFeed, 6);
    }

    function _getTokensForUSDT(
        uint256 usdt_amount
    ) internal view returns (uint256) {
        return div(usdt_amount, s_usdtPrice);
    }

    function _getPriceOfGivenTokenInETH(
        int256 amount
    ) internal view returns (int256) {
        int256 usdtPriceInETH = _getDerivedPrice(
            i_usdt_usd_priceFeed,
            i_eth_usd_priceFeed,
            18
        );

        int256 priceOfTokensInUsdt = int256(
            multiply(uint256(amount), s_usdtPrice)
        );

        int256 formmatedPriceOfTokensInUsdt = _scalePrice(
            priceOfTokensInUsdt,
            6,
            18
        );

        return ((formmatedPriceOfTokensInUsdt * usdtPriceInETH) / 1e18);
    }

    function updateUsdt(IERC20 usdt) external onlyOwner {
        s_usdt = usdt;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        s_usdtPrice = newPrice;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function buyTokensNative() external payable {
        uint256 usdt_amount = multiply(
            msg.value,
            uint256(_getETHPriceInUSDT())
        );
        uint256 tokenAmount = _getTokensForUSDT(usdt_amount);

        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            tokenAmount;
        s_tokenSold = s_tokenSold + tokenAmount;

        (bool sent, ) = payable(fundDistributor).call{value: msg.value}("");
        require(sent, "Funds transfer unsuccesfull");
        s_totalUSDTRaised = tokenAmount.div(1 ether).mul(s_usdtPrice);
        emit BoughtWithNativeToken(msg.sender, tokenAmount, block.timestamp);
    }

    function buyTokensUSDT(uint256 amount) external {
        uint256 tokenAmount = _getTokensForUSDT(amount);
        uint256 formattedToken = tokenAmount * 1 ether;
        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            formattedToken;
        s_tokenSold = s_tokenSold + formattedToken;
        s_usdt.safeTransferFrom(msg.sender, fundDistributor, amount);
        s_totalUSDTRaised = s_totalUSDTRaised + amount;
        emit BoughtWithUSDT(msg.sender, formattedToken, block.timestamp);
    }

    function buyTokensAPI(
        address user,
        uint256 tokenAmount
    ) external payable whenNotPaused nonReentrant onlyManager {
        s_investemetByAddress[user] = s_investemetByAddress[user] + tokenAmount;
        s_tokenSold = s_tokenSold + tokenAmount;

        uint256 usdt_amount = tokenAmount.mul(s_usdtPrice).div(1 ether);

        (bool sent, ) = payable(fundDistributor).call{value: msg.value}("");
        s_totalUSDTRaised = s_tokensForSale + usdt_amount;
        require(sent, "Funds transfer unsuccesfull");
        emit BoughtWithAPI(user, tokenAmount, block.timestamp);
    }

    function allocateTokens(address user, uint256 amount) external onlyManager {
        s_investemetByAddress[user] = s_investemetByAddress[user] + amount;
    }

    function claim() external {
        require(
            s_investemetByAddress[msg.sender] > 0,
            "You dont have enough tokens to claim"
        );
        require(block.timestamp >= s_claimDate, "You cannot claim now");
        uint256 claimableToken = s_investemetByAddress[msg.sender];
        require(
            IERC20(s_dcdtoken).balanceOf(address(this)) >= claimableToken,
            "Not enough tokens"
        );
        require(IERC20(s_dcdtoken).transfer(msg.sender, claimableToken));
    }

    function updateDCDToken(address newToken) external onlyOwner {
        s_dcdtoken = newToken;
    }

    function updateClaimDate(uint256 newClaimDate) external onlyOwner {
        s_claimDate = newClaimDate;
    }

    function updateTokenForSale(uint256 newTokenForSale) external onlyOwner {
        s_tokensForSale = newTokenForSale;
    }

    function addManager(address user, bool isManager) external onlyOwner {
        s_managers[user] = isManager;
    }

    function updateFundDistributor(
        address _fundDistributor
    ) external onlyOwner {
        fundDistributor = _fundDistributor;
    }
}
