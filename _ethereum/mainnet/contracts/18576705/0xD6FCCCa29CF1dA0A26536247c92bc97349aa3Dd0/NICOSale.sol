/**
 *Submitted for verification at Etherscan.io on 2023-11-14
*/

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: NICOsale.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract NICOSale {
    address public taxReceiver;
    address public admin;
    IERC20 public NICOToken;
    IERC20 public usdcToken;
    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public tokenPrice = 0.35 * 1e6; // 1 NICO = 0.35 usdc

    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice
    );

    constructor(
        address _NICOTokenAddress,
        address _usdcTokenAddress,
        address _ethUsdPriceFeedAddress
    ) {
        admin = msg.sender;
        NICOToken = IERC20(_NICOTokenAddress);
        usdcToken = IERC20(_usdcTokenAddress);
         ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeedAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyAdmin {
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 numberOfTokens) external {
        uint256 totalPrice = numberOfTokens * tokenPrice;
        require(
            NICOToken.balanceOf(msg.sender) >= numberOfTokens,
            "Insufficient NICO balance"
        );
        require(
            usdcToken.transferFrom(
                msg.sender,
                taxReceiver,
                totalPrice / 10**18
            ),
            "Token transfer failed"
        );
        require(
            NICOToken.transfer(msg.sender, numberOfTokens),
            "Token transfer to buyer failed"
        );
        emit TokensPurchased(msg.sender, numberOfTokens, totalPrice);
    }

    function getEthPriceInUSD() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function buyTokensInEth(uint256 ethAmount) external payable {
        uint256 ethPriceInUSD = getEthPriceInUSD() / 10**8;
        uint256 ethAmountInWei = ethAmount * 10**18;
        uint256 totalPriceInCents = (ethAmountInWei * ethPriceInUSD) / 1 ether;
        uint256 numberOfTokens = (totalPriceInCents * 100) / 35; // 1 token = 0.35 USD
        require(msg.value >= ethAmount, "Insufficient ETH sent");
        payable(taxReceiver).transfer(msg.value);
        require(
            NICOToken.transfer(msg.sender, numberOfTokens),
            "Token transfer to buyer failed"
        );
        emit TokensPurchased(msg.sender, numberOfTokens, ethAmount);
    }

 
    function withdrawERC20(IERC20 _address) external onlyAdmin {
        uint256 contractBalance = _address.balanceOf(address(this));
        require(
            _address.transfer(admin, contractBalance),
            "Funds withdrawal failed"
        );
    }

    function withdrawFundsETH() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
}