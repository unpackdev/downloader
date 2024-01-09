// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC165.sol";

abstract contract Royalty is ERC165 {
  address private _royaltyReceiver;
  uint256 private _royaltyBps;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165)
    returns (bool)
  {
    return
      interfaceId == 0x2a55205a ||
      interfaceId == 0xb7799584 ||
      super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    public
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    if (_royaltyReceiver == address(0)) {
      return (address(0), 0);
    }

    return (_royaltyReceiver, (_salePrice * _royaltyBps) / 10000);
  }

  function getFeeRecipients(uint256 id)
    public
    view
    returns (address payable[] memory)
  {
    address payable[] memory result = new address payable[](1);
    result[0] = payable(address(_royaltyReceiver));
    return result;
  }

  function getFeeBps(uint256 id) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = _royaltyBps;
    return result;
  }

  function _setRoyalty(address _receiver, uint256 _value) internal virtual {
    _royaltyReceiver = _receiver;
    _royaltyBps = _value;
  }
}
