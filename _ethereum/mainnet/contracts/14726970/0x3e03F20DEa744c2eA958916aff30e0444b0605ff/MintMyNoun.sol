// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 * MyNouns.sol
 *
 * Author: Badu Blanc // badublanc.eth // twitter: badublanc
 * Created: May 6th, 2022
 * Acknowledgements: NounsDAO, Nouns Prop House, Austin Griffith, Buildspace
 * More info at mintmynoun.xyz
 *
 * Mint Price:
 *   - Free if only minting one at a time
 *   - 0.01 ETH per token if minting in bulk
 *
 * ███    ██  ██████  ██    ██ ███    ██ ██ ███████ ██   ██
 * ████   ██ ██    ██ ██    ██ ████   ██ ██ ██      ██   ██
 * ██ ██  ██ ██    ██ ██    ██ ██ ██  ██ ██ ███████ ███████
 * ██  ██ ██ ██    ██ ██    ██ ██  ██ ██ ██      ██ ██   ██
 * ██   ████  ██████   ██████  ██   ████ ██ ███████ ██   ██
 *
 */

import "./ERC721.sol";
import "./Utils.sol";

error HoldsNoTokens();
error MintingPaused();
error TokenDoesNotExist(uint256 tokenId);
error WrongEtherAmount();

interface INounsSeeder {
  struct Seed {
    uint48 background;
    uint48 body;
    uint48 accessory;
    uint48 head;
    uint48 glasses;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

interface IERC2981 {
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

contract MyNouns is ERC721, IERC2981, Ownableish, ReentrancyGuard {
  using Stringish for uint256;

  string public baseURI = "https://api.mintmynoun.xyz/tokens/";
  bool public isPaused = false;
  uint256 public totalSupply;
  uint256 public PRICE_PER_MINT = 0.01 ether;
  uint16 public ROYALTY_BPS = 500;

  event NewNoun(uint256 _id, address _owner, uint256 _ts);

  constructor() payable ERC721("My Nouns", "MYNOUN") {}

  modifier whenNotPaused() {
    if (isPaused) revert MintingPaused();
    _;
  }

  function mintOne(address _address) external whenNotPaused nonReentrant {
    uint256 _id = ++totalSupply;
    _mint(_address, _id);
    emit NewNoun(_id, _address, block.timestamp);
  }

  function bulkMint(address[] calldata _addresses)
    external
    payable
    whenNotPaused
    nonReentrant
  {
    uint256 amount = _addresses.length;
    if (msg.value != amount * PRICE_PER_MINT) {
      revert WrongEtherAmount();
    }

    for (uint16 i = 0; i < amount; i++) {
      uint256 _id = ++totalSupply;
      _mint(_addresses[i], _id);
      emit NewNoun(_id, _addresses[i], block.timestamp);
    }
  }

  function _setMintPrice(uint256 _price) external onlyOwner {
    PRICE_PER_MINT = _price;
  }

  function getTokensByOwner(address _address)
    external
    view
    returns (uint256[] memory)
  {
    uint256 balance = this.balanceOf(_address);
    if (balance == 0) revert HoldsNoTokens();

    uint256 index = 0;
    uint256[] memory tokens = new uint256[](balance);
    for (uint256 i = 1; i <= totalSupply; i++) {
      if (this.ownerOf(i) == _address) {
        tokens[index] = i;
        index++;
      }
    }
    return tokens;
  }

  function togglePause() external onlyOwner {
    isPaused = !isPaused;
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setRoyaltyBPS(uint16 _bps) external onlyOwner {
    ROYALTY_BPS = _bps;
  }

  function withdrawETH() external {
    SafeTransferLib.safeTransferETH(_owner, address(this).balance);
  }

  function withdrawERC20(address _contract) external {
    SafeTransferLib.safeTransfer(
      _contract,
      _owner,
      IERC20(_contract).balanceOf(address(this))
    );
  }

  function withdrawERC721(address _contract, uint256 _token) external {
    ERC721(_contract).safeTransferFrom(address(this), _owner, _token);
  }

  function tokenURI(uint256 _id) public view override returns (string memory) {
    if (ownerOf[_id] == address(0)) revert TokenDoesNotExist(_id);
    return string(abi.encodePacked(baseURI, _id.toString()));
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = address(this);
    royaltyAmount = (_salePrice * ROYALTY_BPS) / 10000;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(ERC721, Ownableish)
    returns (bool)
  {
    return
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
