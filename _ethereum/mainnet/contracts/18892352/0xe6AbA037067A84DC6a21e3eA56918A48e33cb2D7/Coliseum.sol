// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";


interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
   
}


contract Coliseum is ERC20, Ownable {
    IERC20 public token;

    struct VestingDetails {
        uint256 vestingStartTime;
        uint256 vestingDuration;
        uint256 totalTokens;
        uint256 releasedTokens;
    }

    mapping(address => VestingDetails) public beneficiaries;
    address[] public beneficiaryList;

    // for swap
    mapping(address => uint256) public totalTransferred;


    uint256 public maxSupply = 27000000 * 10**decimals();
    
    //swap percentage
    uint256 public maxTransferPercentage;

    uint256 public totalMinted;
    bool public mintingPaused;
    uint256 public maxMintPerTransaction;
    uint256 public transferFee;
    uint256 public totalSwapped;

    // Admin configurable unlock parameters
    uint256 public unlockPercentage;
    uint256 public unlockTimePeriod; // 

    // Address of the Uniswap router contract
    address public uniswapRouter;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() ERC20("COLISEUM", "CMAX") {
        totalMinted = 0;
        mintingPaused = false;
        transferFee = 0; // Default transfer fee is 0%
        uniswapRouter = address(0); // Initialize with the zero address
        maxTransferPercentage = 0;
    }

    modifier mintingNotPaused() {
        require(!mintingPaused, "Minting is paused");
        _;
    }




    function mint(address to, uint256 amount) public onlyOwner mintingNotPaused  {
        require(totalMinted + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
        totalMinted += amount;
        beneficiaries[to].releasedTokens += amount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // Set unlock percentage
  function setUnlockPercentage(uint256 _unlockPercentage) external onlyOwner {
    require(_unlockPercentage <= 100, "Invalid percentage");
    unlockPercentage = _unlockPercentage;
  }

  // Set unlock time period 
  function setUnlockTimePeriod(uint256 _unlockTimePeriod) external onlyOwner {
    require(_unlockTimePeriod > 0, "Invalid time period");
    unlockTimePeriod = _unlockTimePeriod;
  }

   function setMaxTransferPercentage(uint256 _maxTransferPercentage) external onlyOwner {
        require(_maxTransferPercentage <= 100, "Invalid transfer percentage");
        maxTransferPercentage = _maxTransferPercentage;
    }


  function _transfer(
    address sender, 
    address recipient,
    uint256 amount
  ) internal override(ERC20) {
    
    // Fee logic
    uint256 feeAmount = (amount * transferFee) / 100;
    uint256 afterFeeAmount = amount - feeAmount;
    

       VestingDetails storage senderDetails = beneficiaries[sender];
    if (senderDetails.vestingStartTime > 0 &&
        block.timestamp >= senderDetails.vestingStartTime) {

        uint256 elapsedTime = block.timestamp - senderDetails.vestingStartTime;

        // Use unlock time period instead of total vesting duration
        uint256 vestedTokens = (elapsedTime * senderDetails.totalTokens) / unlockTimePeriod;

        // Calculate allowed transfer amount based on unlock percentage
        uint256 allowedTransfer = (vestedTokens * unlockPercentage) / 100;

        // Check both unlock time period and unlock percentage conditions
        require(elapsedTime >= unlockTimePeriod && afterFeeAmount <= allowedTransfer, "Transfer conditions not met");
    }

    // Check swap limit based on the percentage of total supply (if maxTransferPercentage is greater than 0)
   if (maxTransferPercentage > 0) {
    uint256 maxTransferLimit = (maxTransferPercentage * maxSupply) / 100;
    require(totalTransferred[sender] + afterFeeAmount <= maxTransferLimit, "Exceeds max Swap percentage");
    totalTransferred[sender] += afterFeeAmount;
   }


    // Token transfers
    super._transfer(sender, recipient, afterFeeAmount);

    if (feeAmount > 0) {
      super._transfer(sender, address(0xA66bE600dA9315486a0830ddBe502B967D4cCc34), feeAmount);
    }
  }


  function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external {
        IERC20Token(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20Token(_tokenIn).approve(uniswapRouter,  _amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;

        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );

    }

    function setTransferFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee cannot exceed 100%");
        transferFee = _fee;
    }

    function setUniswapRouter(address _router) external onlyOwner {
        uniswapRouter = _router;
    }

    function pauseMinting() external onlyOwner {
        mintingPaused = true;
    }

    function resumeMinting() external onlyOwner {
        mintingPaused = false;
    }

    function getRemainingSwapAmount(address wallet) external view returns (uint256) {
        uint256 remainingSwap = (maxSupply * 2) / 100 - totalSwapped;
        return remainingSwap;
    }

    function addBeneficiaries(
        address[] memory _addresses,
        uint256[] memory _vestingStartTimes,
        uint256[] memory _vestingDurations,
        uint256[] memory _totalTokens
    ) external onlyOwner {
        require(
            _addresses.length == _vestingStartTimes.length &&
            _vestingStartTimes.length == _vestingDurations.length &&
            _vestingDurations.length == _totalTokens.length,
            "Invalid input lengths"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            address beneficiary = _addresses[i];
            require(beneficiary != address(0), "Invalid beneficiary address");
            require(_vestingStartTimes[i] >= block.timestamp, "Invalid vesting start time");
            require(_vestingDurations[i] > 0, "Invalid vesting duration");
            require(_totalTokens[i] > 0, "Invalid total tokens");

            beneficiaries[beneficiary] = VestingDetails({
                vestingStartTime: _vestingStartTimes[i],
                vestingDuration: _vestingDurations[i],
                totalTokens: _totalTokens[i],
                releasedTokens: 0
            });

            beneficiaryList.push(beneficiary);
        }
    }

function airdrop() external onlyOwner {

  for (uint256 i = 0; i < beneficiaryList.length; i++) {
    address beneficiary = beneficiaryList[i];

    if (beneficiaries[beneficiary].vestingStartTime > 0 && 
        block.timestamp >= beneficiaries[beneficiary].vestingStartTime) {
        
      uint256 totalVestedTokens = beneficiaries[beneficiary].totalTokens;
      
      beneficiaries[beneficiary].releasedTokens = totalVestedTokens; 

      _transfer(address(this), beneficiary, totalVestedTokens);
    }
  }
}
}