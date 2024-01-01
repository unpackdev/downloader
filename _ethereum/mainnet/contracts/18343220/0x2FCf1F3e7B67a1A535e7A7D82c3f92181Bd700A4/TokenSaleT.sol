// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeMath.sol";


interface IVestingContract {
    function getAvailableTokensForCategory(uint8 category) external view returns (uint256);
    function setAllocation(address recipient_, uint256 amount_, uint8 allocationType_) external;
}



contract TokenSale {

    using SafeMath for uint256;

    address internal  constant VESTING_CONTRACT_ADDRESS = 0xFA6526E7AA86178995F51689F334646620D76247;
    address internal  constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;


    address public owner;


    IERC20 public usdtToken;



    bool public isSaleActive = true;

    enum SalePhase { NONE, PRESALE, PRIVATE1, PRIVATE2 }
    SalePhase public currentPhase = SalePhase.PRESALE;

    struct PhaseInfo {
        uint256 price;
        uint256 minDeposit;
        uint256 maxDeposit;
    }

    mapping(SalePhase => PhaseInfo) public phaseInfo;

    constructor() {
        owner = msg.sender;


        usdtToken = IERC20(USDT_ADDRESS);

        phaseInfo[SalePhase.PRESALE] = PhaseInfo(150, 10e6, 50000e6);
        phaseInfo[SalePhase.PRIVATE1] = PhaseInfo(200, 1000e6, 300000e6);
        phaseInfo[SalePhase.PRIVATE2] = PhaseInfo(300, 1000e6, 500000e6);
    }

    event TokensPurchased(address indexed buyer, uint256 usdtAmount, uint256 tokenAmount);
    event Withdrawn(address indexed to, uint256 amount);
    event SaleStarted();
    event SaleStopped();
    event PhaseSet(SalePhase newPhase);


    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier saleIsActive() {
        require(isSaleActive, "Token sale is not active");
        _;
    }

    function setPhase(SalePhase _phase) external onlyOwner {
        currentPhase = _phase;
         emit PhaseSet(_phase);
    }

    function getUSDTBalance(address account) public view returns (uint256) {
        return usdtToken.balanceOf(account);
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
         emit SaleStarted();
    }

    function stopSale() external onlyOwner {
        isSaleActive = false;
        emit SaleStopped();
    }



    function getAvailableTokensForSale() external view returns (uint256) {

        if (currentPhase == SalePhase.NONE) {
            return 0;
        }

        IVestingContract vestingContract = IVestingContract(VESTING_CONTRACT_ADDRESS);
        return vestingContract.getAvailableTokensForCategory(uint8(currentPhase) + 3);
    }



    function withdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount should be greater than 0");  // Добавленная проверка
        require(usdtToken.balanceOf(address(this)) >= amount, "Not enough USDT on the contract's balance");

        usdtToken.transfer(to, amount);
        emit Withdrawn(to, amount);
    }






    function buyTokens(uint256 usdtAmount) external {
        require(currentPhase != SalePhase.NONE, "Sale not started");
        PhaseInfo memory currentInfo = phaseInfo[currentPhase];

        require(usdtAmount >= currentInfo.minDeposit && usdtAmount <= currentInfo.maxDeposit, "Invalid USDT amount");


        require(usdtToken.balanceOf(msg.sender) >= usdtAmount, "Not enough USDT on your balance");


        uint256 tokenAmount = usdtAmount.div(currentInfo.price).mul(1000000000000000);

       // uint256 tokenAmount = usdtAmount.div(currentInfo.price).mul(1000000000000);

       
                          
        require(usdtToken.allowance(msg.sender, address(this)) >= usdtAmount);

        IVestingContract vestingContract = IVestingContract(VESTING_CONTRACT_ADDRESS);

        uint256 availableTokens = vestingContract.getAvailableTokensForCategory(uint8(currentPhase) + 3); // Соответствие фазам: 1 => 4, 2 => 5, 3 => 6


        require(availableTokens >= tokenAmount, "Not enough tokens available for sale");

        usdtToken.transferFrom(msg.sender, address(this), usdtAmount);


        vestingContract.setAllocation(msg.sender, tokenAmount, uint8(currentPhase) + 3); // Соответствие фазам: 1 => 4, 2 => 5, 3 => 6    

        emit TokensPurchased(msg.sender, usdtAmount, tokenAmount);


    }

  
}
