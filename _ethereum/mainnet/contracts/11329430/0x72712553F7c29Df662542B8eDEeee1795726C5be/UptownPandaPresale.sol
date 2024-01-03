// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUptownPanda.sol";
import "./IUniswapV2Helper.sol";
import "./IUptownPandaFarm.sol";

contract UptownPandaPresale is Ownable {
    using SafeMath for uint256;

    event InvestmentSucceeded(address sender, uint256 weiAmount, uint256 upAmount);

    mapping(address => bool) public whitelistAddresses; // all addresses eligible for presale
    mapping(address => uint256) public investments; // total WEI invested per address (1ETH = 1e18WEI)
    uint256 public whitelistAddressesCount; // total count of whitelisted addresses

    address public immutable uptownPandaAddress; // address of $UP token
    address public immutable uniswapRouterAddress; // address of uniswap router
    address public immutable liquidityLockAddress; // address where liquidity pool tokens will be locked for 2 years
    address payable public immutable teamAddress; // address where invested ETH will be transfered to

    uint256 public constant UP_FARM_INITIAL_SUPPLY = 27500 * 1 ether;
    uint256 public constant UP_ETH_FARM_INITIAL_SUPPLY = 55000 * 1 ether;
    uint256 public constant WETH_FARM_INITIAL_SUPPLY = 7500 * 1 ether;
    uint256 public constant WBTC_FARM_INITIAL_SUPPLY = 7500 * 1 ether;

    address public immutable upFarmAddress; // address for farming with $UPs
    address public immutable upEthFarmAddress; // address for farming with $UP-ETH uniswap token
    address public immutable wethFarmAddress; // address for farming with WETH
    address public immutable wbtcFarmAddress; // address for farming with WBTC
    address private immutable wbtcAddress; // address to use for WBTC farm intialization

    uint256 public immutable PRESALE_WEI_HARD_CAP; // max amount of ETH collected in presale (in WEI)
    uint256 public constant PRESALE_PRICE_MULTIPLIER = 3; // how many times more $UP presale investor receives vs listing price
    uint256 public constant INVESTMENT_LIMIT = 2.5 * 1 ether; // 2.5 ETH is maximum investment limit
    uint256 public presaleWeiSupplyLeft; // how many WEI are still available in presale

    bool public isPresaleActive = false; // investing is only allowed if presale is active
    bool public allowWhitelistAddressesOnly = true; // if true only addresses found on whitelist can participate
    bool public wasPresaleEnded = false; // indicates that presale is ended and liqudity is provided

    IUptownPanda private immutable uptownPanda;
    IUniswapV2Router02 private immutable uniswapRouter;

    constructor(
        address _uptownPandaAddress,
        address _uniswapV2HelperAddress,
        address _liquidityLockAddress,
        address _teamAddress,
        address _upFarmAddress,
        address _upEthFarmAddress,
        address _wethFarmAddress,
        address _wbtcFarmAddress,
        address _wbtcAddress,
        uint256 _presaleEthSupply
    ) public {
        uptownPandaAddress = _uptownPandaAddress;
        uptownPanda = IUptownPanda(_uptownPandaAddress);

        address resolvedUniswapRouterAddress = IUniswapV2Helper(_uniswapV2HelperAddress).getRouterAddress();
        uniswapRouterAddress = resolvedUniswapRouterAddress;
        uniswapRouter = IUniswapV2Router02(resolvedUniswapRouterAddress);

        liquidityLockAddress = _liquidityLockAddress;
        teamAddress = payable(_teamAddress);

        upFarmAddress = _upFarmAddress;
        upEthFarmAddress = _upEthFarmAddress;
        wethFarmAddress = _wethFarmAddress;
        wbtcFarmAddress = _wbtcFarmAddress;
        wbtcAddress = _wbtcAddress;

        presaleWeiSupplyLeft = _presaleEthSupply * 1 ether;
        PRESALE_WEI_HARD_CAP = presaleWeiSupplyLeft;
    }

    function addWhitelistAddresses(address[] calldata _whitelistAddresses) external onlyOwner {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelistAddresses[_whitelistAddresses[i]] = true;
            whitelistAddressesCount = whitelistAddressesCount.add(1); 
        }
    }

    function setIsPresaleActive(bool _isPresaleActive) external onlyOwner {
        if (_isPresaleActive && !uptownPanda.isInitialized()) {
            uptownPanda.initialize(
                address(this),
                uniswapRouter.WETH(),
                upFarmAddress,
                upEthFarmAddress,
                wethFarmAddress,
                wbtcFarmAddress
            );
        }
        isPresaleActive = _isPresaleActive;
    }

    function setAllowWhitelistAddressesOnly(bool _allowWhitelistAddressesOnly) external onlyOwner {
        allowWhitelistAddressesOnly = _allowWhitelistAddressesOnly;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Presale is currently not active.");
        _;
    }

    modifier presaleNotEnded {
        require(!wasPresaleEnded, "Presale was ended.");
        _;
    }

    modifier presaleContractIsMinter {
        require(uptownPanda.getMinter() == address(this), "Presale contract can't mint $UP tokens.");
        _;
    }

    modifier eligibleForPresale() {
        require(!allowWhitelistAddressesOnly || whitelistAddresses[_msgSender()], "Your address is not whitelisted.");
        _;
    }

    modifier presaleSupplyAvailable() {
        require(presaleWeiSupplyLeft > 0, "Presale cap has been reached.");
        _;
    }

    modifier presaleSupplyNotExceeded() {
        require(msg.value <= presaleWeiSupplyLeft, "The amount of ETH sent exceeds the ETH supply left in presale.");
        _;
    }

    receive()
        external
        payable
        presaleActive
        presaleNotEnded
        presaleContractIsMinter
        eligibleForPresale
        presaleSupplyAvailable
        presaleSupplyNotExceeded
    {
        uint256 addressTotalInvestment = investments[_msgSender()].add(msg.value);
        require(addressTotalInvestment <= INVESTMENT_LIMIT, "Max investment per address is 2.5 ETH.");

        uint256 listingPriceMultiplier = uptownPanda.getListingPriceMultiplier();
        uint256 upsToMint = msg.value.mul(listingPriceMultiplier).mul(PRESALE_PRICE_MULTIPLIER);
        uptownPanda.mint(_msgSender(), upsToMint);

        investments[_msgSender()] = addressTotalInvestment;
        presaleWeiSupplyLeft = presaleWeiSupplyLeft.sub(msg.value);

        emit InvestmentSucceeded(_msgSender(), msg.value, upsToMint);
    }

    function endPresale() external onlyOwner presaleNotEnded {
        uint256 listingPriceMultiplier = uptownPanda.getListingPriceMultiplier();
        uint256 liquidityPoolEths = address(this).balance.mul(60).div(100); // 60% goes to liquidity pool FOREVER
        uint256 liquidityPoolUps = liquidityPoolEths.mul(listingPriceMultiplier);

        uptownPanda.mint(address(this), liquidityPoolUps); // mint $UPs for liquidity pool and assign them to presale address
        uptownPanda.approve(address(uniswapRouter), liquidityPoolUps); // approve uniswap router to use $UPs from this address

        address upAddress = address(uptownPanda);
        uint256 transactionDeadline = block.timestamp.add(5 minutes); // transaction should be confirmed in that timeframe
        uniswapRouter.addLiquidityETH{ value: liquidityPoolEths }(
            upAddress,
            liquidityPoolUps,
            liquidityPoolUps,
            liquidityPoolEths,
            liquidityLockAddress,
            transactionDeadline
        );

        // start up farm
        uptownPanda.mint(upFarmAddress, UP_FARM_INITIAL_SUPPLY);
        IUptownPandaFarm(upFarmAddress).startFarming(uptownPandaAddress, uptownPandaAddress, UP_FARM_INITIAL_SUPPLY);

        // start up/eth farm
        uptownPanda.mint(upEthFarmAddress, UP_ETH_FARM_INITIAL_SUPPLY);
        IUptownPandaFarm(upEthFarmAddress).startFarming(
            uptownPandaAddress,
            uptownPanda.uniswapPair(),
            UP_ETH_FARM_INITIAL_SUPPLY
        );

        // start weth farm
        uptownPanda.mint(wethFarmAddress, WETH_FARM_INITIAL_SUPPLY);
        IUptownPandaFarm(wethFarmAddress).startFarming(
            uptownPandaAddress,
            uniswapRouter.WETH(),
            WETH_FARM_INITIAL_SUPPLY
        );

        // start wbtc farm
        uptownPanda.mint(wbtcFarmAddress, WBTC_FARM_INITIAL_SUPPLY);
        IUptownPandaFarm(wbtcFarmAddress).startFarming(uptownPandaAddress, wbtcAddress, WBTC_FARM_INITIAL_SUPPLY);

        teamAddress.transfer(address(this).balance); // remaining ETHs (40%) go to the team address
        uptownPanda.unlock(); // after liquidity is provided, tokens are unlocked
        wasPresaleEnded = true; // presale is ended so endPresale can't be called again
        isPresaleActive = false; // presale should not be active anymore
    }
}
