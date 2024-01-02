
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.17;

import "./IERC2981.sol";

import "./Initializable.sol";

contract RoyaltiesUpgradeable is Initializable, IERC2981{
  struct Fraction{
    uint16 numerator;
    uint16 denominator;
  }

  struct Royalty{
    address payable receiver;
    Fraction fraction;
  }

  Royalty public defaultRoyalty;
  //mapping(uint => Royalty) public tokenRoyalties;


  // solhint-disable-next-line func-name-mixedcase
  function __Royalties_init(address payable receiver, uint16 royaltyNum, uint16 royaltyDenom) internal onlyInitializing {
    _setDefaultRoyalty(receiver, royaltyNum, royaltyDenom);
  }


  //view: IERC2981
  /**
   * @dev See {IERC2981-royaltyInfo}.
   **/
  function royaltyInfo(uint256, uint256 salePrice) public view virtual returns(address, uint256) {
    /*
    Royalty memory royalty = _tokenRoyaltyInfo[_tokenId];
    if (royalty.receiver == address(0)) {
        royalty = _defaultRoyaltyInfo;
    }
    */

    uint256 royaltyAmount = (salePrice * defaultRoyalty.fraction.numerator) / defaultRoyalty.fraction.denominator;
    return (defaultRoyalty.receiver, royaltyAmount);
  }


  //view: IERC165
  /**
   * @dev See {IERC165-supportsInterface}.
   **/
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC2981).interfaceId;
  }

  function _setDefaultRoyalty(address payable receiver, uint16 royaltyNum, uint16 royaltyDenom) internal {
    require(royaltyNum < royaltyDenom, "Royalties: invalid fraction");
    defaultRoyalty.receiver = receiver;
    defaultRoyalty.fraction = Fraction(royaltyNum, royaltyDenom);
  }
}
