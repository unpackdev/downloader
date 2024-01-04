// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import "./Utilities.sol";

/// @notice This contract looks to be useful for bootstrapping/funding purposes.
contract TokenTurner is Utilities {
  /// @dev How many epochs the funding event is open.
  uint256 constant FUNDING_EPOCHS = 12;
  /// @dev The decay rate per funding epoch.
  uint256 constant DECAY_PER_EPOCH = 4; // 4 %
  /// @dev Maximum decay rate.
  uint256 constant MAX_DECAY_RATE = 100; // 100 %
  /// @dev Price of 1 `OUTPUT_TOKEN` for 1 `INPUT_TOKEN`.
  uint256 constant FUNDING_PRICE = 25e6; // 25 dai-pennies
  /// @dev The maximum epoch that needs to be reached so that the last possible funding epoch has a decay of 100%.
  uint256 constant MAX_EPOCH = FUNDING_EPOCHS + (MAX_DECAY_RATE / DECAY_PER_EPOCH);

  /// @notice The ERC-20 token this contract wants in exchange of `OUTPUT_TOKEN`. For example: DAI
  function INPUT_TOKEN () internal view virtual returns (address) {
  }

  /// @notice The ERC-20 token this contract returns in exchange of `INPUT_TOKEN`. For example: HBT
  function OUTPUT_TOKEN () internal view virtual returns (address) {
  }

  /// @notice The address of the community fund that receives the decay of `INPUT_TOKEN`.
  function COMMUNITY_FUND () internal view virtual returns (address) {
  }

  struct InflowOutflow {
    uint128 inflow;
    uint128 outflow;
  }

  /// @dev The last closed epoch this contract knows of.  Used for bookkeeping purposes.
  uint256 activeEpoch;
  /// @notice epoch > address > amount (inflow `INPUT_TOKEN`, outflow `INPUT_TOKEN`)
  mapping (uint256 => mapping (address => InflowOutflow)) public inflowOutflow;

  event Buy (address indexed buyer, uint256 indexed epoch, uint256 amount);
  event Sell (address indexed seller, uint256 indexed epoch, uint256 amount);
  event Claim (uint256 epoch, uint256 amount);

  /// @notice Returns the current epoch. Can also return zero and maximum `MAX_EPOCH`.
  function getCurrentEpoch () public view virtual returns (uint256 epoch) {
    // ~~(Date.parse('2021-03-05 20:00 UTC+1') / 1000)
    uint256 FUNDING_START_DATE = 1614899552;
    // 7 days
    uint256 EPOCH_SECONDS = 604800;
    epoch = (block.timestamp - FUNDING_START_DATE) / EPOCH_SECONDS;
    if (epoch > MAX_EPOCH) {
      epoch = MAX_EPOCH;
    }
  }

  /// @notice Returns the decay rate for `epoch`.
  /// The first week has zero decay. After each new week, the decay increases by `DECAY_PER_EPOCH`
  /// up to a maximum of `MAX_DECAY_RATE`.
  function getDecayRateForEpoch (uint256 epoch) public view returns (uint256 rate) {
    rate = (getCurrentEpoch() - epoch) * DECAY_PER_EPOCH;
    if (rate > MAX_DECAY_RATE) {
      rate = MAX_DECAY_RATE;
    }
  }

  /// @notice Used for updating the epoch and claiming any decay.
  function updateEpoch () public {
    require(msg.sender != address(this));
    uint256 currentEpoch = getCurrentEpoch();

    if (currentEpoch >= MAX_EPOCH) {
      address receiver = COMMUNITY_FUND();
      // claim everything if the decay of the last funding epoch is 100%
      uint256 balance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      if (balance > 0) {
        Utilities._safeTransfer(INPUT_TOKEN(), receiver, balance);
      }

      // and claim any remaining `OUTPUT_TOKEN`
      balance = Utilities._safeBalance(OUTPUT_TOKEN(), address(this));
      if (balance > 0) {
        Utilities._safeTransfer(OUTPUT_TOKEN(), receiver, balance);
      }
      // nothing to do anymore
      return;
    }

    if (currentEpoch > activeEpoch) {
      // bookkeeping
      activeEpoch = currentEpoch;
      uint256 balance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      uint256 claimableAmount = (balance / MAX_DECAY_RATE) * DECAY_PER_EPOCH;

      if (claimableAmount > 0) {
        emit Claim(currentEpoch, claimableAmount);
        Utilities._safeTransfer(INPUT_TOKEN(), COMMUNITY_FUND(), claimableAmount);
      }
    }
  }

  /// @notice Helper function for calculating the `inflow` and `outflow` amounts given `amountIn` and `path`.
  function getQuote (uint256 amountIn, uint256[] memory path) public view returns (uint256 inflow, uint256 outflow) {
    uint256[] memory amounts = UniswapV2Library.getAmountsOut(amountIn, path);
    inflow = amounts[amounts.length - 1];
    outflow = inflow / FUNDING_PRICE;
  }

  /// @notice Swaps `INPUT_TOKEN` or any other ERC-20 with liquidity on Uniswap(v2) for `OUTPUT_TOKEN`.
  /// @param receiver The receiver of `OUTPUT_TOKEN`.
  /// @param inputAmount The amount of `swapRoute[0]` to trade for `OUTPUT_TOKEN`.
  /// @param swapRoute First element is the address of a ERC-20 used as input.
  /// If the address is not `INPUT_TOKEN` then this array should also include addresses for Uniswap(v2) pairs
  /// to swap from. In the format:
  /// uint256(address(pair) << 1 | direction)
  /// where direction = tokenA === token0 ? 0 : 1 (See Uniswap for ordering algo)
  /// @param permitData Optional EIP-2612 signed approval for `swapRoute[0]`.
  function swapIn (
    address receiver,
    uint256 inputAmount,
    uint256[] memory swapRoute,
    bytes memory permitData
  ) external payable {
    updateEpoch();
    address fromToken = address(swapRoute[0]);

    Utilities._maybeRedeemPermit(fromToken, permitData);

    // if `fromToken` == `INPUT_TOKEN` then this maps directly to our price
    uint256 inflowAmount = inputAmount;

    if (fromToken == INPUT_TOKEN()) {
      Utilities._safeTransferFrom(fromToken, msg.sender, address(this), inflowAmount);
    } else {
      // we have to swap first
      uint256 oldBalance = Utilities._safeBalance(INPUT_TOKEN(), address(this));

      if (msg.value == 0) {
        Utilities._swapExactTokensForTokens(swapRoute, inputAmount, msg.sender, address(this));
      } else {
        Utilities._swapExactETHForTokens(swapRoute, msg.value, address(this));
      }

      uint256 newBalance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      require(newBalance > oldBalance, 'BALANCE');
      inflowAmount = newBalance - oldBalance;
    }

    uint256 currentEpoch = getCurrentEpoch();
    require(currentEpoch < FUNDING_EPOCHS, 'PRESALE_OVER');
    uint256 outflowAmount = inflowAmount / FUNDING_PRICE;
    require(outflowAmount != 0, 'ZERO_AMOUNT');

    // bookkeeping
    emit Buy(msg.sender, currentEpoch, outflowAmount);
    // practically, this should never overflow
    inflowOutflow[currentEpoch][msg.sender].inflow += uint128(inflowAmount);

    // transfer `OUTPUT_TOKEN` to `receiver`
    Utilities._safeTransfer(OUTPUT_TOKEN(), receiver, outflowAmount);
  }

  /// @notice Swaps `OUTPUT_TOKEN` back.
  /// @param receiver Address of the receiver for the returned tokens.
  /// @param inputSellAmount The amount of `OUTPUT_TOKEN` to swap back.
  /// @param epoch The epoch `OUTPUT_TOKEN` was acquired. Needed to calculate the decay rate.
  /// @param swapRoute If `swapRoute.length` is greather than 1, then
  /// this array should also include addresses for Uniswap(v2) pairs to swap to/from. In the format:
  /// uint256(address(pair) << 1 | direction)
  /// where direction = tokenA === token0 ? 0 : 1 (See Uniswap for ordering algo)
  /// For receiving `INPUT_TOKEN` back, just use `swapRoute = [0]`.
  /// If ETH is wanted, then use `swapRoute [<address of WETH>, DAI-WETH-PAIR(see above for encoding)]`.
  /// Otherwise, use `swapRoute [0, DAI-WETH-PAIR(see above for encoding)]`.
  /// @param permitData Optional EIP-2612 signed approval for `OUTPUT_TOKEN`.
  function swapOut (
    address receiver,
    uint256 inputSellAmount,
    uint256 epoch,
    uint256[] memory swapRoute,
    bytes memory permitData
  ) external {
    updateEpoch();
    uint256 currentEpoch = getCurrentEpoch();
    require(epoch <= currentEpoch, 'EPOCH');

    Utilities._maybeRedeemPermit(OUTPUT_TOKEN(), permitData);

    uint128 sellAmount = uint128(inputSellAmount * FUNDING_PRICE);
    // check available amount
    {
      // practically, this should never overflow
      InflowOutflow storage account = inflowOutflow[epoch][msg.sender];
      uint128 swappableAmount = account.inflow;
      uint128 oldOutflow = account.outflow;
      uint128 newOutflow = sellAmount + oldOutflow;
      // just to make sure
      require(newOutflow > oldOutflow);

      if (epoch != currentEpoch) {
        uint256 decay = getDecayRateForEpoch(epoch);
        swappableAmount = uint128(swappableAmount - ((swappableAmount / MAX_DECAY_RATE) * decay));
      }
      require(newOutflow <= swappableAmount, 'AMOUNT');
      account.outflow = newOutflow;
    }

    emit Sell(msg.sender, epoch, inputSellAmount);
    // take the tokens back
    Utilities._safeTransferFrom(OUTPUT_TOKEN(), msg.sender, address(this), inputSellAmount);

    if (swapRoute.length == 1) {
      Utilities._safeTransfer(INPUT_TOKEN(), receiver, sellAmount);
    } else {
      // we swap `INPUT_TOKEN`
      address wethIfNotZero = address(swapRoute[0]);
      swapRoute[0] = uint256(INPUT_TOKEN());

      if (wethIfNotZero == address(0)) {
        Utilities._swapExactTokensForTokens(swapRoute, sellAmount, address(this), receiver);
      } else {
        Utilities._swapExactTokensForETH(swapRoute, sellAmount, address(this), receiver, wethIfNotZero);
      }
    }
  }

  /// @notice Allows to recover `token` except `INPUT_TOKEN` and `OUTPUT_TOKEN`.
  /// Transfers `token` to the `COMMUNITY_FUND`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    require(token != INPUT_TOKEN() && token != OUTPUT_TOKEN());

    Utilities._safeTransfer(token, COMMUNITY_FUND(), Utilities._safeBalance(token, address(this)));
  }

  /// @notice Required for receiving ETH from WETH.
  /// Reverts if caller == origin. Helps against wrong ETH transfers.
  fallback () external payable {
    assembly {
      if eq(caller(), origin()) {
        revert(0, 0)
      }
    }
  }
}
