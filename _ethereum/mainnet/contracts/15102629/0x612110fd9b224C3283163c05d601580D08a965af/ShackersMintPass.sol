// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract ShackersMintPass is ERC1155, ERC1155Supply, Ownable {

  string public constant name = "Shackers MintPass";

  string public constant symbol = "SMP";

  error SMP_NoSuchPass();
  error SMP_PassLocked();
  error SMP_OverMaxSupply();
  error SMP_MaxSupplyBelowMintedSupply();
  error SMP_OnlyMinter();
  error SMP_OnlyBurner();

  struct MintPass {
    bool locked;
    uint96 maxSupply;
    uint96 mintedSupply;
    address minterContract;
    address burnerContract;
    string uri;
  }

  mapping(uint256 => MintPass) public mintPasses;

  uint256 private passCounter;

  constructor() ERC1155("") {}

  function addMintPass(
    uint96 maxSupply,
    address minterContract,
    address burnerContract,
    string calldata passUri
  ) external onlyOwner {
    mintPasses[passCounter++] = MintPass(
      false,
      maxSupply,
      0,
      minterContract,
      burnerContract,
      passUri
    );
  }

  function editMintPass(
    uint256 passId,
    uint96 maxSupply,
    address minterContract,
    address burnerContract,
    string calldata passUri
  ) external onlyOwner {
    if (passId >= passCounter) revert SMP_NoSuchPass();

    MintPass storage mp = mintPasses[passId];
    if (mp.locked) revert SMP_PassLocked();
    if (maxSupply < mp.mintedSupply) revert SMP_MaxSupplyBelowMintedSupply();

    mp.maxSupply = maxSupply;
    mp.minterContract = minterContract;
    mp.burnerContract = burnerContract;
    mp.uri = passUri;
  }

  function lockMintPass(uint256 passId) external onlyOwner {
    if (passId >= passCounter) revert SMP_NoSuchPass();

    MintPass storage mp = mintPasses[passId];
    if (mp.locked) revert SMP_PassLocked();

    mp.locked = true;
  }

  function uri(uint256 passId) public view virtual override returns (string memory) {
    if (passId >= passCounter) revert SMP_NoSuchPass();
    return mintPasses[passId].uri;
  }

  function mint(
    address to,
    uint256 id,
    uint96 amount
  ) external {
    if (id >= passCounter) revert SMP_NoSuchPass();

    MintPass storage mp = mintPasses[id];
    if (mp.minterContract != msg.sender) revert SMP_OnlyMinter();
    if (mp.mintedSupply + amount > mp.maxSupply) revert SMP_OverMaxSupply();

    mp.mintedSupply += amount;
    _mint(to, id, amount, "");
  }

  function burn(
    address from,
    uint256 id,
    uint96 amount
  ) external {
    if (id >= passCounter) revert SMP_NoSuchPass();

    MintPass storage mp = mintPasses[id];
    if (mp.burnerContract != msg.sender) revert SMP_OnlyBurner();

    _burn(from, id, amount);
  }

  // region Default Overrides

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}
