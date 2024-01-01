// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "./IPresaleMintableMulti.sol";
import "./IPresaleMintableSingle.sol";

abstract contract ProcessPresaleMintable {
  enum PresaleType {
    Single,
    Multi
  }

  struct PresaleMinterInfo {
    PresaleType presaleType;
    address minterAddress; // casted as IPresaleMintableSingle or IPresaleMintableMulti
    uint256 collectionId;
    uint256 price;
  }

  // TODO: send value along with this method
  function _processPresaleMinter(PresaleMinterInfo memory _presaleMinter, address _receiver, uint256 _amount, uint256 _price) internal {
    if (_presaleMinter.presaleType == PresaleType.Multi) {
      IPresaleMintableMulti(_presaleMinter.minterAddress).presaleMint{value: _price}(_presaleMinter.collectionId, _receiver, _amount);
    } else if (_presaleMinter.presaleType == PresaleType.Single) {
      IPresaleMintableSingle(_presaleMinter.minterAddress).presaleMint{value: _price}(_receiver, _amount);
    }
  }
}