// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./PermissionManagement.sol";

/// @title Payable Contract
/// @author kumareth@monument.app
/// @notice If this abstract contract is inherited, the Contract becomes payable, it also allows Admins to manage Assets owned by the Contract.
abstract contract Payable {
  PermissionManagement internal permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  event ReceivedFunds(
    address indexed by,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event ERC20SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc20Token,
    uint256 tokenAmount,
    uint256 timestamp
  );

  event ERC721SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc721ContractAddress,
    uint256 tokenId,
    uint256 timestamp
  );

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  /// @notice To pay the contract
  function fund() external payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  fallback() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  receive() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  /// So the Admins can maintain control over all the Funds the Contract might own in future
  /// @notice Sends Wei the Contract might own, to the Beneficiary
  /// @param _amountInWei Amount in Wei you think the Contract has, that you want to send to the Beneficiary
  function sendToBeneficiary(uint256 _amountInWei) external returns(uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    (bool success, ) = payable(permissionManagement.beneficiary()).call{value: _amountInWei}("");
    require(success, "Transfer to Beneficiary failed.");
    
    emit SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _amountInWei, block.timestamp);
    return _amountInWei;
  }

  /// So the Admins can maintain control over all the ERC20 Tokens the Contract might own in future
  /// @notice Sends ERC20 tokens the Contract might own, to the Beneficiary
  /// @param _erc20address Address of the ERC20 Contract
  /// @param _tokenAmount Amount of Tokens you wish to send to the Beneficiary.
  function sendERC20ToBeneficiary(address _erc20address, uint256 _tokenAmount) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC20 erc20Token;
    erc20Token = IERC20(_erc20address);

    erc20Token.transfer(permissionManagement.beneficiary(), _tokenAmount);

    emit ERC20SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc20address, _tokenAmount, block.timestamp);

    return (_erc20address, _tokenAmount);
  }

  /// So the Admins can maintain control over all the ERC721 Tokens the Contract might own in future.
  /// @notice Sends ERC721 tokens the Contract might own, to the Beneficiary
  /// @param _erc721address Address of the ERC721 Contract
  /// @param _tokenId ID of the Token you wish to send to the Beneficiary.
  function sendERC721ToBeneficiary(address _erc721address, uint256 _tokenId) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC721 erc721Token;
    erc721Token = IERC721(_erc721address);

    erc721Token.safeTransferFrom(address(this), permissionManagement.beneficiary(), _tokenId);

    emit ERC721SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc721address, _tokenId, block.timestamp);

    return (_erc721address, _tokenId);
  }
}
