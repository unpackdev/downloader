//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract PurchaseGiftcard is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Purchase {
    string orderID;
    uint256 cryptoAmount;
    address cryptoContract;
    uint256 purchaseTime;
  }

  address public adminAddress;
  mapping(address => bool) public operators;
  mapping(address => Purchase[]) public purchaseHistory;
  mapping(string => bool) public refundHistory;
  mapping(address => bool) public tokens;

  event PurchaseByCurrency(
    string voucherID,
    string fromFiatID,
    string toCryptoID,
    uint256 fiatDenomination,
    uint256 cryptoAmount,
    string orderID,
    uint256 purchaseTime
  );
  event PurchaseByToken(
    string voucherID,
    string fromFiatID,
    string toCryptoID,
    uint256 fiatDenomination,
    uint256 cryptoAmount,
    string orderID,
    uint256 purchaseTime
  );
  event WithdrawCurrency(address adminAddress, uint256 currencyAmount);
  event WithdrawToken(
    address adminAddress,
    uint256 tokenAmount,
    address tokenAddress
  );
  event RefundCurrency(string orderID);
  event RefundToken(string orderID);

  constructor() {
    adminAddress = msg.sender;
  }

  // For owner
  function setupOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(!operators[operatorAddress], "Operator already exists.");
    operators[operatorAddress] = true;
  }

  function removeOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(operators[operatorAddress], "Operator not setup yet.");
    operators[operatorAddress] = false;
  }

  function setAdminAddress(address _adminAddress)
    external
    onlyOwner
    isValidAddress(_adminAddress)
  {
    adminAddress = _adminAddress;
  }

  // For operator
  function setupToken(address _token) external onlyOperater {
    require(!tokens[_token], "Token already setup.");

    tokens[_token] = true;
  }

  function removeToken(address _token) external onlyOperater {
    require(tokens[_token], "Token not setup yet.");

    tokens[_token] = false;
  }

  function withdrawCurrency(uint256 currencyAmount) external onlyOperater {
    require(currencyAmount > 0, "Withdraw amount invalid.");

    require(
      currencyAmount <= address(this).balance,
      "Not enough amount to withdraw."
    );

    require(adminAddress != address(0), "Invalid admin address.");

    payable(adminAddress).transfer(currencyAmount);

    emit WithdrawCurrency(adminAddress, currencyAmount);
  }

  function withdrawToken(uint256 tokenAmount, address tokenAddress)
    external
    onlyOperater
    isTokenExist(tokenAddress)
  {
    require(tokenAmount > 0, "Withdraw amount invalid.");

    require(
      tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)),
      "Not enough amount to withdraw."
    );

    require(adminAddress != address(0), "Invalid admin address.");

    IERC20(tokenAddress).safeTransfer(adminAddress, tokenAmount);

    emit WithdrawToken(adminAddress, tokenAmount, tokenAddress);
  }

  function refundOrder(string memory orderID, address buyer)
    external
    onlyOperater
    isValidAddress(buyer)
  {
    (
      string memory existingOrderID,
      uint256 cryptoAmount,
      address cryptoContract
    ) = _findPurchase(orderID, buyer);

    require(bytes(existingOrderID).length > 0, "Order not found.");

    require(
      !refundHistory[existingOrderID],
      "Purchase has been already refunded."
    );

    require(cryptoAmount > 0, "Refund amount invalid.");

    if (cryptoContract == address(0)) {
      require(
        cryptoAmount <= address(this).balance,
        "Not enough amount of native token to refund."
      );

      payable(buyer).transfer(cryptoAmount);

      refundHistory[existingOrderID] = true;

      emit RefundCurrency(existingOrderID);
    } else {
      require(
        cryptoAmount <= IERC20(cryptoContract).balanceOf(address(this)),
        "Not enough amount of token to refund."
      );

      IERC20(cryptoContract).safeTransfer(buyer, cryptoAmount);

      refundHistory[existingOrderID] = true;

      emit RefundToken(existingOrderID);
    }
  }

  // For user
  function purchaseByCurrency(
    string memory _voucherID,
    string memory _fromFiatID,
    string memory _toCryptoID,
    uint256 _fiatDenomination,
    string memory _orderID
  ) external payable {
    require(msg.value >= 0, "Transfer amount invalid.");

    require(msg.sender.balance >= msg.value, "Insufficient token balance.");

    Purchase memory purchase = Purchase({
      orderID: _orderID,
      cryptoAmount: msg.value,
      cryptoContract: address(0),
      purchaseTime: block.timestamp
    });

    purchaseHistory[msg.sender].push(purchase);

    emit PurchaseByCurrency(
      _voucherID,
      _fromFiatID,
      _toCryptoID,
      _fiatDenomination,
      msg.value,
      _orderID,
      block.timestamp
    );
  }

  function purchaseByToken(
    string memory _voucherID,
    string memory _fromFiatID,
    string memory _toCryptoID,
    uint256 _fiatDenomination,
    uint256 _cryptoAmount,
    address token,
    string memory _orderID
  ) external isTokenExist(token) {
    require(_cryptoAmount >= 0, "Transfer amount invalid.");

    require(
      IERC20(token).balanceOf(msg.sender) >= _cryptoAmount,
      "Insufficient token balance."
    );

    IERC20(token).safeTransferFrom(msg.sender, address(this), _cryptoAmount);

    Purchase memory purchase = Purchase({
      orderID: _orderID,
      cryptoAmount: _cryptoAmount,
      cryptoContract: token,
      purchaseTime: block.timestamp
    });

    purchaseHistory[msg.sender].push(purchase);

    emit PurchaseByToken(
      _voucherID,
      _fromFiatID,
      _toCryptoID,
      _fiatDenomination,
      _cryptoAmount,
      _orderID,
      block.timestamp
    );
  }

  modifier onlyOperater() {
    require(operators[msg.sender], "You are not Operator");
    _;
  }

  modifier isValidAddress(address _address) {
    require(_address != address(0), "Invalid address.");
    _;
  }

  modifier isTokenExist(address _address) {
    require(tokens[_address] == true, "Token is not exist.");
    _;
  }

  // Help functions
  function _findPurchase(string memory _orderID, address _buyer)
    internal
    view
    isValidAddress(_buyer)
    returns (
      string memory orderID,
      uint256 cryptoAmount,
      address cryptoContract
    )
  {
    require(bytes(_orderID).length > 0, "OrderID must not be empty.");

    for (uint256 i = 0; i < purchaseHistory[_buyer].length; i++) {
      if (
        keccak256(abi.encodePacked(purchaseHistory[_buyer][i].orderID)) ==
        keccak256(abi.encodePacked(_orderID))
      ) {
        return (
          purchaseHistory[_buyer][i].orderID,
          purchaseHistory[_buyer][i].cryptoAmount,
          purchaseHistory[_buyer][i].cryptoContract
        );
      }
    }
  }
}
