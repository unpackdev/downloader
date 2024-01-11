pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./NonReentrancy.sol";
import "./TransferHelper.sol";

contract GPOLockedReworked is ERC20, Ownable, ReentrancyGuard {

    // Event is emitted anytime GPOL tokens are purchased
    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount,
        uint256 timestamp
    );
    // Event is emitted anytime GPOL is swaped to GPO
    event TokensSwaped(
        address indexed swapper,
        uint256 value,
        uint256 timestamp
    );

    // Unlock Time in seconds EPOCH
    uint256 public lockedUntil;
    // Total Vesting Time in seconds 
    uint256 public vestingTime;
    // Token Name
    string public _name = "GoldPesa Option Locked";
    // Token Symbol
    string public _symbol = "GPOL";
    // GPO Contract address
    IERC20 public gpo;
    // Chainlink Aggregator used to retrieve the live Ethereum price
    AggregatorV3Interface internal priceFeed;

    // Wallet address where sale funds are transferred to
    address payable public fundWallet;
    // Price per token in USD Cents
    uint256 public priceInUSDCents;

    mapping(address => uint256) public balancesSold;
    mapping(address => uint256) public balancesSwap;
    // Total Sale Amount 
    uint256 public amountSold;

    constructor(address _gpoAddress,
        uint256 _priceInUSDCents,
        address _ethUsdAggregator,
        address payable _fundWallet,
        uint256 _lockedUntil,
        uint256 _vestingTime) 
        
        ERC20(_name, _symbol)
    {
        gpo = IERC20(_gpoAddress);
        priceInUSDCents = _priceInUSDCents;
        priceFeed = AggregatorV3Interface(_ethUsdAggregator);
        fundWallet = _fundWallet;
        lockedUntil = _lockedUntil;
        amountSold = 0;
        vestingTime = _vestingTime;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from == address(this) || to == address(this) || from == address(0x0), "GPOLs are not transferrable");
    }

    // fetches the price of each token in Ethereum at the moment of the purchase
    function getSalePriceInETH() public view returns (uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return (priceInUSDCents * 10**24) / uint256(price);
    }
    // Amount of GPO per Ethereum
    function tentativeAmountGPOPerETH(uint256 amount) public view returns (uint256) {
        return (amount * 10**18) / getSalePriceInETH();
    }

    function availableAmount() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function addGPOsToSale(uint256 amount) public onlyOwner {
        require(gpo.balanceOf(address(this)) - availableAmount() >= amount, "Must transfer the exact amount of GPOs to the sale");
        _mint(address(this), amount);
    }

    function buyTokens() public payable nonReentrant {
        require(msg.value > 0, "Has to be > 0 eth");
        uint256 tentativeAmountGPO = tentativeAmountGPOPerETH(msg.value);
        require(availableAmount() >= tentativeAmountGPO, "Do not have enough GPO");
        _transfer(address(this), _msgSender(), tentativeAmountGPO);
        balancesSold[_msgSender()] += tentativeAmountGPO;
        amountSold += tentativeAmountGPO;
        emit TokensPurchased(_msgSender(), msg.value, tentativeAmountGPO, block.timestamp);
        transferFunds();
    }

    function swapGPOLtoGPO(uint256 amountIn) external {
        require(block.timestamp >= lockedUntil, "Cannot swap during the lock period");
        require(balanceOf(_msgSender()) >= amountIn, "GPOL balance is too low for this tx");
        require(amountIn <= unlockedGPOAllowance(_msgSender()), "Not enough unlocked GPOs atm");
        _burn(_msgSender(), amountIn);
        gpo.transfer(_msgSender(), amountIn);
        balancesSwap[_msgSender()] += amountIn;
        emit TokensSwaped(_msgSender(), amountIn, block.timestamp);
    }

    function unlockedGPOAllowance(address account) public view returns (uint256) {
        if (block.timestamp < lockedUntil) return 0;
        if (vestingTime == 0) return balancesSold[account];
        uint256 theoreticalAllowance = ((block.timestamp - lockedUntil) * balancesSold[account]) / vestingTime;
        return theoreticalAllowance - balancesSwap[account];
    }

    function setFundWallet(address payable _fundWallet) external onlyOwner {
        fundWallet = _fundWallet;
    }

    function transferFunds() internal {
        fundWallet.transfer(address(this).balance);
    } 
}