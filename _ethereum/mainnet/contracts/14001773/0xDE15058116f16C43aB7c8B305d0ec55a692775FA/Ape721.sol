// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./SafeTransferLib.sol";

import "./Ownable.sol";
import "./IERC721.sol";
import "./Strings.sol";

error DoesNotExist();
error NoTokensLeft();
error NotEnoughETH();
error AssertionError();
error NotTokenOwner();
error MintNotActive();
error MintAlreadyActive();
error MintLimitPerTx();

contract xApe721 is Ownable, ERC721 {
  using Strings for uint256;

  uint256 public constant TOTAL_SUPPLY = 10_000;
  uint256 public constant PRICE_PER_MINT = 0.05 ether;
  uint256 public constant MAX_MINT_PER_TX = 20;

  bool public mintActive;

  uint256 public totalSupply;

  string public baseURI;

  IERC721 public oldContract = IERC721(0x090b1DE324fEA5f0A0B4226101Db645819102629);
  address private teamWallet = 0xC7639015cB3da4FDd1C8c1925B22fB32ae133dAb;

  address private dev1Wallet = 0x29c36265c63fE0C3d024b2E4d204b49deeFdD671;
  address private dev2Wallet = 0x0c4618FfbE21f926d040043976457d0a489ea360;

  uint256 private devMints = 0;

  constructor(
    string memory name,
    string memory symbol,
    string memory _baseURI,
    address _oldContract,
    address _dev1Wallet,
    address _dev2Wallet,
    address _teamWallet
  ) payable ERC721(name, symbol) {
    baseURI = _baseURI;

    if (_oldContract != address(0)) {
      oldContract = IERC721(_oldContract);
    }

    if (_dev1Wallet != address(0)) {
      dev1Wallet = _dev1Wallet;
    }

    if (_dev2Wallet != address(0)) {
      dev2Wallet = _dev2Wallet;
    }

    if (_teamWallet != address(0)) {
      teamWallet = _teamWallet;
    }
  }

  modifier onlyTeamWallet() {
    require(msg.sender == teamWallet, "Not callable except by team wallet");
    _;
  }

  modifier onlyDev() {
    require(
      (msg.sender == dev1Wallet || msg.sender == dev2Wallet),
      "Only callable by devs");
    _;
  }

  modifier devMintLimit(uint256 amount) {
    require(devMints + amount <= 6, "Devs only promised 3 free mints each");
    _;
  }

  function mint(uint16 amount) external payable {
    if (!mintActive) revert MintNotActive();
    if (totalSupply + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
    if (msg.value < amount * PRICE_PER_MINT) revert NotEnoughETH();
    if (amount > MAX_MINT_PER_TX) revert MintLimitPerTx();

    unchecked {
      for (uint16 index = 0; index < amount; index++) {
        uint256 newId = _getNextUnusedID(totalSupply++);
        _mint(msg.sender, newId);
      }
    }
  }

  function claim(uint256 tokenId) external payable {
    if (_ownsOldToken(msg.sender, tokenId))  {
      // Transfering into this contract effectively burns the old
      // token as there is no way to get it out of here
      oldContract.safeTransferFrom(msg.sender, address(this), tokenId);
      _mint(msg.sender, tokenId);
      return;
    }
    revert NotTokenOwner();
  }

  function claimAll() external payable {
    uint256[] memory ownedTokens = oldContract.getPhunksBelongingToOwner(msg.sender);
    uint256 length = ownedTokens.length; // gas saving

    for (uint256 i; i < length; ++i) {
      if (ownerOf[ownedTokens[i]] == address(0)) {
        // Has not been claimed yet

        // Transfering into this contract effectively burns the
        // old token as there is no way to get it out of here
        oldContract.safeTransferFrom(msg.sender, address(this), ownedTokens[i]);
        _mint(msg.sender, ownedTokens[i]);
      }
    }
  }

  function _ownsOldToken(address account, uint256 tokenId) internal view returns(bool) {
    try oldContract.ownerOf(tokenId) returns (address tokenOwner) {
      return account == tokenOwner;
    } catch Error(string memory /*reason*/) {
      return false;
    }
  }

  function _getNextUnusedID(uint256 currentSupply) internal view returns (uint256) {
    uint256 newId = 10000 + currentSupply; // IDs start at 10000

    // Using 10 iterations instead of while loop as it is known
    // that the maximum contiguous group of successive IDs in
    // the original contract is 7 (14960-14966). Cannot have unbounded gas usage
    for (uint256 i; i < 10; ++i) {
      if (ownerOf[newId] != address(0)) {
        // Token is owned in this contract
        newId++;
        continue;
      }

      try oldContract.ownerOf(newId) returns (address) {
        // Token is owned in the old contract
        // ownerOf always reverts if the token isn't owned
        // so no need for zero check here
        newId++;
        continue;
      } catch Error(string memory /*reason*/) {
        return newId;
      }
    }
    revert AssertionError();
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    if (ownerOf[id] == address(0)) revert DoesNotExist();

    return string(abi.encodePacked(baseURI, id.toString()));
  }

  function withdraw() external onlyTeamWallet() {
    SafeTransferLib.safeTransferETH(teamWallet, address(this).balance);
  }

  function devMint(uint16 amount) external onlyDev() devMintLimit(amount) {
    if (totalSupply + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
    
    unchecked {
      for (uint16 index = 0; index < amount; index++) {
        uint256 newId = _getNextUnusedID(totalSupply++);
        _mint(msg.sender, newId);
        devMints++;
      }
    }
  }

  function pauseMint() external {
    if (msg.sender != _owner) revert NotOwner();
    if (!mintActive) revert MintNotActive();

    mintActive = false;
  }

  function startMint() external {
    if (msg.sender != _owner) revert NotOwner();
    if (mintActive) revert MintAlreadyActive();

    mintActive = true;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override
    returns (bool)
  {
    return
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
      interfaceId == 0x150b7a02;   // ERC721 Receiver
  }

  function onERC721Received(
      address operator,
      address from,
      uint256 tokenId,
      bytes calldata data
  ) external returns (bytes4) {
      return 0x150b7a02;
  }
}
