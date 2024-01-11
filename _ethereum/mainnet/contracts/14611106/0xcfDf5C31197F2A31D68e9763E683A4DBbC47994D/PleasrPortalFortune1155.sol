//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./ERC1155CreatorCore.sol";
import "./CreatorExtension.sol";
import "./ERC1155CreatorCore.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract PleasrPortalFortune1155 is CreatorExtension, Ownable {
  //Fortune contract 1155: 0x47E22659d9aE152975e6CBFa2EED5DC8B75Ac545
  ERC1155 private _fortuneContractAspiringChads;
  uint256 private _aspiringChadTokenId = 1;
  // pplpleasr 1155 creator contract: ???
  IERC1155CreatorCore private _creator;
  // used to store the tokenId we get from mintNew, and to use for subsequent mintExisting
  uint256 public _redemptionTokenId;
  uint256 public _totalMinted;
  uint256 private _maxSupply;
  bool private _isActive;

  constructor(
    address creator,
    address redeemableContract,
    uint256 maxSupply
  ) {
    _creator = IERC1155CreatorCore(creator);
    _fortuneContractAspiringChads = ERC1155(redeemableContract);
    _maxSupply = maxSupply;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(CreatorExtension)
    returns (bool)
  {
    return
      interfaceId == type(CreatorExtension).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setIsActive(bool isActive) external onlyOwner {
    _isActive = isActive;
  }

  function redeem() public {
    require(_isActive, "redemption not active");
    uint256 balanceOfToken = _fortuneContractAspiringChads.balanceOf(
      msg.sender,
      _aspiringChadTokenId
    );
    require(balanceOfToken > 0, "Don't have this token in your wallet");
    require(
      _totalMinted + balanceOfToken <= _maxSupply,
      "max supply reached for redemption"
    );
    // burn
    _fortuneContractAspiringChads.safeTransferFrom(
      msg.sender,
      address(0xdEaD),
      _aspiringChadTokenId,
      balanceOfToken,
      ""
    );

    address[] memory addresses = new address[](1);
    addresses[0] = msg.sender;
    uint256[] memory balancesOfToken = new uint256[](1);
    balancesOfToken[0] = balanceOfToken;
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = _redemptionTokenId;

    // first person to mint, create new token, otherwise mint existing
    if (_totalMinted == 0) {
      string[] memory uris = new string[](1);
      uris[0] = _fortuneContractAspiringChads.uri(1);
      _redemptionTokenId = _creator.mintExtensionNew(
        addresses,
        balancesOfToken,
        uris
      )[0];
    } else {
      _creator.mintExtensionExisting(addresses, tokenIds, balancesOfToken);
    }
    _totalMinted = _totalMinted + balanceOfToken;
  }
}
