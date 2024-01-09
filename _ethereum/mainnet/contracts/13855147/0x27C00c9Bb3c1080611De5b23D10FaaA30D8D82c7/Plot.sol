//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./SafeMath.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IBlock.sol";
import "./IPlotMetadata.sol";
import "./ERC721Stakable.sol";

contract Plot is ERC721Stakable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;

  address public blockAddress;
  address public metadataAddress;

  uint256 public constant MAX_DIMENSION = 250;

  uint256 public price;
  uint256 public dimension;

  uint256 public totalSupply;

  mapping(uint256 => bool) public spawns;

  function initialize(
    address _stakingAddress,
    address _blockAddress,
    address _metadataAddress
  ) public initializer {
    __ERC721Stakable_init("Plot", "PLOT");
    __ReentrancyGuard_init_unchained();

    price = 1000 * 10**18;
    dimension = 150;

    stakingAddress = _stakingAddress;
    blockAddress = _blockAddress;
    metadataAddress = _metadataAddress;

    // prettier-ignore
    uint16[232] memory spawnIds = [31375,31376,31374,31625,31125,31626,31124,31126,31624,31373,31123,31623,30875,30874,30876,30873,43875,43876,43874,44125,43625,44126,43624,43626,44124,43925,43926,43924,44175,43675,44176,43674,43676,44174,31425,31426,31424,31675,31175,31676,31174,31176,31674,18925,18926,18924,19175,18675,19176,18674,18676,19174,18875,18876,18874,19125,18625,19126,18624,18626,19124,18825,18826,18824,19075,18575,19076,18574,18576,19074,31325,31326,31324,31575,31075,31576,31074,31076,31574,43825,43826,43824,44075,43575,44076,43574,43576,44074,56375,56376,56374,56625,56125,56626,56124,56126,56624,56425,56426,56424,56675,56175,56676,56174,56176,56674,56475,56476,56474,56725,56225,56726,56224,56226,56724,43975,43976,43974,44225,43725,44226,43724,43726,44224,31475,31476,31474,31725,31225,31726,31224,31226,31724,18975,18976,18974,19225,18725,19226,18724,18726,19224,6475,6476,6474,6725,6225,6726,6224,6226,6724,6425,6426,6424,6675,6175,6676,6174,6176,6674,6375,6376,6374,6625,6125,6626,6124,6126,6624,6325,6326,6324,6575,6075,6576,6074,6076,6574,6275,6276,6274,6525,6025,6526,6024,6026,6524,18775,18776,18774,19025,18525,19026,18524,18526,19024,31275,31276,31274,31525,31025,31526,31024,31026,31524,43775,43776,43774,44025,43525,44026,43524,43526,44024,56275,56276,56274,56525,56025,56526,56024,56026,56524,56325,56326,56324,56575,56075,56576,56074,56076,56574];

    for (uint256 i = 0; i < 232; i++) {
      spawns[spawnIds[i]] = true;
    }
  }

  /*
  WRITE FUNCTIONS
  */

  function claimCoordinate(
    int256 x,
    int256 y,
    bool stake
  ) public nonReentrant {
    int256 halfDimensionAbs = int256(dimension) / 2;
    require(
      x >= -halfDimensionAbs &&
        x < halfDimensionAbs &&
        y >= -halfDimensionAbs &&
        y < halfDimensionAbs,
      "Coordinate out of bounds"
    );
    _claim(getPlotTokenId(x, y), stake);
  }

  function claim(uint256[] calldata tokenIds, bool stake)
    external
    nonReentrant
  {
    int256 halfDimensionAbs = int256(dimension) / 2;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      (int256 x, int256 y) = getPlotCoordinate(tokenId);
      require(
        x >= -halfDimensionAbs &&
          x < halfDimensionAbs &&
          y >= -halfDimensionAbs &&
          y < halfDimensionAbs,
        "Coordinate out of bounds"
      );
    }
    _claim(tokenIds, stake);
  }

  function _claim(uint256 tokenId, bool stake) internal {
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    _claim(tokenIds, stake);
  }

  function _claim(uint256[] memory tokenIds, bool stake) internal {
    uint256 _totalSupply = totalSupply;
    uint256 _price = price;
    uint256 _totalPrice = 0;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(!spawns[tokenId], "Cannot claim spawn");
      _totalPrice += _price;
      // increase price by 1.00004
      if (_totalSupply < 22500) {
        _price = (_price * 100004) / 100000;
      } else {
        // 1000 * 10 ^ 18 * ln(1.00004) * 1.00004 ^ 22500
        _price += 98380386000000000;
      }
      _safeMint(
        stake ? stakingAddress : msg.sender,
        tokenId,
        abi.encode(msg.sender)
      );
      _totalSupply += 1;
    }
    totalSupply = _totalSupply;
    price = _price;
    IBlock(blockAddress).burnFrom(msg.sender, _totalPrice);
  }

  /*
  READ FUNCTIONS
  */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return
      IPlotMetadata(metadataAddress).getMetadata(
        tokenId,
        false,
        new string[](0)
      );
  }

  function getPlotCoordinate(uint256 tokenId)
    public
    pure
    returns (int256, int256)
  {
    int256 halfDimension = int256(MAX_DIMENSION / 2);
    int256 x = int256(tokenId % MAX_DIMENSION) - halfDimension;
    int256 y = int256(tokenId / MAX_DIMENSION) - halfDimension;
    return (x, y);
  }

  function getPlotTokenId(int256 x, int256 y) public pure returns (uint256) {
    int256 halfDimension = int256(MAX_DIMENSION / 2);
    uint256 tokenId = uint256(y + halfDimension) *
      MAX_DIMENSION +
      uint256(x + halfDimension);
    return tokenId;
  }

  /*
  OWNER FUNCTIONS
  */

  function setBlockAddress(address _blockAddress) external onlyOwner {
    blockAddress = _blockAddress;
  }

  function setMetadataAddress(address _metadataAddress) external onlyOwner {
    metadataAddress = _metadataAddress;
  }

  function claimSpawn(uint256 tokenId) external onlyOwner {
    require(spawns[tokenId], "Not a spawn");
    _safeMint(msg.sender, tokenId);
  }

  function setDimension(uint256 _dimension) external onlyOwner {
    require(_dimension <= MAX_DIMENSION, "Dimension too large");
    dimension = _dimension;
  }
}
