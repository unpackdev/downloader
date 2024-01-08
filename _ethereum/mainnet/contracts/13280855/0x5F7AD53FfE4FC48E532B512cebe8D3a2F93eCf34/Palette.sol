// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";

import "./RandomColor.sol";
import "./Base64.sol";
import "./IPalette.sol";
import "./BaseOpensea.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract Palette is
  IPalette,
  RandomColor,
  ReentrancyGuard,
  Ownable,
  ERC721,
  BaseOpenSea,
  RoyaltiesV2Impl
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 public MAX_SUPPLY;
  bool public FAIR_MINT;
  uint96 public ROYALTY = 1000; // 10%

  Counters.Counter private _totalSupply;
  mapping(address => bool) private _minters;
  bytes32 private _lastSeed;
  mapping(uint256 => bytes32[]) private _tokenSeeds;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(
    uint256 maxSupply,
    bool fairMint,
    address owner,
    address openSeaProxyRegistry
  ) ERC721('PaletteOnChain', 'PALETTE') Ownable() {
    MAX_SUPPLY = maxSupply;
    FAIR_MINT = fairMint;

    if (owner != _msgSender()) {
      transferOwnership(owner);
    }

    if (openSeaProxyRegistry != address(0)) {
      _setOpenSeaRegistry(openSeaProxyRegistry);
    }
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply.current();
  }

  function remainingSupply() external view override returns (uint256) {
    return MAX_SUPPLY - _totalSupply.current();
  }

  function mint() external override nonReentrant {
    require(_totalSupply.current() < MAX_SUPPLY, 'Mint would exceed max supply');

    address operator = _msgSender();
    if (FAIR_MINT) {
      require(!_minters[operator], 'Mint only once');
    }

    _minters[operator] = true;

    bytes32 seed = _lastSeed;
    bytes32 blockHash = blockhash(block.number - 1);
    uint256 timestamp = block.timestamp;

    uint256 paletteCount = 5;
    bytes32[] memory seeds = new bytes32[](paletteCount);
    for (uint256 i = 0; i < paletteCount; i++) {
      seed = _nextSeed(seed, timestamp, operator, blockHash);
      seeds[i] = seed;
    }
    _lastSeed = seed;

    _totalSupply.increment();
    uint256 tokenId = _totalSupply.current();

    _tokenSeeds[tokenId] = seeds;
    _safeMint(operator, tokenId);
    _setRoyalties(tokenId, payable(owner()), ROYALTY);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string[5] memory palette = _getPalette(tokenId);

    string[8] memory parts;
    string[5] memory attributeParts;

    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" width="800" height="800" viewBox="0 0 10 10"><g transform="rotate(-90 5 5)">';

    for (uint256 i = 0; i < palette.length; i++) {
      parts[i + 1] = string(
        abi.encodePacked(
          '<rect x="0" y="',
          (i * 2).toString(),
          '" width="10" height="2" fill="',
          palette[i],
          '" />'
        )
      );

      attributeParts[i] = string(
        abi.encodePacked(
          '{"trait_type": "Color',
          (i + 1).toString(),
          '", "value": "',
          palette[i],
          '"}',
          i + 1 == palette.length ? '' : ', '
        )
      );
    }

    parts[7] = '</g></svg>';

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
    );
    output = string(abi.encodePacked(output, parts[5], parts[6], parts[7]));

    string memory attributes = string(
      abi.encodePacked(
        attributeParts[0],
        attributeParts[1],
        attributeParts[2],
        attributeParts[3],
        attributeParts[4]
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Palette #',
            tokenId.toString(),
            '", "description": "PaletteOnChain is randomly generated color palette and stored on chain. This palette can be used as a color base by others to create new collectable art.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '", "attributes": [',
            attributes,
            '], "license": { "type": "CC0", "url": "https://creativecommons.org/publicdomain/zero/1.0/" }}'
          )
        )
      )
    );
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  function getRandomColorCode(uint256 seed) external view override returns (string memory) {
    return _getColorCode(uint256(seed));
  }

  function getColorCodeFromHSV(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) external pure override returns (string memory) {
    return _getColorCode(hue, saturation, brightness);
  }

  function getPalette(uint256 tokenId) external view override returns (string[5] memory) {
    return _getPalette(tokenId);
  }

  function _getPalette(uint256 tokenId) private view returns (string[5] memory) {
    require(_exists(tokenId), 'getPalette query for nonexistent token');

    bytes32[] memory seeds = _tokenSeeds[tokenId];

    string[5] memory palette;

    for (uint256 i = 0; i < seeds.length; i++) {
      palette[i] = _getColorCode(uint256(seeds[i]));
    }

    return palette;
  }

  function _nextSeed(
    bytes32 currentSeed,
    uint256 timestamp,
    address operator,
    bytes32 blockHash
  ) private view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          currentSeed,
          timestamp,
          operator,
          blockHash,
          block.coinbase,
          block.difficulty,
          tx.gasprice
        )
      );
  }

  /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
  /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
  /// @inheritdoc	ERC721
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    // allows gas less trading on OpenSea
    if (isOwnersOpenSeaProxy(owner, operator)) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function _setRoyalties(
    uint256 _tokenId,
    address payable _royaltiesReceipientAddress,
    uint96 _percentageBasisPoints
  ) private {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesReceipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}
