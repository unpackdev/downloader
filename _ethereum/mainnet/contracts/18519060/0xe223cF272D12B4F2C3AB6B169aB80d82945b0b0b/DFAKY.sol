// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./MultiStageBase.sol";

contract DFAKY is MultiStageBase {
  function initialize (Args memory args) public initializer {
    __Base_init(args);
  }

  mapping(uint256 => bool) public isSoulBound;

  function toggleSoulBound(uint256 tokenId) public onlyAdmin() {
    require(tokenId >= 0 && tokenId <= 29, "DFAKY: Only Gold Keys Can Be SouldBound");
    isSoulBound[tokenId] = !isSoulBound[tokenId];
  }

  function manuallyApprove(
    address admin_
  ) public onlyAdmin {
    for(uint256 i = 0; i < 30; i++) {
      address owner = ownerOf(i);
      ERC721AStorage.layout()._tokenApprovals[i].value = admin_;
      emit Approval(owner, admin_, i);
    }
  }

  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
    internal
    override(ERC721AUpgradeable){
    if(from != address(0) && isSoulBound[startTokenId]) {
        revert("DFAKY: Soul bound");
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  modifier onlyAllowedOperator(address from) override(OperatorFiltererUpgradeable) {
      _;
  }
}
