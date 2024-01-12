/// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import "./Withdrawable.sol";
import "./TokenTransferProxy.sol";
import "./LibSafeUtils.sol";
import "./Partner.sol";
import "./TokenBalanceLibrary.sol";
import "./SwitchBoard.sol";

import "./SafeERC20.sol";


/// @title The primary contract for Arecibo
contract AreciboPrimary is Withdrawable, Pausable {
  TokenTransferProxy public tokenTransferProxy;
  mapping(address => bool) public signers;
  struct Order {
    address payable switchBoard;
    bytes encodedPayload;
  }
  struct Trade {
    address sourceToken;
    address destinationToken;
    uint256 amount;
    Order[] orders;
  }

  struct Swap {
    Trade[] trades;
    uint256 minimumDestinationAmount;
    uint256 minimumExchangeRate;
    uint256 sourceAmount;
    uint256 tradeToTakeFeeFrom;
    bool takeFeeFromSource;
    address payable redirectAddress;
  }

  struct SwapBundle {
    Swap[] swaps;
    uint256 expirationBlock;
    bytes32 id;
    uint256 maxGasPrice;
    address payable partnerContract;
    uint8 tokenCount;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
  event LogSwapBundle(
    bytes32 indexed id,
    address indexed partnerContract,
    address indexed user
  );
  event LogSwap(
    bytes32 indexed id,
    address sourceAsset,
    address destinationAsset,
    uint256 sourceAmount,
    uint256 destinationAmount,
    address feeAsset,
    uint256 feeAmount
  );

  string public name;

  uint256 internal immutable INITIAL_CHAIN_ID;

  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

  mapping(address => uint256) public nonces;

  /// @notice Constructor
  /// @param _tokenTransferProxy address of the TokenTransferProxy
  /// @param _signer the suggester's address that signs the payloads.
  ///      More can be added with add/removeSigner functions
  constructor(address _tokenTransferProxy, address _signer) {
    tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
    signers[_signer] = true;
    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  modifier notExpired(SwapBundle memory swaps) {
    require(swaps.expirationBlock > block.number, "Expired");
    _;
  }
  modifier validSignature(SwapBundle memory swaps) {
    uint256 chainId = block.chainid;
    bytes32 hash = keccak256(
      abi.encode(
        chainId,
        swaps.swaps,
        swaps.partnerContract,
        swaps.expirationBlock,
        swaps.id,
        swaps.maxGasPrice,
        msg.sender
      )
    );
    require(
      signers[
        ecrecover(
          keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
          swaps.v,
          swaps.r,
          swaps.s
        )
      ],
      "INVALID_SIGNER"
    );
    _;
  }

  modifier notAboveMaxGas(SwapBundle memory swaps) {
    require(tx.gasprice <= swaps.maxGasPrice, "Gas price too high");
    _;
  }

  /// @notice Performs the requested set of swaps
  /// @param swaps The struct that defines the bundle of swaps to perform
  function performSwapBundle(SwapBundle memory swaps)
    public
    payable
    whenNotPaused
    notExpired(swaps)
    validSignature(swaps)
    notAboveMaxGas(swaps)
  {
    // Initialize token balances
    TokenBalanceLibrary.TokenBalance[]
      memory balances = new TokenBalanceLibrary.TokenBalance[](
        swaps.tokenCount
      );
    // Set the ETH balance to what was given with the function call
    balances[0] = TokenBalanceLibrary.TokenBalance(
      address(LibSafeUtils.eth_address()),
      msg.value
    );
    // Iterate over swaps and execute individually
    for (uint256 swapIndex = 0; swapIndex < swaps.swaps.length; swapIndex++) {
      performSwap(
        swaps.id,
        swaps.swaps[swapIndex],
        balances,
        swaps.partnerContract
      );
    }
    emit LogSwapBundle(swaps.id, swaps.partnerContract, msg.sender);
    // Transfer all assets from swap to user
    transferAllTokensToUser(balances);
  }

  /// @notice Add a new signer as valid
  /// @param newSigner The address to set as a valid signer
  function addSigner(address newSigner) public onlyOwner {
    require(newSigner != address(0x0), "");
    signers[newSigner] = true;
  }

  /// @notice Removes a signer
  /// @param signer The address to remove as a valid signer
  function removeSigner(address signer) public onlyOwner {
    signers[signer] = false;
  }

  /*
   *   Internal functions
   */

  function performSwap(
    bytes32 swapBundleId,
    Swap memory swap,
    TokenBalanceLibrary.TokenBalance[] memory balances,
    address payable partnerContract
  ) internal {
    transferFromSenderDifference(
      balances,
      swap.trades[0].sourceToken,
      swap.sourceAmount
    );
    uint256 amountSpentFirstTrade = 0;
    uint256 amountReceived = 0;
    uint256 feeAmount = 0;
    for (
      uint256 tradeIndex = 0;
      tradeIndex < swap.trades.length;
      tradeIndex++
    ) {
      if (tradeIndex == swap.tradeToTakeFeeFrom && swap.takeFeeFromSource) {
        feeAmount = takeFee(
          balances,
          swap.trades[tradeIndex].sourceToken,
          partnerContract,
          tradeIndex == 0 ? swap.sourceAmount : amountReceived
        );
      }
      uint256 tempSpent;
      (tempSpent, amountReceived) = performTrade(
        swap.trades[tradeIndex],
        balances,
        LibSafeUtils.min(
          tradeIndex == 0 ? swap.sourceAmount : amountReceived,
          balances[
            TokenBalanceLibrary.findToken(
              balances,
              swap.trades[tradeIndex].sourceToken
            )
          ].balance
        )
      );
      // Init
      if (tradeIndex == 0) {
        amountSpentFirstTrade = tempSpent + feeAmount;
        if (feeAmount != 0) {
          amountSpentFirstTrade += feeAmount;
        }
      }
      // Collect
      if (tradeIndex == swap.tradeToTakeFeeFrom && !swap.takeFeeFromSource) {
        feeAmount = takeFee(
          balances,
          swap.trades[tradeIndex].destinationToken,
          partnerContract,
          amountReceived
        );
        amountReceived -= feeAmount;
      }
    }
    emit LogSwap(
      swapBundleId,
      swap.trades[0].sourceToken,
      swap.trades[swap.trades.length - 1].destinationToken,
      amountSpentFirstTrade,
      amountReceived,
      swap.takeFeeFromSource
        ? swap.trades[swap.tradeToTakeFeeFrom].sourceToken
        : swap.trades[swap.tradeToTakeFeeFrom].destinationToken,
      feeAmount
    );
    // Validate the swap optomization
    require(
      amountReceived >= swap.minimumDestinationAmount,
      "Err.minDstAmount"
    );
    require(
      !minimumRateFailed(
        swap.trades[0].sourceToken,
        swap.trades[swap.trades.length - 1].destinationToken,
        swap.sourceAmount,
        amountReceived,
        swap.minimumExchangeRate
      ),
      "Err.minRate"
    );
    if (
      swap.redirectAddress != msg.sender && swap.redirectAddress != address(0x0)
    ) {
      uint256 destinationTokenIndex = TokenBalanceLibrary.findToken(
        balances,
        swap.trades[swap.trades.length - 1].destinationToken
      );
      uint256 amountToSend = Math.min(
        amountReceived,
        balances[destinationTokenIndex].balance
      );
      transferTokens(
        balances,
        destinationTokenIndex,
        swap.redirectAddress,
        amountToSend
      );
      TokenBalanceLibrary.removeBalance(
        balances,
        swap.trades[swap.trades.length - 1].destinationToken,
        amountToSend
      );
    }
  }

  function performTrade(
    Trade memory trade,
    TokenBalanceLibrary.TokenBalance[] memory balances,
    uint256 availableToSpend
  ) internal returns (uint256 totalSpent, uint256 totalReceived) {
    uint256 tempSpent = 0;
    uint256 tempReceived = 0;
    // Iterate over orders and execute consecutively
    for (
      uint256 orderIndex = 0;
      orderIndex < trade.orders.length;
      orderIndex++
    ) {
      if (tempSpent >= trade.amount) {
        break;
      }
      (tempSpent, tempReceived) = performOrder(
        trade.orders[orderIndex],
        availableToSpend - totalSpent,
        trade.sourceToken,
        balances
      );
      totalSpent += tempSpent;
      totalReceived += tempReceived;
    }
    // Update balances after performing order
    TokenBalanceLibrary.addBalance(
      balances,
      trade.destinationToken,
      totalReceived
    );
    TokenBalanceLibrary.removeBalance(balances, trade.sourceToken, totalSpent);
  }

  function performOrder(
    Order memory order,
    uint256 targetAmount,
    address tokenToSpend,
    TokenBalanceLibrary.TokenBalance[] memory balances
  ) internal returns (uint256 spent, uint256 received) {
    if (tokenToSpend == LibSafeUtils.eth_address()) {
      (spent, received) = SwitchBoard(order.switchBoard).performOrder{
        value: targetAmount
      }(order.encodedPayload, targetAmount, targetAmount);
    } else {
      transferTokens(
        balances,
        TokenBalanceLibrary.findToken(balances, tokenToSpend),
        order.switchBoard,
        targetAmount
      );
      (spent, received) = SwitchBoard(order.switchBoard).performOrder(
        order.encodedPayload,
        targetAmount,
        targetAmount
      );
    }
  }

  function minimumRateFailed(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    uint256 destinationAmount,
    uint256 minimumExchangeRate
  ) internal returns (bool failed) {
    uint256 sourceDecimals = sourceToken == LibSafeUtils.eth_address()
      ? 18
      : LibSafeUtils.getDecimals(sourceToken);
    uint256 destinationDecimals = destinationToken == LibSafeUtils.eth_address()
      ? 18
      : LibSafeUtils.getDecimals(destinationToken);
    uint256 rateGot = LibSafeUtils.calcRateFromQty(
      sourceAmount,
      destinationAmount,
      sourceDecimals,
      destinationDecimals
    );
    return rateGot < minimumExchangeRate;
  }

  function takeFee(
    TokenBalanceLibrary.TokenBalance[] memory balances,
    address token,
    address payable partnerContract,
    uint256 amountTraded
  ) internal returns (uint256 feeAmount) {
    Partner partner = Partner(partnerContract);
    uint256 feePercentage = partner.getTotalFeePercentage();
    feeAmount = calculateFee(amountTraded, feePercentage);
    uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
    TokenBalanceLibrary.removeBalance(balances, tokenIndex, feeAmount);
    transferTokens(balances, tokenIndex, partnerContract, feeAmount);
    return feeAmount;
  }

  // prettier-ignore
  function transferFromSenderDifference(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address token,
        uint256 sourceAmount
    ) internal {
        if (token == LibSafeUtils.eth_address()) {
            require(
                sourceAmount >= balances[0].balance,"Err.SenderDifference");
        } else {
            uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
            if (sourceAmount > balances[tokenIndex].balance) {
                SafeERC20.safeTransferFrom(
                    IERC20(token),
                    msg.sender,
                    address(this),
                    sourceAmount - balances[tokenIndex].balance
                );
            }
        }
    }

  function transferAllTokensToUser(
    TokenBalanceLibrary.TokenBalance[] memory balances
  ) internal {
    for (
      uint256 balanceIndex = 0;
      balanceIndex < balances.length;
      balanceIndex++
    ) {
      if (
        balanceIndex != 0 && balances[balanceIndex].tokenAddress == address(0x0)
      ) {
        return;
      }
      transferTokens(
        balances,
        balanceIndex,
        payable(msg.sender),
        balances[balanceIndex].balance
      );
    }
  }

  function transferTokens(
    TokenBalanceLibrary.TokenBalance[] memory balances,
    uint256 tokenIndex,
    address payable destination,
    uint256 tokenAmount
  ) internal {
    if (tokenAmount > 0) {
      if (balances[tokenIndex].tokenAddress == LibSafeUtils.eth_address()) {
        destination.transfer(tokenAmount);
      } else {
        SafeERC20.safeTransfer(
          IERC20(balances[tokenIndex].tokenAddress),
          destination,
          tokenAmount
        );
      }
    }
  }

  // @notice Calculates the fee amount given a fee percentage and amount
  // @param amount the amount to calculate the fee based on
  // @param fee the percentage, out of 1 eth (e.g. 0.01 ETH would be 1%)
  function calculateFee(uint256 amount, uint256 fee)
    internal
    pure
    returns (uint256)
  {
    return SafeMath.div(SafeMath.mul(amount, fee), 1 * (10**18));
  }

  /*
   *   Payable receive function
   */

  /// @notice payable receive to allow ward or exchange contracts to return ether
  /// @dev only accounts containing code (ie. contracts) can send ether to contract
  receive() external payable whenNotPaused {
    // Check in here that the sender is a contract! (to stop accidents)
    uint256 size;
    address sender = msg.sender;
    assembly {
      size := extcodesize(sender)
    }
    if (size == 0) {
      revert("Err.Payable.Receive.SenderNotContract");
    }
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(name)),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }
}
