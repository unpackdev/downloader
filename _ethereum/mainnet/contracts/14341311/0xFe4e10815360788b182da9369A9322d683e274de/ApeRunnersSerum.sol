// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Controllable.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

/// @title Ape Runners Serum
/// @author naomsa <https://twitter.com/naomsa666>
contract ApeRunnersSerum is Ownable, Pausable, Controllable, ERC1155 {
  using Strings for uint256;

  /* -------------------------------------------------------------------------- */
  /*                                Sale Details                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Utility token contract address.
  IRUN public utilityToken;

  /* -------------------------------------------------------------------------- */
  /*                              Metadata Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Base metadata uri.
  string public baseURI;

  /// @notice Base metadata uri extension.
  string public baseExtension;

  constructor(
    string memory newBaseURI,
    string memory newBaseExtension,
    address newUtilityToken
  ) {
    // Set variables
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
    utilityToken = IRUN(newUtilityToken);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Sale Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Buy one or more serums.
  /// @param serum Serum id to buy.
  /// @param amount Amount to buy.
  function buy(uint256 serum, uint256 amount) external {
    require(
      serum == 1 || serum == 2 || serum == 3,
      "Query for nonexisting serum"
    );

    require(
      totalSupply[serum] + amount <= maxSuppply(serum),
      "Serum max supply exceeded"
    );

    require(amount > 0, "Invalid buy amount");

    utilityToken.burn(msg.sender, price(serum) * amount);
    _mint(msg.sender, serum, amount, "");
  }

  /// @notice Retrieve serum cost.
  /// @param serum Serum 1, 2 or 3.
  function price(uint256 serum) public pure returns (uint256) {
    if (serum == 1) return 300 ether;
    else if (serum == 2) return 900 ether;
    else if (serum == 3) return 3000 ether;
    else revert("Query for nonexisting serum");
  }

  /// @notice Retrieve serum max supply.
  /// @param serum Serum 1, 2 or 3.
  function maxSuppply(uint256 serum) public pure returns (uint256) {
    if (serum == 1) return 4500;
    else if (serum == 2) return 490;
    else if (serum == 3) return 10;
    else revert("Query for nonexisting serum");
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set baseURI to `newBaseURI`.
  /// @param newBaseURI New base uri.
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /// @notice Set baseExtension to `newBaseExtension`.
  /// @param newBaseExtension New base uri.
  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  /// @notice Set utilityToken to `newUtilityToken`.
  /// @param newUtilityToken New utility token.
  function setUtilityToken(address newUtilityToken) external onlyOwner {
    utilityToken = IRUN(newUtilityToken);
  }

  /// @notice Toggle if the contract is paused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                               ERC-1155 Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint new tokens with `ids` at `amounts` to `to`.
  /// @param to Address of the recipient.
  /// @param ids Array of token ids.
  /// @param amounts Array of amounts.
  function mint(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyController {
    _mintBatch(to, ids, amounts, "");
  }

  /// @notice Burn tokens with `ids` at `amounts` from `from`.
  /// @param from Address of the owner.
  /// @param ids Array of token ids.
  /// @param amounts Array of amounts.
  function burn(
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyController {
    _burnBatch(from, ids, amounts);
  }

  /// @notice See {ERC1155-uri}.
  function uri(uint256 id) public view override returns (string memory) {
    require(super.exists(id), "Query for nonexisting serum");
    return string(abi.encodePacked(baseURI, id.toString(), baseExtension));
  }

  /// @notice See {ERC1155-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    require(!super.paused() || msg.sender == super.owner(), "Pausable: paused");
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}

interface IRUN {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}
