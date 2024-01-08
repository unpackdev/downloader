// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IFeeDistributor.sol";

contract LiquidVault is Ownable {
  /** Emitted when purchaseLP() is called to track ETH amounts */
  event EthTransferred(
      address from,
      uint amount,
      uint percentageAmount
  );

  /** Emitted when purchaseLP() is called and LP tokens minted */
  event LPQueued(
      address holder,
      uint amount,
      uint eth,
      uint infinityToken,
      uint timestamp
  );

  /** Emitted when claimLP() is called */
  event LPClaimed(
      address holder,
      uint amount,
      uint timestamp,
      uint exitFee,
      bool claimed
  );

  struct LPbatch {
      address holder;
      uint amount;
      uint timestamp;
      bool claimed;
  }

  struct LiquidVaultConfig {
      address infinityToken;
      IUniswapV2Router02 uniswapRouter;
      IUniswapV2Pair tokenPair;
      IFeeDistributor feeDistributor;
      address weth;
      address payable feeReceiver;
      uint32 stakeDuration;
      uint8 donationShare; //0-100
      uint8 purchaseFee; //0-100
  }
  
  bool public forceUnlock;
  bool private locked;

  modifier lock {
      require(!locked, "LiquidVault: reentrancy violation");
      locked = true;
      _;
      locked = false;
  }

  LiquidVaultConfig public config;

  mapping(address => LPbatch[]) public lockedLP;
  mapping(address => uint) public queueCounter;

  function seed(
      uint32 duration,
      address infinityToken,
      address uniswapPair,
      address uniswapRouter,
      address feeDistributor,
      address payable feeReceiver,
      uint8 donationShare, // LP Token
      uint8 purchaseFee // ETH
  ) public onlyOwner {
      config.infinityToken = infinityToken;
      config.uniswapRouter = IUniswapV2Router02(uniswapRouter);
      config.tokenPair = IUniswapV2Pair(uniswapPair);
      config.feeDistributor = IFeeDistributor(feeDistributor);
      config.weth = config.uniswapRouter.WETH();
      setFeeReceiverAddress(feeReceiver);
      setParameters(duration, donationShare, purchaseFee);
  }

  function getStakeDuration() public view returns (uint) {
      return forceUnlock ? 0 : config.stakeDuration;
  }

  // Could not be canceled if activated
  function enableLPForceUnlock() public onlyOwner {
      forceUnlock = true;
  }

  function setFeeReceiverAddress(address payable feeReceiver) public onlyOwner {
      require(
          feeReceiver != address(0),
          "LiquidVault: ETH receiver is zero address"
      );

      config.feeReceiver = feeReceiver;
  }

  function setParameters(uint32 duration, uint8 donationShare, uint8 purchaseFee)
      public
      onlyOwner
  {
      require(
          donationShare <= 100,
          "LiquidVault: donation share % between 0 and 100"
      );
      require(
          purchaseFee <= 100,
          "LiquidVault: purchase fee share % between 0 and 100"
      );

      config.stakeDuration = duration * 1 days;
      config.donationShare = donationShare;
      config.purchaseFee = purchaseFee;
  }

  function purchaseLPFor(address beneficiary) public payable lock {
      config.feeDistributor.distributeFees();
      require(msg.value > 0, "LiquidVault: ETH required to mint INFINITY LP");

      uint feeValue = (config.purchaseFee * msg.value) / 100;
      uint exchangeValue = msg.value - feeValue;

      (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

      uint infinityRequired;

      if (address(config.infinityToken) < address(config.weth)) {
          infinityRequired = config.uniswapRouter.quote(
              exchangeValue,
              reserve2,
              reserve1
          );
      } else {
          infinityRequired = config.uniswapRouter.quote(
              exchangeValue,
              reserve1,
              reserve2
          );
      }

      uint balance = IERC20(config.infinityToken).balanceOf(address(this));
      require(
          balance >= infinityRequired,
          "LiquidVault: insufficient INFINITY tokens in LiquidVault"
      );

      IWETH(config.weth).deposit{ value: exchangeValue }();
      address tokenPairAddress = address(config.tokenPair);
      IWETH(config.weth).transfer(tokenPairAddress, exchangeValue);
      IERC20(config.infinityToken).transfer(
          tokenPairAddress,
          infinityRequired
      );

      uint liquidityCreated = config.tokenPair.mint(address(this));
      config.feeReceiver.transfer(feeValue);

      lockedLP[beneficiary].push(
          LPbatch({
              holder: beneficiary,
              amount: liquidityCreated,
              timestamp: block.timestamp,
              claimed: false
          })
      );

      emit LPQueued(
          beneficiary,
          liquidityCreated,
          exchangeValue,
          infinityRequired,
          block.timestamp
      );

      emit EthTransferred(msg.sender, exchangeValue, feeValue);
  }

  //send ETH to match with INFINITY tokens in LiquidVault
  function purchaseLP() public payable {
      purchaseLPFor(msg.sender);
  }

  function claimLP() public {
      uint next = queueCounter[msg.sender];
      require(
          next < lockedLP[msg.sender].length,
          "LiquidVault: nothing to claim."
      );
      LPbatch storage batch = lockedLP[msg.sender][next];
      require(
          block.timestamp - batch.timestamp > getStakeDuration(),
          "LiquidVault: LP still locked."
      );
      next++;
      queueCounter[msg.sender] = next;
      uint donation = (config.donationShare * batch.amount) / 100;
      batch.claimed = true;
      emit LPClaimed(msg.sender, batch.amount, block.timestamp, donation, batch.claimed);
      require(
          config.tokenPair.transfer(address(0), donation),
          "LiquidVault: donation transfer failed in LP claim."
      );
      require(
          config.tokenPair.transfer(batch.holder, batch.amount - donation),
          "LiquidVault: transfer failed in LP claim."
      );
  }

  function lockedLPLength(address holder) public view returns (uint) {
      return lockedLP[holder].length;
  }

  function getLockedLP(address holder, uint position)
      public
      view
      returns (
          address,
          uint,
          uint,
          bool
      )
  {
      LPbatch memory batch = lockedLP[holder][position];
      return (batch.holder, batch.amount, batch.timestamp, batch.claimed);
  }
}