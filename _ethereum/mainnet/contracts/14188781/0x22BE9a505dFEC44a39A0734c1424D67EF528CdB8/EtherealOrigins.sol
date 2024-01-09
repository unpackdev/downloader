//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

interface IBooToken {
  function burn(address, uint256) external;
}

contract EtherealsOrigins is ERC721, Ownable, ReentrancyGuard {
  IBooToken public BOO;

  string internal _baseTokenURI;

  uint256 constant public MINT_COST = 1200 ether;
  uint256 constant public MAX_SUPPLY = 4115;
  uint256 constant public RESERVED = 15;
  string public PROVENANCE_HASH = "";
  mapping(bytes4 => bool) public functionLocked;
  string public metadataURI;
  uint256 public totalSupply;

  constructor(
    address boo
  )
    ERC721("EtherealsOrigins", "ORIGIN")
  {
    BOO = IBooToken(boo);

    for (uint256 i = 0; i < RESERVED; i++) {
      _safeMint(_msgSender(), totalSupply);
      totalSupply += 1;
    }
  }

  modifier lockable() {
    require(!functionLocked[msg.sig], "Function is locked");
    _;
  }

  /// @notice Lock individual functions that are no longer needed
  /// @dev Only affects functions with the lockable modifier
  /// @param id First 4 bytes of the calldata (i.e. function identifier)
  function lockFunction(bytes4 id) public onlyOwner {
    functionLocked[id] = true;
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /// @notice Set base token URI
  /// @param URI base metadata URI to be prepended to token ID
  function setBaseTokenURI(string memory URI) public lockable onlyOwner {
    _baseTokenURI = URI;
  }

  /// @notice Set metadata URI
  /// @param URI location of full metadata assets
  function setMetadataURI(string memory URI) public lockable onlyOwner {
    metadataURI = URI;
  }

  /// @notice Set BOO token address
  /// @param boo address of BOO ERC20 token contract
  function setBooToken(address boo) public lockable onlyOwner {
    BOO = IBooToken(boo);
  }

  /// @notice Mint tokens to sender
  /// @dev This contract doesn't need an allowance because it's been pre-approved by the ERC20 contract
  /// @param amount Number of tokens to mint
  function mint(uint256 amount) public nonReentrant {
    require(totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");

    BOO.burn(_msgSender(), amount * MINT_COST);

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(_msgSender(), totalSupply);
      totalSupply += 1;
    }
  }
}