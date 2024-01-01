// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IHighstreetBrands.sol";

contract TalonPaymentReceiver is Ownable, Pausable, ReentrancyGuard {

  struct CryptoPaymentRawType {
    uint256 chainId;
    bytes32 paymentId;
    address userWallet;
    uint256 highAmount;
    uint256 option1Amount;
    uint256 option2Amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  address immutable public HIGH_TOKEN;
  address immutable public HIGHSTREET_BRANDS;
  uint256 immutable public MAX_SELL_AMOUNT;
  uint256 immutable public OPTION1_TOKENID;
  uint256 immutable public OPTION2_TOKENID;
  address public signer;
  address public paymentReceiver;
  uint256 public option1SoldAmount;
  uint256 public option2SoldAmount;
  mapping(bytes32 => bool) public usedPaymentIds;

  /**
   * @dev Fired in updateSuperOwner()
   *
   * @param paymentReceiver new super owner address
   */
  event UpdateReceiver(address paymentReceiver);

  /**
   * @dev Fired in updateSigner()
   *
   * @param signer new signer address
   */
  event UpdateSigner(address signer);

  /**
   * @dev Fired in Checkout()
   * 
   * @param user user address
   * @param paymentId a random hash to prevent input message collision
   * @param option1Amount a tokenId that minted to user 
   * @param option2Amount a tokenId that minted to user 
   * @param highAmount a number expected to receive
   */
  event Checkout(address indexed user, bytes32 indexed paymentId, uint256 option1Amount, uint256 option2Amount, uint256 highAmount);

  /**
   * @dev Creates/deploys an instance of the TalonPaymentReceiver contract
   * 
   * @param high_ high token address
   * @param brands_ brands nft address
   * @param maxAmount_ max amount of each option
   * @param signer_ signer address
   * @param receiver_ receiver address
   * @param hoodieTokenId_ option token id
   */

  constructor(
    address high_,
    address brands_,
    uint256 maxAmount_,
    address signer_,
    address receiver_,
    uint256[2] memory hoodieTokenId_
  ) {
    require(signer_ != address(0), "Invalid signer");
    require(receiver_ != address(0), "Invalid receiver");
    HIGH_TOKEN = high_;
    HIGHSTREET_BRANDS = brands_;
    MAX_SELL_AMOUNT = maxAmount_;
    signer = signer_;
    paymentReceiver = receiver_;
    OPTION1_TOKENID = hoodieTokenId_[0];
    OPTION2_TOKENID = hoodieTokenId_[1];
  }

  /**
   * @dev Checkout function that receive payment from user and mint nfts to user
   * 
   * @param input_ every input data that user send to this function
   * 
   * @notice this should always be signed by signer to complete the checkout
   */
  function checkout(CryptoPaymentRawType calldata input_) external payable nonReentrant whenNotPaused {
    require(_msgSender() == input_.userWallet, "Invalid sender");
    require(block.timestamp <= input_.deadline, "Execution exceed deadline");
    require(usedPaymentIds[input_.paymentId] == false, "PaymentId already used");
    _verifyInputSignature(input_);
    usedPaymentIds[input_.paymentId] = true;

    SafeERC20.safeTransferFrom(IERC20(HIGH_TOKEN), input_.userWallet, paymentReceiver, input_.highAmount);

    if (input_.option1Amount != 0) {
      require(input_.option1Amount + option1SoldAmount <= MAX_SELL_AMOUNT, "Exceed max sell amount");
      option1SoldAmount += input_.option1Amount;
      IHighstreetBrands(HIGHSTREET_BRANDS).mint(input_.userWallet, OPTION1_TOKENID, input_.option1Amount, "");
    }
    if (input_.option2Amount != 0) {
      require(input_.option2Amount + option2SoldAmount <= MAX_SELL_AMOUNT, "Exceed max sell amount");
      option2SoldAmount += input_.option2Amount;
      IHighstreetBrands(HIGHSTREET_BRANDS).mint(input_.userWallet, OPTION2_TOKENID, input_.option2Amount, "");
    }
    emit Checkout(input_.userWallet, input_.paymentId, input_.option1Amount, input_.option2Amount, input_.highAmount);
  }

  function _verifyInputSignature(CryptoPaymentRawType memory input_) internal view {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    require(input_.chainId == chainId, "Invalid network");
    bytes32 hash_ = keccak256(
      abi.encode(
        input_.chainId,
        input_.paymentId,
        input_.userWallet,
        input_.highAmount,
        input_.option1Amount,
        input_.option2Amount,
        input_.deadline
      )
    );
    bytes32 appendEthSignedMessageHash = ECDSA.toEthSignedMessageHash(hash_);
    address inputSigner = ECDSA.recover(appendEthSignedMessageHash, input_.v, input_.r, input_.s);
    require(signer == inputSigner, "Invalid signer");
  }

  /**
   * @dev update receiver address
   * 
   * @param receiver_ new receiver address
   */
  function updateReceiver(address receiver_) external onlyOwner {
    require(receiver_ != address(0), "Invalid address");
    paymentReceiver = receiver_;
    emit UpdateReceiver(paymentReceiver);
  }

  /**
   * @dev update signer address
   * 
   * @param signer_ new signer address
   */
  function updateSigner(address signer_) external onlyOwner {
    require(signer_ != address(0), "Invalid address");
    signer = signer_;
    emit UpdateSigner(signer);
  }

  /**
   * @dev pause the minting process
   *
   * @notice this function could only call by owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev unpause the minting process
   *
   * @notice this function could only call by owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}