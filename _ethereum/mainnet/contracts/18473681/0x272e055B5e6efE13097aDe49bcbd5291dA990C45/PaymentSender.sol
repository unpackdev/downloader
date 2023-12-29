// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/// @notice Contract to receive and distribute payments on ETH or ERC20 tokens

contract PaymentSender is
  ERC1155Holder,
  IERC721Receiver,
  Ownable,
  ReentrancyGuard
{
  /// @notice ETH amount still not distributed
  uint256 public reserveBalance;
  /// @notice ETH amount for contributions (coming from taxes)
  uint256 public contributionsBalance;
  /// @notice Perc of taxes to take on deposits
  uint256 public taxesPerc;
  /// @notice Address of the wallet that signs messages
  address public secret;

  /// @notice Mapping of ETH balances for each wallet address
  mapping(address => uint256) public ethBalance;

  /// @notice Mapping of used signatures
  mapping(bytes => bool) public usedSignatures;
  /// @notice Mapping of allowed wallets
  mapping(address => bool) public isAllowed;

  /// @notice Event emitted when ETH is deposited to reserve balance
  event Deposit(uint256 amount, address operator);
  /// @notice Event emitted when ETH is deposited to contributions balance
  event Contribution(uint256 amount, address operator);
  /// @notice Event emitted when ETH is distributed
  event Distribute(uint256[] amounts, address[] recipients, address operator);
  /// @notice Event emitted ETH is sent
  event SendETH(uint256[] amounts, address[] recipients, address operator);
  /// @notice Event emitted when someone withdraws ETH
  event WithdrawETH(uint256 amount, address recipient, address operator);

  /// @notice Event emitted when someone withdraws ERC20 tokens
  event WithdrawERC20(
    address token,
    uint256 amount,
    address recipient,
    address operator
  );

  /// @notice Event emitted when someone withdraws ERC721 or ERC1155 tokens
  event WithdrawNFT(
    address token,
    uint256 tokenId,
    uint256 amount,
    address recipient,
    address operator
  );

  /// @notice Event emitted when a new signer is set
  event SetSigner(address signer);

  /// @notice Event emitted when a new allowed wallet is set
  event SetAllowed(address wallet, bool allowed);

  /// @notice Event emitted when a signature is marked as used without withdrawing anything
  event UseSignature(bytes signature);

  /// @notice Event emitted when ETH is unassigned from a recipient
  event UnassignETH(uint256 amount, address recipient);

  /// @notice Event emitted when taxes percentage is set
  event SetTaxesPerc(uint256 taxesPerc);

  constructor() {}

  /// @notice Fall back function to receive ETH
  receive() external payable {
    depositToReserve(msg.value, taxesPerc);
  }

  /// @notice modifier of wallets allowed to use restricted functions
  modifier onlyAllowed() {
    require(
      isAllowed[msg.sender] || msg.sender == owner(),
      "onlyAllowed: Not allowed"
    );
    _;
  }

  /// @notice Function to deposit ETH and distribute it to recipients
  /// @param amounts Amounts of ETH to distribute
  /// @param recipients Addresses to distribute ETH to
  /// @dev Only assign the ETH to the recipients, doesn't send it, use sendFunds for that
  function distribute(
    uint256[] memory amounts,
    address[] memory recipients,
    uint256 taxToTake,
    bool fromContributions
  ) external payable onlyAllowed nonReentrant {
    _handleFunds(amounts, recipients, true, taxToTake, fromContributions);

    emit Distribute(amounts, recipients, msg.sender);
  }

  /// @notice Function to send ETH to recipients
  /// @param amounts Amounts of ETH to send
  /// @param recipients Addresses to send ETH to
  /// @dev Only send the ETH to the recipients, doesn't assign it, use distribute for that
  function sendFunds(
    uint256[] memory amounts,
    address[] memory recipients,
    uint256 taxToTake,
    bool fromContributions
  ) external payable onlyAllowed nonReentrant {
    _handleFunds(amounts, recipients, false, taxToTake, fromContributions);

    emit SendETH(amounts, recipients, msg.sender);
  }

  /// @notice Function to withdraw ETH
  /// @param amount Amount of ETH to withdraw
  /// @param recipient Address to withdraw ETH to
  /// @dev Withdraw from the ETH balance of the sender
  function withdrawETH(uint256 amount, address payable recipient) external {
    require(amount > 0, "withdraw: Amount must be greater than 0");
    require(
      ethBalance[msg.sender] >= amount,
      "withdraw: Not enough ETH in your balance to withdraw"
    );

    ethBalance[msg.sender] -= amount;

    recipient.transfer(amount);

    emit WithdrawETH(amount, recipient, msg.sender);
  }

  /// @notice use a signature to withdraw ETH without having any assigned
  /// @param amount Amount of ETH to withdraw
  /// @param recipient Address to withdraw ETH to
  /// @param checkId Id to check if the signature was used
  /// @param signature Signature to use
  function withdrawETHWithSignature(
    uint256 amount,
    address recipient,
    uint256 checkId,
    bytes memory signature
  ) external {
    require(
      amount <= reserveBalance,
      "withdrawETHWithSignature: Not enough ETH in reserve to withdraw"
    );

    bytes32 hash = keccak256(
      abi.encode(recipient, amount, checkId, "withdrawETHWithSignature")
    );

    _handleSignature(hash, signature);

    reserveBalance -= amount;

    payable(recipient).transfer(amount);

    emit WithdrawETH(amount, recipient, msg.sender);
  }

  /// @notice use a signature to withdraw ERC20 tokens
  /// @param token Address of the ERC20 token
  /// @param amount Amount of ERC20 tokens to withdraw
  /// @param recipient Address to withdraw ERC20 tokens to
  /// @param checkId Id to check if the signature was used
  /// @param signature Signature to use
  function withdrawERC20WithSignature(
    address token,
    uint256 amount,
    address recipient,
    uint256 checkId,
    bytes memory signature
  ) external {
    require(
      amount <= IERC20(token).balanceOf(address(this)),
      "withdrawERC20WithSignature: Not enough ERC20 tokens in reserve to withdraw"
    );

    bytes32 hash = keccak256(
      abi.encode(
        token,
        recipient,
        amount,
        checkId,
        "withdrawERC20WithSignature"
      )
    );

    _handleSignature(hash, signature);

    IERC20(token).transfer(recipient, amount);

    emit WithdrawERC20(token, amount, recipient, msg.sender);
  }

  /// @notice use a signature to withdraw ERC721 or ERC1155 tokens
  /// @param token Address of the ERC721 or ERC1155 token
  /// @param tokenId Id of the ERC721 or ERC1155 token
  /// @param amount Amount of ERC1155 token to withdraw (ERC721 = 0, amount not required)
  /// @param recipient Address to withdraw ERC721 or ERC1155 tokens to
  /// @param checkId Id to check if the signature was used
  /// @param signature Signature to use
  function withdrawNFTWithSignature(
    address token,
    uint256 tokenId,
    uint256 amount,
    address recipient,
    uint256 checkId,
    bytes memory signature
  ) external {
    bytes32 hash = keccak256(
      abi.encode(
        token,
        tokenId,
        recipient,
        amount,
        checkId,
        "withdrawNFTWithSignature"
      )
    );

    _handleSignature(hash, signature);

    if (amount == 0) {
      require(
        IERC721(token).ownerOf(tokenId) == address(this),
        "withdrawNFTWithSignature: Not enough ERC721 tokens in reserve to withdraw"
      );

      IERC721(token).safeTransferFrom(address(this), recipient, tokenId);
    } else {
      require(
        amount <= IERC1155(token).balanceOf(address(this), tokenId),
        "withdrawNFTWithSignature: Not enough ERC1155 tokens in reserve to withdraw"
      );

      IERC1155(token).safeTransferFrom(
        address(this),
        recipient,
        tokenId,
        amount,
        ""
      );
    }

    emit WithdrawNFT(token, tokenId, amount, recipient, msg.sender);
  }

  /// INTERNAL FUNCTIONS

  /// @notice Helper function to deposit ETH
  function depositToReserve(uint256 amount, uint256 taxToTake) internal {
    if (taxToTake > 0) {
      uint256 taxes = (amount * taxToTake) / 10000;
      contributionsBalance += taxes;
      amount -= taxes;
      emit Contribution(taxes, msg.sender);
    }

    reserveBalance += amount;

    emit Deposit(amount, msg.sender);
  }

  function _handleSignature(bytes32 hash, bytes memory signature) internal {
    require(
      _verifyHashSignature(hash, signature),
      "handleSignature: Invalid signature"
    );

    require(
      !usedSignatures[signature],
      "handleSignature: Signature already used"
    );

    usedSignatures[signature] = true;
  }

  /// @notice Function to deposit ETH and distribute it to recipients
  /// @param amounts Amounts of ETH to handle
  /// @param recipients Addresses to handle ETH for
  /// @param isDistribute Whether to distribute (true) or send (false)
  function _handleFunds(
    uint256[] memory amounts,
    address[] memory recipients,
    bool isDistribute,
    uint256 taxToTake,
    bool fromContributions
  ) internal {
    require(
      amounts.length == recipients.length,
      "handleFunds: Arrays must have the same length"
    );

    if (msg.value > 0) {
      depositToReserve(msg.value, taxToTake);
    }

    uint256 totalAmount;

    for (uint256 i = 0; i < amounts.length; i++) {
      uint256 amount = amounts[i];
      totalAmount += amount;

      if (isDistribute) {
        ethBalance[recipients[i]] += amount;
      } else {
        payable(recipients[i]).transfer(amount);
      }
    }

    if (fromContributions) {
      require(
        totalAmount <= contributionsBalance,
        "handleFunds: Not enough ETH in contributions balance"
      );

      contributionsBalance -= totalAmount;
    } else {
      require(
        totalAmount <= reserveBalance,
        "handleFunds: Not enough ETH in reserve balance"
      );

      reserveBalance -= totalAmount;
    }
  }

  /// OWNER FUNCTIONS

  /// @notice Function to set a new signer
  /// @param newSigner: Address of the new signer
  /// @dev Only the owner can set a new signer
  function setSigner(address newSigner) external onlyOwner {
    require(newSigner != address(0), "Invalid address");
    secret = newSigner;

    emit SetSigner(newSigner);
  }

  /// @notice Function to set a new allowed wallet
  /// @param wallet: Address of the new allowed wallet
  /// @param allowed: Boolean to set if the wallet is allowed or not
  /// @dev Only the owner can set a new allowed wallet
  function setAllowed(address wallet, bool allowed) external onlyOwner {
    require(wallet != address(0), "Invalid address");
    isAllowed[wallet] = allowed;

    emit SetAllowed(wallet, allowed);
  }

  /// @notice Function to set the taxes percentage
  /// @param _taxesPerc: New taxes percentage
  /// @dev Only the owner can set the taxes percentage
  function setTaxesPerc(uint256 _taxesPerc) external onlyOwner {
    require(_taxesPerc <= 10000, "setTaxesPerc: Taxes percentage too high");

    taxesPerc = _taxesPerc;

    emit SetTaxesPerc(_taxesPerc);
  }

  /// @notice Mark a signature as used without withdrawing anything
  /// @param signature Signature to use
  function useSignature(bytes memory signature) external nonReentrant {
    require(!usedSignatures[signature], "useSignature: Signature already used");

    usedSignatures[signature] = true;

    emit UseSignature(signature);
  }

  /// @notice Unassign ETH from a recipient
  /// @param amount Amount of ETH to unassign
  /// @param recipient Address to unassign ETH from
  function unassignETH(uint256 amount, address recipient) external onlyOwner {
    require(
      ethBalance[recipient] >= amount,
      "unassignETH: Not enough ETH in recipient balance"
    );

    ethBalance[recipient] -= amount;

    reserveBalance += amount;

    emit UnassignETH(amount, recipient);
  }

  /// EMERGENCY FUNCTIONS

  /// @notice Emergency function to withdraw ETH
  function emergencyWithdrawETH() external onlyOwner {
    uint256 contractBalance = address(this).balance;

    payable(msg.sender).transfer(reserveBalance);

    emit WithdrawETH(contractBalance, msg.sender, msg.sender);
  }

  /// @notice Emergency function to withdraw ERC20 tokens
  /// @param token Address of the ERC20 token
  function emergencyWithdrawERC20(address token) external onlyOwner {
    uint256 contractBalance = IERC20(token).balanceOf(address(this));

    require(
      contractBalance > 0,
      "emergencyWithdrawERC20: No tokens to withdraw"
    );

    IERC20(token).transfer(msg.sender, contractBalance);

    emit WithdrawERC20(token, contractBalance, msg.sender, msg.sender);
  }

  /// @notice Emergency function to withdraw ERC721 or ERC1155 tokens
  /// @param token Address of the ERC721 or ERC1155 token
  /// @param tokenId Id of the ERC721 or ERC1155 token
  /// @param amount Amount of ERC1155 token to withdraw (ERC721 = 0, amount not required)
  function emergencyWithdrawNFT(
    address token,
    uint256 tokenId,
    uint256 amount
  ) external onlyOwner {
    if (amount == 0) {
      IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
    } else {
      IERC1155(token).safeTransferFrom(
        address(this),
        msg.sender,
        tokenId,
        amount,
        ""
      );
    }

    emit WithdrawNFT(token, tokenId, amount, msg.sender, msg.sender);
  }

  /// @notice Internal function to check if a signature is valid
  /// @param freshHash: Hash to check
  /// @param signature: Signature to check
  function _verifyHashSignature(
    bytes32 freshHash,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
    );

    bytes32 r;
    bytes32 s;
    uint8 v;

    if (signature.length != 65) {
      return false;
    }
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    address signer = address(0);
    if (v == 27 || v == 28) {
      // solium-disable-next-line arg-overflow
      signer = ecrecover(hash, v, r, s);
    }
    return secret == signer;
  }

  // TODO: if we want to support ERC721, we need to implement this function
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
