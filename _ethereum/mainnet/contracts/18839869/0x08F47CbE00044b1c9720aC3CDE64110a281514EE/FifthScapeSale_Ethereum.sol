// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFifthScapeVesting.sol";
import "./AggregatorV3Interface.sol";

contract FifthScapeSale_Ethereum is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public s_usdt;
    IFifthScapeVesting public s_vesting;

    address public i_eth_usd_priceFeed;
    address public i_usdt_usd_priceFeed;

    uint256 public s_usdtPrice = 1870;
    uint256 public s_minAmountToInvest = 100000000;
    uint256 public s_maxAmountToInvest = 5000000000;
    uint256 public s_tokensForSale = 1250000 ether;
    uint256 public s_tokenSold;

    mapping(address => uint256) public s_investemetByAddress;

    constructor(
        address _vesting,
        address _usdt,
        address _owner
    ) Ownable(_owner) {
        if (block.chainid == 1) {
            i_eth_usd_priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
            i_usdt_usd_priceFeed = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
            s_vesting = IFifthScapeVesting(_vesting);
            s_usdt = IERC20(_usdt);
        } else {
            i_eth_usd_priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
            i_usdt_usd_priceFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
            s_vesting = IFifthScapeVesting(_vesting);
            s_usdt = IERC20(_usdt);
        }
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

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

    function _getPriceOfGivenTokenInETH(
        int256 amount
    ) public view returns (int256) {
        // 1000000 = below pricce
        int256 usdtPriceInETH = _getDerivedPrice(
            i_usdt_usd_priceFeed,
            i_eth_usd_priceFeed,
            18
        );

        int256 priceOfTokensInUsdt = int256(
            multiply(uint256(amount), s_usdtPrice)
        ); // 6 decimal answer

        int256 formmatedPriceOfTokensInUsdt = _scalePrice(
            priceOfTokensInUsdt,
            6,
            18
        );

        return ((formmatedPriceOfTokensInUsdt * usdtPriceInETH) / 1e18);
    }

    function buyTokensETH(
        uint256 amount
    ) external payable whenNotPaused nonReentrant {
        require(
            s_tokenSold <= s_tokensForSale,
            "FifthScapeSale_Ethereum: All Tokens Solded Out"
        );

        uint256 payableAmountInETH = uint256(
            _getPriceOfGivenTokenInETH(int256(amount))
        );

        uint256 tokenAmount = amount * (10 ** 18);

        require(
            msg.value >= payableAmountInETH,
            "FifthScapeSale_Ethereum: Not enough funds to buy tokens"
        );

        uint256 payableAmountUSDT = multiply(amount, s_usdtPrice);

        require(
            payableAmountUSDT >= s_minAmountToInvest,
            "FifthScapeSale_Ethereum: Less than Minimum investment"
        );

        require(
            s_investemetByAddress[msg.sender] + payableAmountUSDT <=
                s_maxAmountToInvest,
            "FifthScapeSale_Ethereum: Exceeding maximum limit"
        );

        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            payableAmountUSDT;

        s_vesting.allocateTokensManager(msg.sender, tokenAmount);
        s_tokenSold = s_tokenSold + tokenAmount;
    }

    function buyTokensUSDT(uint256 amount) external whenNotPaused nonReentrant {
        require(
            s_tokenSold <= s_tokensForSale,
            "FifthScapeSale_Ethereum: All Tokens Solded Out"
        );
        uint256 tokenAmount = amount * (10 ** 18);
        uint256 payableAmount = multiply(amount, s_usdtPrice);

        require(
            payableAmount >= s_minAmountToInvest,
            "FifthScapeSale_Ethereum: Less than Minimum investment"
        );
        require(
            s_investemetByAddress[msg.sender] + payableAmount <=
                s_maxAmountToInvest,
            "FifthScapeSale_Ethereum: Exceeding maximum limit"
        );

        s_investemetByAddress[msg.sender] =
            s_investemetByAddress[msg.sender] +
            payableAmount;
        s_usdt.safeTransferFrom(msg.sender, owner(), payableAmount);
        s_vesting.allocateTokensManager(msg.sender, tokenAmount);
        s_tokenSold = s_tokenSold + tokenAmount;
    }

    function updateMaxInvestment(uint256 amount) external onlyOwner {
        s_maxAmountToInvest = amount;
    }

    function updateMinInvestment(uint256 amount) external onlyOwner {
        s_minAmountToInvest = amount;
    }

    function updateUsdt(IERC20 usdt) external onlyOwner {
        s_usdt = usdt;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        s_usdtPrice = newPrice;
    }

    function updateVesting(address newVesting) external onlyOwner {
        s_vesting = IFifthScapeVesting(newVesting);
    }

    function updatePriceFeeds(
        address _eth_usd,
        address _usdt_usd
    ) external onlyOwner {
        i_eth_usd_priceFeed = _eth_usd;
        i_usdt_usd_priceFeed = _usdt_usd;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function withdrawERC20(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20 currentToken = IERC20(_tokenAddress);
        currentToken.approve(address(this), _amount);
        currentToken.safeTransferFrom(address(this), owner(), _amount);
    }

    function withdrawNative(uint256 _amount) external onlyOwner {
        (bool hs, ) = payable(owner()).call{value: _amount}("");
        require(hs, "EnergiWanBridge:: Failed to withdraw native coins");
    }
}
