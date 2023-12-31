// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract GrowabilitySalesContract is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using PriceConverter for uint256;
    uint256 public minimumUSDAmount;
    uint256 public exchangeRate;
    IERC20 public token;

    event TokenPurchased(address indexed buyer, uint256 amount, uint256 cost);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        minimumUSDAmount = 50 * 1e18;
        exchangeRate = 0; // 1 USD = 24 GROW
        token = IERC20(0x96CE6004AFd275B16327285A41396a1584084Ef5);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setExchangeRate(uint256 rate) public onlyOwner {
        exchangeRate = rate;
    }

    function setMinimalUsdAmount(uint256 amount) public onlyOwner {
        minimumUSDAmount = amount;
    }

    function fund() external payable whenNotPaused {
        // Ensure that the sender is not the zero address
        require(msg.sender != address(0), "Invalid sender address");

        // Ensure that the amount is greater than 0
        require(msg.value > 0, "Invalid amount");

        uint amountInUSD = msg.value.getConversionRate();

        require(amountInUSD >= minimumUSDAmount, "Amount is too small");
    }

    function getContractBalance() public view onlyOwner returns (uint) {
        return token.balanceOf(address(this));
    }

    function transferAllTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
