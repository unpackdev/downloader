// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./CarveToken.sol";

contract CarvePresale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router02 constant UNI_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable treasury;

    uint public PRESALE_START_TIME;
    uint256 public constant PRICE_PER_TOKEN = 1; // 0.01 ETH
    uint256 public constant MAX_ETH_PER_WALLET = 5 ether;
    uint256 public constant PRESALE_CAP = 25000 ether;
    uint256 public MAX_TOKEN_PER_WALLET = MAX_ETH_PER_WALLET.div(PRICE_PER_TOKEN).mul(100);

    uint256 public remainingSupply = PRESALE_CAP;
    mapping (address => uint256) public userBalances;

    bool public preSaleComplete = false;
    CarveToken public carve;

    constructor(CarveToken carve_, uint startTime, address payable treasury_) {
        carve = carve_;
        PRESALE_START_TIME = startTime;
        treasury = treasury_;
    }

    receive() external payable {
        require(PRESALE_START_TIME <= block.timestamp, "presale-not-started");
        uint256 amount = uint256(msg.value).div(PRICE_PER_TOKEN).mul(100);
        uint256 balance = userBalances[msg.sender];
        require(amount <= remainingSupply, "insufficient-remaining-supply");
        require(amount.add(balance) <= MAX_TOKEN_PER_WALLET, "max-per-wallet-hit");
        userBalances[msg.sender] = userBalances[msg.sender].add(amount);
        remainingSupply = remainingSupply.sub(amount);
    }

    function claim() external nonReentrant {
        require(preSaleComplete, "presale-not-finalized");
        carve.mint(msg.sender, userBalances[msg.sender]);
        userBalances[msg.sender] = 0;
    }

    function finalize() external onlyOwner {
        require(!preSaleComplete, "presale-finalized");
        uint256 amountTokensForUniswap = PRESALE_CAP.sub(remainingSupply);
        amountTokensForUniswap = amountTokensForUniswap.sub(amountTokensForUniswap.mul(190).div(1000));
        carve.mint(address(this), amountTokensForUniswap);

        uint256 ethBalance = address(this).balance;
        uint256 amountEthForTreasury = ethBalance.mul(100).div(1000);
        uint256 amountEthForUniswap = ethBalance.sub(amountEthForTreasury);

        carve.approve(address(UNI_ROUTER), amountTokensForUniswap);
        UNI_ROUTER.addLiquidityETH{value: amountEthForUniswap}
                                   (address(carve),
                                   amountTokensForUniswap,
                                   amountTokensForUniswap,
                                   amountEthForUniswap,
                                   DEAD,
                                   block.timestamp + 120);
        treasury.transfer(amountEthForTreasury);
        preSaleComplete = true;
    }
}