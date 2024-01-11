// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title: Space Koi
 * @author: Manifest Futures
 *       ___           ___         ___           ___           ___                    ___           ___           ___           ___      
 *      /\__\         /\  \       /\  \         /\__\         /\__\                  /\  \         /\__\         /\  \         |\__\      
 *     /:/ _/_       /::\  \     /::\  \       /:/  /        /:/ _/_                /::\  \       /:/  /        /::\  \        |:|  |      
 *    /:/ /\  \     /:/\:\__\   /:/\:\  \     /:/  /        /:/ /\__\              /:/\:\  \     /:/  /        /:/\:\  \       |:|  |      
 *   /:/ /::\  \   /:/ /:/  /  /:/ /::\  \   /:/  /  ___   /:/ /:/ _/_             \:\~\:\  \   /:/  /  ___   /:/  \:\  \      |:|__|__     
 *  /:/_/:/\:\__\ /:/_/:/  /  /:/_/:/\:\__\ /:/__/  /\__\ /:/_/:/ /\__\             \:\ \:\__\ /:/__/  /\__\ /:/__/ \:\__\     /::::\__\   
 *  \:\/:/ /:/  / \:\/:/  /   \:\/:/  \/__/ \:\  \ /:/  / \:\/:/ /:/  /              \:\/:/  / \:\  \ /:/  / \:\  \ /:/  /    /:/~~/~     
 *   \::/ /:/  /   \::/__/     \::/__/       \:\  /:/  /   \::/_/:/  /                \::/  /   \:\  /:/  /   \:\  /:/  /    /:/  /      
 *    \/_/:/  /     \:\  \      \:\  \        \:\/:/  /     \:\/:/  /                 /:/  /     \:\/:/  /     \:\/:/  /     \/__/       
 *      /:/  /       \:\__\      \:\__\        \::/  /       \::/  /                 /:/  /       \::/  /       \::/  /                   
 *      \/__/         \/__/       \/__/         \/__/         \/__/                  \/__/         \/__/         \/__/                     
 *
 */

import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SpaceQuoy is ERC1155, ERC1155Holder, Ownable {
  /**
   * @dev CONTRACT DETAILS
   */
  string public name;
  string private baseURIString;

  /**
   * @dev EVENTS
   */
  event SetTokenURIEvent(address requester, string newTokenURI);
  event SetContractNameEvent(address requester, string name);
  event MintedBatch(address minter, uint256[] ids, uint256[] amounts);
  event BalanceWithdrawn(address receiver, uint256 value);
  event TokenWithdrawn(address receiver, uint256 asset, uint256 amount);

  constructor() ERC1155("https://space-quoy-api.manifutures.com/token/") {
    name = "Space Quoy";
    baseURIString = "https://space-quoy-api.manifutures.com/token/";
  }

  /**
   * @notice Check token URI for given tokenId
   * @param tokenId Space Quoy token ID
   * @return API Endpoint for token metadata
   */
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
  }

  /**
   * @notice Check the token URI
   * @return Base API endpoint for token metadata URI
   */
  function baseTokenURI() public view virtual returns (string memory) {
    return baseURIString;
  }

  /**
   * @notice Update the token URI for the contract
   * @param tokenUriBase_ New metadata endpoint to set for contract
   */
  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    baseURIString = tokenUriBase_;
    emit SetTokenURIEvent(msg.sender, tokenUriBase_);
  }

  /**
   * @notice Update the contract name
   * @param name_ New name to set for contract
   */
  function setContractName(string memory name_) public onlyOwner {
    name = name_;
    emit SetContractNameEvent(msg.sender, name_);
  }

  /**
   * @notice Mint batch of tokens for collection
   * @param ids The tokens to mint in batch
   * @param amounts The amount of each token to mint in batch
   */
  function mintBatch(uint256[] memory ids, uint256[] memory amounts)
    public
    onlyOwner
  {
    _mintBatch(msg.sender, ids, amounts, "");
    emit MintedBatch(msg.sender, ids, amounts);
  }

  /**
   * @notice Only Owner Function to withdraw ETH from contract
   * @param receiver Address to withdraw ETH to
   */
  function withdrawAllEth(address receiver) public virtual onlyOwner {
    uint256 balance = address(this).balance;
    payable(receiver).transfer(balance);
    emit BalanceWithdrawn(receiver, balance);
  }

  /**
   * @notice Only Owner Function to withdraw token stuck on contract
   * @param _asset Asset to withdraw from contract
   * @param _amount Amount of asset to withdraw from the contract
   */
  function emergencyTokenWithdraw(uint256 _asset, uint256 _amount)
    public
    onlyOwner
  {
    _safeTransferFrom(address(this), msg.sender, _asset, _amount, "");
    emit TokenWithdrawn(msg.sender, _asset, _amount);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC1155Receiver)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
