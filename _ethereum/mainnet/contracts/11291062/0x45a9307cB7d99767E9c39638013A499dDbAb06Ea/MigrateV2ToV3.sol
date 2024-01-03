pragma solidity ^0.6.12;

import "./MixedPodInterface.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "./IERC1820Registry.sol";
import "./IERC1820Implementer.sol";

/// @title Allows no-slippage swaps from PoolTogether V2 tickets to V3
/// @dev Note that V3 tickets need to be transferred to this contract for liquidity.
contract MigrateV2ToV3 is OwnableUpgradeSafe, IERC777Recipient {

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 constant private _ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  // The interface hash for ERC777TokensRecipient
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
  0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  /// @notice Emitted when V2 tokens are received by this contract.  May be tickets or Pod shares.
  event ReceivedTokens(address token, address from, uint256 amount);

  /// @notice The PoolTogether V2 Pool Dai token
  IERC777 public poolDaiToken;

  /// @notice THe PoolTogether V2 Pool USDC token
  IERC777 public poolUsdcToken;

  /// @notice The PoolTogether V2 Pool Dai Pod token
  MixedPodInterface public poolDaiPod;

  /// @notice The PoolTogether V2 Pool USDC Pod token
  MixedPodInterface public poolUsdcPod;

  /// @notice The PoolTogether V3 Pool Dai Token
  IERC20 public v3Token;

  /// @notice initializes the migration contract
  /// @param _poolDaiToken The V2 Pool Dai token
  /// @param _poolUsdcToken The V2 Pool USDC token
  /// @param _poolDaiPod The V2 Pool Dai pod token
  /// @param _poolUsdcPod The V2 Pool USDC pod token
  /// @param _v3Token The V3 Pool Dai token
  constructor (
    IERC777 _poolDaiToken,
    IERC777 _poolUsdcToken,
    MixedPodInterface _poolDaiPod,
    MixedPodInterface _poolUsdcPod,
    IERC20 _v3Token
  ) public {
    poolDaiToken = _poolDaiToken;
    poolUsdcToken = _poolUsdcToken;
    poolDaiPod = _poolDaiPod;
    poolUsdcPod = _poolUsdcPod;
    v3Token = _v3Token;

    // register interfaces
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

    __Ownable_init();
  }

  /// @notice This function is called by ERC777 tokens after tokens have been transferred to this contract.
  /// This function will transfer V3 tokens held by the migration contract to the sender.  The tokens will
  /// be exchanged 1:1 with Pool Dai and Pool USDC tokens (denomination withstanding).  The tokens will
  /// be exchanged 1:1 with the underlying value of Pool Dai Pod shares and Pool USDC Pod shares (i.e. the Dai and USDC value, respectively).
  /// @param from The user who sent the tokens
  /// @param to The recipient of the tokens
  /// @param amount The amount of tokens that were sent
  function tokensReceived(
    address,
    address from,
    address to,
    uint256 amount,
    bytes calldata,
    bytes calldata
  ) external override {
    require(to == address(this), "MigrateV2ToV3/only-tokens");

    if (msg.sender == address(poolDaiToken)) {
      v3Token.transfer(from, amount);
    } else if (msg.sender == address(poolUsdcToken)) {
      v3Token.transfer(from, amount * 1e12);
    } else if (msg.sender == address(poolDaiPod)) {
      uint256 collateral = poolDaiPod.tokenToCollateralValue(amount);
      v3Token.transfer(from, collateral);
    } else if (msg.sender == address(poolUsdcPod)) {
      uint256 collateral = poolUsdcPod.tokenToCollateralValue(amount);
      v3Token.transfer(from, collateral * 1e12);
    } else {
      revert("MigrateV2ToV3/unknown-token");
    }

    emit ReceivedTokens(msg.sender, from, amount);
  }

  function withdrawERC20Batch(IERC20[] memory tokens, address recipient) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      withdrawERC20(tokens[i], recipient);
    }
  }

  /// @notice Allows the owner of the contract to withdraw any ERC777 tokens.
  /// @param token The ERC777 token whose entire balance should be transferred to the owner.
  function withdrawERC777(IERC777 token, address to) external onlyOwner {
    uint256 amount = token.balanceOf(address(this));
    token.send(to, amount, "");
  }

  /// @notice Allows the owner of the contract to withdraw any ERC20 tokens
  /// @param token The ERC20 token whose entire balance should be transferred to the owner
  function withdrawERC20(IERC20 token, address to) public onlyOwner {
    uint256 amount = token.balanceOf(address(this));
    token.transfer(to, amount);
  }

  /// @notice Allows the owner of the contract to withdraw any ERC721 token
  /// @param token The ERC721 to withdraw
  /// @param id The id of the token to transfer
  function withdrawERC721(IERC721 token, uint256 id, address to) external onlyOwner {
    IERC721(token).transferFrom(address(this), to, id);
  }
}
