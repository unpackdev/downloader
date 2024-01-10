// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./NftTokenHandler.sol";

contract NftMarket is AccessControl, ReentrancyGuard, Pausable {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  using SafeMath for uint256;
  address private serviceAccount;
  address private dealerOneTimeOperator;
  address public dealerContract;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    serviceAccount = msg.sender;
    dealerOneTimeOperator = msg.sender;
  }

  function alterServiceAccount(address account) public onlyRole(ADMIN_ROLE) {
    serviceAccount = account;
  }

  function alterDealerContract(address _dealerContract) public {
    require(msg.sender == dealerOneTimeOperator, "Permission Denied.");
    dealerOneTimeOperator = address(0);
    dealerContract = _dealerContract;
  }

  event Deal (
    address currency,
    address indexed nftContract,
    uint256 tokenId,
    address seller,
    address buyer,
    uint256 price,
    uint256 comission,
    uint256 roality,
    uint256 dealTime,
    bytes32 indexed tokenIndex,
    bytes32 indexed dealIndex
  );

  function pause() public onlyRole(ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(ADMIN_ROLE) {
    _unpause();
  }
  
  function indexToken(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  function indexDeal(bytes32 tokenIndex, address seller, address buyer, uint256 dealTime) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenIndex, seller, buyer, dealTime));
  }

  function isMoneyApproved(IERC20 money, address account, uint256 amount) public view returns (bool) {
    if (money.allowance(account, address(this)) >= amount) return true;
    if (money.balanceOf(account) >= amount) return true;
    return false;
  }

  function isNftApproved(address nftContract, uint256 tokenId, address owner) public view returns (bool) {
    return NftTokenHandler.isApproved(nftContract, tokenId, owner, address(this));
  }

  function _dealPayments(
    uint256 price,
    uint256 comission,
    uint256 roality
  ) private pure returns (uint256[3] memory) {

    uint256 serviceFee = price
      .mul(comission).div(1000);

    uint256 roalityFee = roality > 0 ? 
      price.mul(roality).div(1000) : 0;

    uint256 sellerEarned = price
      .sub(serviceFee)
      .sub(roalityFee);

    return [sellerEarned, serviceFee, roalityFee];
  }

  function _payByPayable(address[3] memory receivers, uint256[3] memory payments) private {
      
    if(payments[0] > 0) payable(receivers[0]).transfer(payments[0]); // seller : sellerEarned
    if(payments[1] > 0) payable(receivers[1]).transfer(payments[1]); // serviceAccount : serviceFee
    if(payments[2] > 0) payable(receivers[2]).transfer(payments[2]); // roalityAccount : roalityFee
      
  }

  function _payByERC20(
    address erc20Contract, 
    address buyer,
    uint256 price,
    address[3] memory receivers, 
    uint256[3] memory payments) private {
    
    IERC20 money = IERC20(erc20Contract);
    require(money.balanceOf(buyer) >= price, "Buyer doesn't have enough money to pay.");
    require(money.allowance(buyer, address(this)) >= price, "Buyer allowance isn't enough.");

    money.transferFrom(buyer, address(this), price);
    if(payments[0] > 0) money.transfer(receivers[0], payments[0]); // seller : sellerEarned
    if(payments[0] > 0) money.transfer(receivers[1], payments[1]); // serviceAccount : serviceFee
    if(payments[0] > 0) money.transfer(receivers[2], payments[2]); // roalityAccount : roalityFee

  }

  function deal(
    address erc20Contract,
    address nftContract,
    uint256 tokenId,
    address seller,
    address buyer,
    uint256 price,
    uint256 comission,
    uint256 roality,
    address roalityAccount,
    bytes32 dealIndex
  ) 
    public 
    nonReentrant 
    whenNotPaused
    payable
  {
    require(msg.sender == dealerContract, "Permission Denied.");
    require(isNftApproved(nftContract, tokenId, seller), "Doesn't have approval of this token.");
    
    uint256[3] memory payments = _dealPayments(price, comission, roality);
    
    if(erc20Contract == address(0) && msg.value > 0) {
      require(msg.value == price, "Payment amount incorrect.");
      _payByPayable([seller, serviceAccount, roalityAccount], payments);
    } else {
      _payByERC20(erc20Contract, buyer, price, [seller, serviceAccount, roalityAccount], payments);
    }

    NftTokenHandler.transfer(nftContract, tokenId, seller, buyer, abi.encodePacked(dealIndex));
    
    emit Deal(
      erc20Contract,
      nftContract,
      tokenId,
      seller,
      buyer,
      price,
      payments[1],
      payments[2],
      block.timestamp,
      indexToken(nftContract, tokenId),
      dealIndex
    );
  }

}