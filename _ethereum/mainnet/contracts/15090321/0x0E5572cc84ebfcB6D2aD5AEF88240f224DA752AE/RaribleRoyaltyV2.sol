// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v2;

import "./IERC2981.sol";
import "./ERC2981.sol";
import "./AbstractRoyalties.sol";
import "./RoyaltiesV2.sol";
import "./LibRoyalties2981.sol";

contract RaribleRoyaltyV2 is AbstractRoyalties, RoyaltiesV2, ERC2981 {

  function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
    return royalties[id];
  }

  function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
    emit RoyaltiesSet(id, _royalties);
  }

  /*
  *Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155 ) can have a number of different royalties beneficiaries
  *calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
  */
  function royaltyInfo(uint256 id, uint256 _salePrice) override(ERC2981) public view returns (address receiver, uint256 royaltyAmount) {
    if (royalties[id].length == 0) {
      return super.royaltyInfo(id, _salePrice);
    }
    LibPart.Part[] memory _royalties = royalties[id];
    receiver = _royalties[0].account;
    uint percent;
    for (uint i = 0; i < _royalties.length; i++) {
      percent += _royalties[i].value;
    }
    //don`t need require(percent < 10000, "Token royalty > 100%"); here, because check later in calculateRoyalties
    royaltyAmount = percent * _salePrice / 10000;
  }


  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC2981)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
