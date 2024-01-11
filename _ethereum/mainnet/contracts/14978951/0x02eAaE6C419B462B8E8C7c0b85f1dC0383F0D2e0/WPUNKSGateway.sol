// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./ILendingPool.sol";
import "./INToken.sol";
import "./IPunks.sol";
import "./IWrappedPunks.sol";
import "./IWPUNKSGateway.sol";

contract WPUNKSGateway is IWPUNKSGateway, IERC721Receiver, Ownable {
  
  IPunks internal immutable PUNKS;
  IWrappedPunks internal immutable WPUNKS;
  address internal immutable proxy;

  constructor(address punks, address wrappedPunks) public {
    PUNKS = IPunks(punks);
    WPUNKS = IWrappedPunks(wrappedPunks);
    WPUNKS.registerProxy();
    proxy = WPUNKS.proxyInfo(address(this));    
  }

  function authorizeLendingPool(address lendingPool) external onlyOwner {
    WPUNKS.setApprovalForAll(lendingPool, true);
  }

  function _mintToWPUNKS(
    uint256[] calldata punkIndices,
    uint256[] calldata amounts) internal {
    require(punkIndices.length == amounts.length, "PunkGateway: Invalid amount");
    for(uint256 i = 0; i < punkIndices.length; ++i){
      uint256 punkIndex = punkIndices[i];
      address owner = PUNKS.punkIndexToAddress(punkIndex);
      require(amounts[i] > 0, "PunkGateway: Invalid amount");
      require(owner == _msgSender(), "PunkGateway: not owner of punkIndex");
      PUNKS.buyPunk(punkIndex);
      PUNKS.transferPunk(proxy, punkIndex);
      WPUNKS.mint(punkIndex);
    }
  }
  
  function depositPUNKS(
    address lendingPool, 
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 referralCode
  ) external override {
    _mintToWPUNKS(punkIndices, amounts);
    ILendingPool(lendingPool).depositNFT(address(WPUNKS), punkIndices, amounts, onBehalfOf, referralCode);
  }

  function depositAndLockPUNKS(
    address lendingPool,
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 lockType,
    uint16 referralCode
  ) external override {
    _mintToWPUNKS(punkIndices, amounts);
    ILendingPool(lendingPool).depositAndLockNFT(address(WPUNKS), punkIndices, amounts, onBehalfOf, lockType, referralCode);
  }

  function withdrawPUNKS(
    address lendingPool,
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address to
  ) external override {
    require(punkIndices.length == amounts.length, "PunkGateway: Invalid amount");
    INToken nPUNKS = INToken(ILendingPool(lendingPool).getNFTVaultData(address(WPUNKS)).nTokenAddress);
    for(uint256 i = 0; i < punkIndices.length; ++i){
      nPUNKS.safeTransferFrom(msg.sender, address(this), punkIndices[i]);
    }
    ILendingPool(lendingPool).withdrawNFT(address(WPUNKS), punkIndices, amounts, address(this));
    for(uint256 i = 0; i < punkIndices.length; ++i){
      uint256 punkIndex = punkIndices[i];
      WPUNKS.burn(punkIndex);
      PUNKS.transferPunk(to, punkIndex);
    }
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }

  /**
   * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param nft nft to transfer
   * @param to recipient of the transfer
   */
  function emergencyNFTTransfer(
    address nft,
    address to,
    uint256 tokenId
  ) external onlyOwner {
    IERC721(nft).safeTransferFrom(address(this), to, tokenId);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /**
   * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
   * due selfdestructs or transfer ether to pre-computated contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    _safeTransferETH(to, amount);
  }

  function onERC721Received(
    address operator, 
    address from, 
    uint256 tokenId, 
    bytes calldata data
  ) external override returns (bytes4)
  {
    return this.onERC721Received.selector;
  }

  function getPUNKSAddress() external view returns (address) {
    return address(PUNKS);
  }

  function getWPUNKSAddress() external view returns (address) {
    return address(WPUNKS);
  }

  function getWPUNKSProxyAddress() external view returns (address) {
    return address(proxy);
  }

  /**
   * @dev
   */
  receive() external payable {
    revert("Receive not allowed");
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert("Fallback not allowed");
  }

  
}
