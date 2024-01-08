// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./IVAndV.sol";
import "./IVAndVMinter.sol";
import "./ITraits.sol";
import "./IVillage.sol";
import "./IBattleground.sol";

contract VAndV is IVAndV, ERC721Enumerable, Ownable {
  using Address for address;
  using Strings for uint256;

  // max number of tokens that can be minted - 75000 in production
  uint256 public immutable MAX_TOKENS;
  // number of tokens that can be claimed for free - 20% of MAX_TOKENS
  uint256 public immutable PAID_TOKENS;

  // number of tokens have been minted so far
  uint16 public minted = 0;

  // refernece to V&V minter
  IVAndVMinter private vandvMinter;
  // reference to village
  IVillage private village;
  // reference to battleground (coming soon)
  IBattleground private battleground;

  /**
   * create the contract with a name and symbol and references to other contracts
   * @param _maxTokens total tokens available
   */
  constructor(uint256 _maxTokens) ERC721("Vikings & Villagers", "VANDV") {
    MAX_TOKENS = _maxTokens;
    PAID_TOKENS = _maxTokens / 5;
  }

  /**
   * mint a token to an address
   * @param to who to send the new token to
   */
  function mint(address to) external returns (uint256) {
    require(_msgSender() == address(vandvMinter), "V&V: Only minter can call this function");
    require(minted + 1 <= MAX_TOKENS, "V&V: All tokens minted");

    minted++;

    _safeMint(to, minted);

    return minted;
  }

  /**
   * @param tokenId the token ID
   * @return the token's fully formed URI to get metadata
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked("https://vikingsandvillagers.com/metadata/", tokenId.toString()));
  }

  /**
   * @param from the address sending the token
   * @param to the address we're sending to
   * @param tokenId the token ID being transferred
   */
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    // Hardcode approval for our contracts to transfer tokens to prevent users having
    // to manually approve their token for transfer, saving them gas
    if (_msgSender() != address(vandvMinter) && _msgSender() != address(village) && _msgSender() != address(battleground)) {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    }

    _transfer(from, to, tokenId);
  }

  /**
   * get how many tokens have been minted
   * @return number of tokens minted
   */
  function getMinted() external view returns (uint16) {
    return minted;
  }

  /**
   * get the number of tokens available for minting ever
   * @return max tokens
   */
  function getMaxTokens() external view returns (uint256) {
    return MAX_TOKENS;
  }

  /**
   * get the number of paid tokens
   * @return total paid tokens
   */
  function getPaidTokens() external view returns (uint256) {
    return PAID_TOKENS;
  }

  /**
   * set the address of the V&V minter contract
   * @param _vandvMinter the address
   */
  function setVAndVMinter(address _vandvMinter) external onlyOwner {
    vandvMinter = IVAndVMinter(_vandvMinter);
  }

  /**
   * set the address of the village contract
   * @param _village the address
   */
  function setVillage(address _village) external onlyOwner {
    village = IVillage(_village);
  }

  /**
   * set the address of the battleground contract
   * doesn't exist yet, will be used in the future
   * @param _battleground the address
   */
  function setBattleground(address _battleground) external onlyOwner {
    battleground = IBattleground(_battleground);
  }

}
