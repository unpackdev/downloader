// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./two_bit.sol";
import "./i_two_bit_renderer.sol";
import "./i_two_bit_upgrade_merkle.sol";

pragma solidity 0.8.10;
pragma abicoder v2;

// Website: https://twobitclicks.com
// Twitter: @twobitclicks
// Discord: https://discord.gg/WfTdKShQbw
contract TwoBitClick is ERC721Enumerable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  ITwoBitRenderer private renderer;
  ITwoBitUpgradeMerkle private upgrader;
  bool public saleIsActive = false;
  uint256 public constant tokenPrice = 0.03 ether;
  uint256 public constant upgradePrice = 0.0049 ether;
  uint256 public constant MAX_TOKENS = 10001;
  mapping(uint256 => TwoBit) tokenTraits;
  mapping(uint256 => uint256) public existingCombinations;
  uint8[][10] public rarities;
  uint8[][10] public aliases;
  address public proxyRegistryAddress;
  mapping(address => bool) public projectProxy;

  event TwoBitUpgraded(uint256 tokenId);
  event Rebirth(uint256 tokenId);

  constructor(address rendererAddress, address upgraderAddress, address _addressProxy) ERC721("TwoBitClick", "TWOBIT") { 
    proxyRegistryAddress = _addressProxy;
    renderer = ITwoBitRenderer(rendererAddress);
    upgrader = ITwoBitUpgradeMerkle(upgraderAddress);
    rarities[0] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,65,55];
    aliases[0] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    rarities[1] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,65,55];
    aliases[1] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    rarities[2] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,35];
    aliases[2] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
    rarities[3] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,35];
    aliases[3] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
    rarities[4] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,35];
    aliases[4] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
    rarities[5] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,35];
    aliases[5] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ,12, 13, 14, 15, 16, 17, 18, 19];
    rarities[6] = [255,245,235,225,215,205,195,185,175,165,155,145,135,125,115,105,95,85,75,35,15];
    aliases[6] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    rarities[7] = [255,235,215,195,175,155,135,115,95,90,85,80,75,70,65,60,55];
    aliases[7] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    rarities[8] = [255,215,175,135,125,115,95,85,55,35];
    aliases[8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    rarities[9] = [255,222,199,187,134,118,95,85,55,35,5];
    aliases[9] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  }

  function withdraw() public onlyOwner {
    (bool success,) = msg.sender.call{value : address(this).balance}('');
    require(success, "Failed");
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function flipProxyState(address proxyAddress) public onlyOwner {
    projectProxy[proxyAddress] = !projectProxy[proxyAddress];
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function mintToken() public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalSupply() < MAX_TOKENS, "Purchase exceeds supply");
    require(msg.value == tokenPrice, "Ether value sent not correct");

    mint();
  }

  function mint() internal {
    uint256 tokenId = totalSupply().add(1);
    uint256 seed = random(tokenId);
    generate(3, 0, 0, tokenId, seed, 0);
    _safeMint(msg.sender, tokenId);
  }

  function handleRebirth(uint256 tokenId) public nonReentrant {
    require(msg.sender == ownerOf(tokenId), "You do not own this bit");
    require(2 + tokenTraits[tokenId].bitOneLevel + tokenTraits[tokenId].bitTwoLevel == 20, "Not level 20");

    generate(3, 0, 0, tokenId, random(tokenId), tokenTraits[tokenId].rebirth + 1);
    emit Rebirth(tokenId);
  }

  function upgradeToken(uint256 tokenId, uint8 upgradeType, bytes32[] calldata proof) public payable nonReentrant {
    TwoBit memory bits = tokenTraits[tokenId];
    uint8 currentLevel = bits.bitOneLevel + bits.bitTwoLevel;
    require(msg.sender == ownerOf(tokenId), "You do not own this bit");
    require(msg.value == upgradePrice, "Ether value sent not correct");
    require(upgrader.checkUpgradeStatus(currentLevel, upgradeType, tokenId, proof), "Upgrade not ready");
    uint256 oldStruct = structToHash(bits);

    if (upgradeType == 1) {
      bits.bitOneLevel += 1;
    } else if (upgradeType == 2) {
      bits.bitTwoLevel += 1;
    } else {
      bits.bitOneLevel += 1;
      bits.bitTwoLevel += 1;
    }

    generate(upgradeType, bits.bitOneLevel, bits.bitTwoLevel, tokenId, random(tokenId), bits.rebirth);
    existingCombinations[oldStruct] = 0;
    emit TwoBitUpgraded(tokenId);
  }

  function generate(uint8 upgradeType, uint8 bitOneLevel, uint8 bitTwoLevel, uint256 tokenId, uint256 seed, uint8 rebirth) internal returns (TwoBit memory g) {
    g = selectTraits(upgradeType, bitOneLevel, bitTwoLevel, seed);
    if (existingCombinations[structToHash(g)] == 0) {
      g.rebirth = rebirth;
      tokenTraits[tokenId] = g;
      existingCombinations[structToHash(g)] = tokenId;
      return g;
    }
    return generate(upgradeType, bitOneLevel, bitTwoLevel, tokenId, random(seed), rebirth);
  }

  function selectTrait(uint16 seed, uint8 level) internal view returns (uint8) {
    uint8 trait = uint8(seed) % uint8(rarities[level].length);
    if (seed >> 5 < rarities[level][trait]) return trait;
    return aliases[level][trait];
  }

  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }
 
  function selectTraits(uint8 upgradeType, uint8 bitOneLevel, uint8 bitTwoLevel, uint256 seed) internal view returns (TwoBit memory t) {    
    t.bitOneLevel = bitOneLevel;
    t.bitTwoLevel = bitTwoLevel;
    seed >>= 16;
    t.degrees = (uint16(seed & 0xFFFF) % 5) * 90;
    seed >>= 16;
    t.backgroundRandomLevel = uint8(uint16(seed & 0xFFFF) % 10);
    seed >>= 16;
    t.background = selectTrait(uint16(seed & 0xFFFF), t.backgroundRandomLevel);
    seed >>= 16;
    int16 direction = int16(((uint16(seed & 0xFFFF) % 3) - 1) * 100);
    int16 factor = 260;
    t.bitOneXCoordinate = uint16(factor + direction);
    t.bitTwoXCoordinate = uint16(factor - direction);
    if (upgradeType == 1) {
      seed >>= 16;
      t.bitOneRGB = selectTrait(uint16(seed & 0xFFFF), bitOneLevel);
    } else if (upgradeType == 2) {
      seed >>= 16;
      t.bitTwoRGB = selectTrait(uint16(seed & 0xFFFF), bitTwoLevel);
    } else {
      seed >>= 16;
      t.bitOneRGB = selectTrait(uint16(seed & 0xFFFF), bitOneLevel);
      seed >>= 16;
      t.bitTwoRGB = selectTrait(uint16(seed & 0xFFFF), bitTwoLevel);
    }

    return t;
  }

  function structToHash(TwoBit memory tb) internal pure returns (uint256) {
    return uint256(bytes32(
      abi.encodePacked(
        tb.bitOneRGB,
        tb.bitTwoRGB,
        tb.bitOneLevel,
        tb.bitTwoLevel,
        tb.degrees,
        tb.bitOneXCoordinate,
        tb.bitTwoXCoordinate
      )
    ));
  }

  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function getTokenTraits(uint256 tokenId) external view returns (TwoBit memory) {
    require(_exists(tokenId), "DNE");
    return tokenTraits[tokenId];
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "DNE");
    return renderer.tokenURI(_tokenId, tokenTraits[_tokenId]);
  }

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
    return super.isApprovedForAll(_owner, operator);
  }
}
contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}