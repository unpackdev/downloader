pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Address.sol";

contract PerseusToken is ERC20, Ownable, ReentrancyGuard {

    AggregatorV3Interface internal priceFeed;
    uint256 PERUSD;
    bool canSell;

    event TokensExchanged(address indexed addr, uint256 indexed quantity);

    constructor()
        ERC20("Perseus Token", "PER")
    {
        // Prices
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        PERUSD = 50 * 10**6; // in USD cents
        canSell = true;
        
        // Tokens Emission
        uint256 M = 1000000;
        uint256 units = 10**18;

        // Founders' Tokens
        _mint(address(0xb9Cf3B8237927C23298505F909BeC9f499761008), 5 * M * units);
        _mint(address(0xDC7AF6D9a2F1C35e15d6E555dA84Cc6286B36299), 5 * M * units);

        // Company's Tokens + Private sell tokens
        _mint(address(0x66251c49503D81aBb497a916752F24D325Fce428), 30 * M * units);

        // Public sell tokens
        _mint(address(this), 10 * M * units);
    }

    function setPrice(uint256 _PERUSD) external onlyOwner {
        PERUSD = _PERUSD;
    }

    function getPrice() external view returns (uint256) {
        return PERUSD;
    }

    function setSellState(bool _canSell) external onlyOwner {
        canSell = _canSell;
    }

    function getSellState() external view returns (bool) {
        return canSell;
    }

    function decreaseContractLiquidity(uint256 _quantity) external onlyOwner {
        _burn(address(this), _quantity);
    }

    function increaseContractLiquidity(uint256 _quantity) external onlyOwner {
        _mint(address(this), _quantity);
    }

    function getETHUSD() internal view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(price > 0, "Negative ETH price");
        return uint256(price);
    }
    
    function buy() external payable nonReentrant {
        require(canSell, "Tokens sell is not open");
        uint256 ETHUSD = getETHUSD();
        uint256 PERWEI = ETHUSD / PERUSD;
        uint256 tokens = PERWEI * msg.value;
        
        _transfer(address(this), address(msg.sender), tokens);
    }

    function withdraw() external onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function exchange(uint256 quantity) external nonReentrant {
        _burn(msg.sender, quantity);
        emit TokensExchanged(msg.sender, quantity);
    }
}