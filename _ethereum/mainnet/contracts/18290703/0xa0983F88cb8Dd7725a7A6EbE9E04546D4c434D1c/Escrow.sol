//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Escrow is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  address public usdcTokenAddress;

  enum EscrowStatus {
    Created,
    SignedSeller,
    SignedBoth,
    Delivered,
    Released,
    Revoked,
    Dispute
  }

  enum EscrowType {
    BuyEscrow,
    SellEscrow
  }

  struct EscrowTransaction {
    address buyer;
    address seller;
    bool isNative;
    uint256 price;
    string description;
    EscrowStatus status;
    EscrowType escrow_type;
    bool is_admin_allow_need;
    bool is_admin_allow;
  }

  //bytes32 is a generated link id which is created from backend
  mapping(bytes32 => EscrowTransaction) public escrowTransactions;
  address public fee_wallet_addr;

  /**
   * @notice event when the escrow transaction is created
   */
  event EscrowCreated(bytes32 indexed escrow);
  event EscrowReleased(bytes32 indexed escrow);
  event EscrowRevoked(bytes32 indexed escrow);

  constructor(address owner, address _fee_wallet, address _usdcTokenAddress) {
    super.transferOwnership(owner);
    fee_wallet_addr = _fee_wallet;
    usdcTokenAddress = _usdcTokenAddress;
  }

  /**
   * @dev this function is called by buyer
   *  in case of buyer, he needs to deposit money first
   */
  function createBuyEscrow(
    uint256 price,
    string calldata description,
    bytes32 escrowID,
    bool is_admin_allow_need,
    bool is_native
  ) external payable {
    require(
      escrowTransactions[escrowID].buyer == address(0x0),
      "Escrow id already exists"
    );
    require(msg.value == price || !is_native, "actual eth amount is wrong ");

    if (!is_native) {
      IERC20(usdcTokenAddress).transferFrom(msg.sender, address(this), price);
    }

    uint256 actualAmount = (price / 1025) * 1000; //this is because of platform fee
    escrowTransactions[escrowID] = EscrowTransaction({
        buyer: msg.sender,
        seller: address(0),
        isNative: is_native,
        description: description,
        price: actualAmount,
        status: EscrowStatus.Created,
        escrow_type: EscrowType.BuyEscrow,
        is_admin_allow_need: is_admin_allow_need,
        is_admin_allow: false
      }
    );

    emit EscrowCreated(escrowID);
  }

  /**
   * @dev this function is called by seller
   *  in case of seller, he just input his servie price
   */
  function createSellEscrow(
    uint256 price,
    string calldata description,
    bytes32 escrowID,
    bool is_admin_allow_need,
    bool is_native
  ) external {
    require(
      escrowTransactions[escrowID].seller == address(0x0),
      "Escrow id already exists"
    );
    escrowTransactions[escrowID] = EscrowTransaction(
      address(0x0),
      msg.sender,
      is_native,
      price,
      description,
      EscrowStatus.Created,
      EscrowType.SellEscrow,
      is_admin_allow_need,
      false
    );

    emit EscrowCreated(escrowID);
  }

  /**
   * @dev this function is called by seller to sign the tansaction.
   *      Here sign means accept the buy request from buyer
   *      Buyer use this function for signing when this escrow is created by seller
   *      In this case buyer needs to deposit money to this contract
   */
  function signToBuyEscrow(bytes32 escrowID) external {
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "No Escrow transaction"
    );
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Created,
      "Escrow is not in Created status"
    );

    EscrowTransaction storage transaction = escrowTransactions[escrowID];
    transaction.seller = msg.sender;
    transaction.status = EscrowStatus.SignedSeller;
  }

  /**
   * @dev this function is called by buyer to sign the tansaction.
   *      Here sign means buyer accepts the sell request from seller
   *
   */
  function signToSellEscrow(bytes32 escrowID) external payable {
    EscrowTransaction storage transaction = escrowTransactions[escrowID];

    require(
      escrowTransactions[escrowID].seller != address(0x0),
      "No Escrow transaction"
    );
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Created,
      "Escrow is not in Created status"
    );

    require(msg.value == transaction.price, "Actual amount is wrong");
    transaction.buyer = msg.sender;
    transaction.status = EscrowStatus.SignedSeller;
  }

  /**
   * @dev this function is called by buyer or seller to tell the correct seller or buyer is matched.
   *      the transaction status should be SignedSeller to be called by this function
   */
  function confirmSigning(
    bytes32 escrowID
  ) external onlyTransactionOwner(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedSeller,
      "Seller/buyer didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.SignedBoth;
  }

  /**
   * @dev this function is called by buyer or seller to tell the wrong seller or buyer is matched or not
   *      the transaction status should be SignedSeller to be called by this function
   */
  function rejectSigning(
    bytes32 escrowID
  ) external onlyTransactionOwner(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedSeller,
      "Seller/buyer didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.Created;
  }

  /**
   * @dev this function is called by buyer to check that he gets correct delivery
   *      the transaction status should be SignedBoth to be called by this function
   */
  function confirmDelivery(bytes32 escrowID) external onlyBuyer(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedBoth,
      "Seller didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.Delivered;
  }

  /**
   * @dev this function is called by buyer to finalize the transaction
   *
   */
  function releaseFunds(
    bytes32 escrowID
  ) external nonReentrant onlyBuyer(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Delivered,
      "Can't release funds"
    );

    if (escrowTransactions[escrowID].is_admin_allow_need == true) {
      require(
        escrowTransactions[escrowID].is_admin_allow == true,
        "Require admin's permit"
      );
    }

    escrowTransactions[escrowID].status = EscrowStatus.Released;
    if (escrowTransactions[escrowID].escrow_type == EscrowType.BuyEscrow) {
      address payable seller = payable(escrowTransactions[escrowID].seller);
      //the price doesn't contain fee
      if (escrowTransactions[escrowID].isNative) {
        seller.transfer(escrowTransactions[escrowID].price);
        payable(fee_wallet_addr).transfer(
          (escrowTransactions[escrowID].price / 1000) * 25
        );
      } else {
        IERC20(usdcTokenAddress).transfer(seller, escrowTransactions[escrowID].price);
        IERC20(usdcTokenAddress).transfer(fee_wallet_addr, (escrowTransactions[escrowID].price / 1000) * 25);
      }
    } else if (
      escrowTransactions[escrowID].escrow_type == EscrowType.SellEscrow
    ) {
      address payable seller = payable(escrowTransactions[escrowID].seller);
      //the price contains fee
      if (escrowTransactions[escrowID].isNative) {
        seller.transfer((escrowTransactions[escrowID].price / 1025) * 1000);
        payable(fee_wallet_addr).transfer(
          (escrowTransactions[escrowID].price / 1025) * 25
        );
      } else {
        IERC20(usdcTokenAddress).transfer(seller, (escrowTransactions[escrowID].price / 1025 * 1000));
        IERC20(usdcTokenAddress).transfer(fee_wallet_addr, ((escrowTransactions[escrowID].price / 1025) * 25));
      }
    }
    emit EscrowReleased(escrowID);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getUSDCBalance() public view returns (uint256) {
    return IERC20(usdcTokenAddress).balanceOf(address(this));
  }

  // function withdraw(address to) external onlyOwner {
  //   payable(to).transfer(getBalance());
  // }

  function updateFeeWalletAddr(address new_fee_wallet) external onlyOwner {
    fee_wallet_addr = new_fee_wallet;
  }

  // admin can control the status of transaction
  // however admin can't control released transaction
  function admin_control_status(
    bytes32 escrowID,
    uint256 status
  ) external onlyOwner {
    require(escrowTransactions[escrowID].status != EscrowStatus.Released, "Even admin can't control the released transaction");
    escrowTransactions[escrowID].status = EscrowStatus(status);
  }

  /**
   *  this function is called by admin
   *  if there is a opportunity to manage the transactions by manager, owner
   *  manager the transaction by using this function for approving
   */
  function admin_release(bytes32 escrowID) external onlyOwner {
    require(
      escrowTransactions[escrowID].status != EscrowStatus.Released,
      "Already Released Transaction"
    );
    //there should be buyer to be approved by manager
    //no buyer means the tranction was created by seller and there is no funds are escrowed on this
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "There is no buyer"
    );

    address payable seller = payable(escrowTransactions[escrowID].seller);
    if (escrowTransactions[escrowID].isNative) {
      seller.transfer(escrowTransactions[escrowID].price);
    } else {
      IERC20(usdcTokenAddress).transfer(seller, escrowTransactions[escrowID].price);
    }
    escrowTransactions[escrowID].status = EscrowStatus.Released;
    emit EscrowReleased(escrowID);
  }

  /**
   *  this function is called by admin
   *  if there is a opportunity to manager the transactions by manager, owner
   *  manager the transaction by using this function for rejecting
   */
  function admin_revoke(bytes32 escrowID) external onlyOwner {
    require(
      escrowTransactions[escrowID].status != EscrowStatus.Released,
      "Already Released Transaction"
    );
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "There is no buyer"
    );

    address payable buyer = payable(escrowTransactions[escrowID].buyer);
    if (escrowTransactions[escrowID].isNative) {
      buyer.transfer(escrowTransactions[escrowID].price);
    } else {
      IERC20(usdcTokenAddress).transfer(buyer, escrowTransactions[escrowID].price);
    }
    escrowTransactions[escrowID].status = EscrowStatus.Revoked;
    emit EscrowRevoked(escrowID);
  }

  modifier onlyTransactionOwner(bytes32 escrowID) {
    if (escrowTransactions[escrowID].escrow_type == EscrowType.BuyEscrow) {
      require(
        msg.sender == escrowTransactions[escrowID].buyer,
        "Only owner can access the transaction"
      );
    } else {
      //when the escrow is created by seller
      require(
        msg.sender == escrowTransactions[escrowID].seller,
        "Only owner can access the transaction"
      );
    }
    _;
  }

  modifier onlyBuyer(bytes32 escrowID) {
    require(
      msg.sender == escrowTransactions[escrowID].buyer,
      "Only Buyer can do this transaction"
    );
    _;
  }
}
