// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IDataStorage.sol";
import "./ISpellCompute.sol";
import "./Merge.sol";
import "./MergeMana.sol";
import "./AdminEditableStorage.sol";
import "./TransmutationRitual.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./LayerCompositeRenderer.sol";
import "./BytesUtils.sol";

contract TransmutationRitualSimulator {
  using Strings for uint256;

  Merge public merge;
  TransmutationRitual public ritual;

  constructor(address _merge, address _ritual) {
    merge = Merge(_merge);
    ritual = TransmutationRitual(_ritual);
  }

  function getComputedSeed(uint256 tokenId, bytes32 spell)
    public
    returns (bytes5)
  {
    return ritual.getComputedSeed(tokenId, getSpell(tokenId, spell));
  }

  function getSpell(uint256 tokenId, bytes32 spell) public returns (bytes32) {
    ritual.simulateRitual(tokenId, spell);
    return ritual.getSpell(tokenId);
  }

  function tokenURI(uint256 tokenId, bytes32 spell)
    public
    returns (string memory)
  {
    ritual.simulateRitual(tokenId, spell);
    return merge.tokenURI(tokenId);
  }
}
