// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title MarketPlaceCommon
 * @dev A base contract for handling common marketplace functionalities
 */
contract MarketPlaceCommon {
  address payable public dxs;
  address payable public supplier;
  address public owner;

  uint public minProductPrice;
  uint public maxVAT = 27;

  mapping(address => uint) public purchasedBalance;

  event ProductPurchased(address indexed buyer, uint amount);

  event BalanceWithdrawn(address indexed withdrawer, uint amount);

  event SupplierChanged(
    address indexed oldSupplier,
    address indexed newSupplier
  );

  event DXSChanged(address indexed oldDXS, address indexed newDXS);

  event MinProductPriceChanged(uint oldPrice, uint newPrice);

  event OwnershipTransferred(
    address indexed oldOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize the contract
   * @param _dxs Decentrashop's address
   * @param _supplier Supplier's address
   */
  constructor(address _dxs, address _supplier) {
    require(
      _dxs != address(0),
      'Decentrashop address cannot be the zero address.'
    );

    require(
      _supplier != address(0),
      'Supplier address cannot be the zero address.'
    );

    owner = msg.sender;
    dxs = payable(_dxs);
    supplier = payable(_supplier);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'You are not the contract Owner.');
    _;
  }

  function setSupplier(address newSupplier) external onlyOwner {
    require(
      newSupplier != address(0),
      'Supplier address cannot be the zero address.'
    );
    address oldSupplier = supplier;
    supplier = payable(newSupplier);

    emit SupplierChanged(oldSupplier, newSupplier);
  }

  function setDXS(address newDXS) external onlyOwner {
    require(newDXS != address(0), 'DXS address cannot be the zero address.');
    address oldDXS = dxs;
    dxs = payable(newDXS);

    emit DXSChanged(oldDXS, newDXS);
  }

  function setMinProductPrice(uint newMinProductPrice) external onlyOwner {
    uint oldPrice = minProductPrice;
    minProductPrice = newMinProductPrice;

    emit MinProductPriceChanged(oldPrice, newMinProductPrice);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), 'New owner cannot be the zero address.');
    address oldOwner = owner;
    owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev Set the maximum VAT Possible
   * @param newMaxVAT The new minimum product price
   */
  function setMaxVAT(uint newMaxVAT) external onlyOwner {
    require(newMaxVAT <= 50, 'VAT cannot be greater than 50%.');
    maxVAT = newMaxVAT;
  }

  /**
   * @dev Rectify the balance of a wallet address
   * @param walletAddress The address of the wallet
   * @param amount The new balance of the wallet
   */
  function rectifyBalance(
    address walletAddress,
    uint amount
  ) external onlyOwner {
    purchasedBalance[walletAddress] = amount;
  }

  fallback() external {
    revert('Do not send Ether directly.');
  }
}
