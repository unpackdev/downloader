// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./ERC721Holder.sol";
import "./IEthemeralsLike.sol";

contract EthemeralsBurner is ERC721Holder {

  event MeralBurnt(uint256 tokenId);
  event PropsChange(uint16 burnableLimit, uint16 maxTokenId);

  /*///////////////////////////////////////////////////////////////
                  STORAGE
  //////////////////////////////////////////////////////////////*/

  uint16 public count;
  uint16 public burnableLimit;
  uint16 public maxTokenId;

  address public admin;
  address public burnAddress;

  IEthemeralsLike coreContract;

  /*///////////////////////////////////////////////////////////////
                  ADMIN FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  constructor(address _coreAddress) {
    admin = msg.sender;
    coreContract = IEthemeralsLike(_coreAddress);
  }

  function setProps(uint16 _burnableLimit, uint16 _maxTokenId) external {
    require(msg.sender == admin, 'admin only');
    burnableLimit = _burnableLimit;
    maxTokenId = _maxTokenId;
    emit PropsChange(_burnableLimit, _maxTokenId);
  }

  function setBurnAddress(address _burnAddress) external {
    require(msg.sender == admin, 'admin only');
    burnAddress = _burnAddress;
  }

  function transferCoreOwnership(address newOwner) external {
    require(msg.sender == admin, 'admin only');
    coreContract.transferOwnership(newOwner);
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/


  function _mintAdmin(address recipient, uint _amount) internal {
    coreContract.mintMeralsAdmin(recipient, _amount);
  }

  /*///////////////////////////////////////////////////////////////
                  PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
    * @dev user can burn meral for new meral:
    * - sends merals to admin controlled 'burn_address'
    * - subgraph marks meral as burn and removes metadata
    * Requirements:
    * - max burnable not reached
    * - max tokenId not reached (generation)\
    */
  function onERC721Received(
    address,
    address from,
    uint tokenId,
    bytes calldata
  ) public override returns (bytes4) {
    require(count + 1 <= burnableLimit, 'max reached');
    require(tokenId <= maxTokenId, 'max gen');

    count ++;
    _mintAdmin(from, 1);
    coreContract.safeTransferFrom(address(this), burnAddress, tokenId);

    emit MeralBurnt(tokenId);
    return this.onERC721Received.selector;
  }

}
