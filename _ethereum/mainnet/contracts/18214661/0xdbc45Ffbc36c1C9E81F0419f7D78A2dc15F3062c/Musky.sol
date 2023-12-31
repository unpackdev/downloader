// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Musky is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public teamMusky;
    uint256 public tokenPrice = 694200000000; 
    uint256 public bonusPercentage = 5;
    uint256 public maxSupply;
    uint256 public FeePercentage = 42;

    bool public liquidityPoolOpen = false;
    bool public presaleOpen = true;

    event TokensBought(address indexed buyer, uint256 amount);
    event LiquidityPoolOpened();
    event BuyTokensToggled();
    event Withdrawn(address indexed recipient, uint256 amount);
    event BonusPercentageChanged(uint256 newBonusPercentage);

    modifier onlypresaleOpen() {
        require(presaleOpen, "Pre-Sale Closed");
        _;
    }

    modifier onlyteamMusky() {
        require(msg.sender == teamMusky, "Only teamMusky can call this function");
        _;
    }

    constructor(
        address _teamMusky
    ) ERC20("MUSKY THE HUSKY", "BONES") {
        teamMusky = _teamMusky;

        maxSupply = 100000000000 * 10 ** decimals();

        uint256 amountForteamMusky = maxSupply * 10 / 100;

        _mint(teamMusky, amountForteamMusky);
        transferOwnership(_teamMusky);
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        require(liquidityPoolOpen || msg.sender == teamMusky, "Token transfer is not allowed until the liquidity pool is open");

        if (msg.sender != teamMusky) {

            uint256 fee = amount.mul(FeePercentage).div(1000); 
            _transfer(msg.sender, teamMusky, fee);
            amount = amount.sub(fee);
        }

        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        require(liquidityPoolOpen || sender == teamMusky, "Token transfer is not allowed until the liquidity pool is open");

        if (sender != teamMusky) {

            uint256 fee = amount.mul(FeePercentage).div(1000);
            _transfer(sender, teamMusky, fee);
            amount = amount.sub(fee);
        }

        return super.transfer(recipient, amount);
    }

    function changeBonusPercentage(uint256 newBonusPercentage) external onlyteamMusky {
        require(newBonusPercentage >= 0, "Bonus percentage cannot be negative");
        bonusPercentage = newBonusPercentage;
        emit BonusPercentageChanged(newBonusPercentage);
    }

    function toggleBuyTokens() external onlyteamMusky {
        presaleOpen = !presaleOpen;
        emit BuyTokensToggled();
    }

    function openLiquidityPool() external onlyteamMusky {
        liquidityPoolOpen = true;
        emit LiquidityPoolOpened();
    }

    function withdraw() external onlyteamMusky nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");

        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawn(_msgSender(), balance);
    }

    function buyTokens(uint256 bonusCondition) external payable nonReentrant onlypresaleOpen {
        uint256 ethAmount = msg.value;
        require(ethAmount > 0, "Must send a non-zero ETH amount to buy tokens");

        uint256 amountToMint = ethAmount.mul(10 ** decimals()).div(tokenPrice);
      
        uint256 bonusPercentageToApply = bonusCondition == 1 ? 10 : bonusPercentage;
        uint256 bonusAmount = amountToMint.mul(bonusPercentageToApply).div(100);

        amountToMint = amountToMint.add(bonusAmount);

        require(totalSupply().add(amountToMint) <= maxSupply, "Exceeds maximum supply");

        uint256 feeAmount = amountToMint.mul(FeePercentage).div(1000);

        payable(teamMusky).transfer(ethAmount);

        _mint(teamMusky, feeAmount);

        _mint(msg.sender, amountToMint);

        emit TokensBought(msg.sender, amountToMint);
    }


    receive() external payable  {
        address payable teamMuskyPayable = payable(teamMusky);
        teamMuskyPayable.transfer(msg.value);
    }
}
