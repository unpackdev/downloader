// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./StringList.sol";
import "./FormatMetadata.sol";
import "./IPlotMetadata.sol";
import "./IPlot.sol";

contract PlotMetadata is IPlotMetadata, OwnableUpgradeable {
  using Base64 for bytes;
  using ECDSA for bytes32;
  using SafeMath for uint256;
  using StringList for string[];
  using Strings for uint256;

  string internal constant HEADER =
    '<svg id=\\"plot\\" width=\\"100%\\" height=\\"100%\\" version=\\"1.1\\" viewBox=\\"0 0 64 64\\" xmlns=\\"http://www.w3.org/2000/svg\\" xmlns:xlink=\\"http://www.w3.org/1999/xlink\\">';
  string internal constant FOOTER =
    "<style>#plot{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

  string internal constant PNG_HEADER =
    '<image x=\\"1\\" y=\\"1\\" width=\\"64\\" height=\\"64\\" image-rendering=\\"pixelated\\" preserveAspectRatio=\\"xMidYMid\\" xlink:href=\\"';
  string internal constant PNG_FOOTER = '\\"/>';

  string internal constant STAKED_LAYER =
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABTklEQVR42u3XMWuDUBSG4a/JKBIuQoghZBBHQbrlL/SfdxUsXYJDKXEoIiW4dLFDuBfbdDFJIVfeZzIOwnfO9RwjAQAAAAAAAAAAAAAAAAAAAACm5+EWD9ku1K/D8/vP77d5/n+a3Sp8nmSSpNTE7nq3UT/5Agw7b4N3baM8yXQ43v8rcFUBdhv1eZIpNbGKqlTXNgpMJEkqqtKLGTC7JnxqYklSYKIf3bdFmGwBbPjAROraRl3buELs29qrLTC7JLy9LqpSgYkUmMgd+TzJXEF8MB878Y9f0uPq1P2VWaqoSq3MUqHmeq0rhZq7U/DyMaE1uF2cOv+UZ9q3teuyHYCBiZSa2IX3YQOM+hDabdQfjqcC2GFn33v7exj+7fP+uz96BqxDnQ08OwR9DD/6U/j36hvue3vkfQp/UQH+uu9r+Iv+DNlZMORjcACQpG+Cj4F77K7KfwAAAABJRU5ErkJggg==";

  string internal constant PLACEHOLDER_LAYER =
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUdOwwqPBwiRQ8sP2k0WShCU3pRWDg+YipRZoe7sow31aPoAAAEs0lEQVRIx1WVTW/bRhCGR1umTm8clpXa23LAQOitgCKkuUnMANucHabOUUDhc8QusOm5NSBfjSTy/tu+s7TRmgZMQHx2Pt+ZJc75ZvPfM16dbs8pJMWfPUzLJ8A4nm6zc1FVB1kbQRnA5eP3rX3PnagBvjpyqp4CcJDzZ3FBJEzijtw+tTAbODNz7cPkqTs0vQGnR2A8wUBOSwAUEvmOF9X/AcvAALMgIXnyRBVdX+fT+OjADJwTt+waZLpbOOqJl/n+76dAikI+pDjRRdrTcvngYjt7OKeYYkcSU5gQCBNzvikurkqOGbXR4GWtIQ5SKVNdfZqBOYdzAYbmAoYmmoH7m3H8rwjWgvjR9+jFRL0Gqn88wfbmcrO9MSCpyBxeEr9GwQkncfTrF7z/sRDUuRT3qLEBUYXm7NInexcAKVZ7XmnyXqT3ABD8WV5YmgghKFEDoFXxbgY2+P3OPTMt3CKJyzT5XiMMUJhqlwC8HmToXhSxAKhlkj4gFSGd4AS9uB6cd99YnmaB3OWraIAniIqITDt4vXkEPP350mrBrCYJA6KSc2+slDmr7pClAUtWlARAUk1Q2AMQ1axDasoco3jpyPQdUI4CnMt3AKsEVaIksBFDDLl0a/yQ1SwIpAag0eCgXkohfpcvS7Py16ABBXAdX1gSYVch2RA+5nsDxvfXe0GJJkfNRcRRh16lDsBb6B7NfMfsqU/RUltbs/2FRitXkN+KAQBSryNbaquOUeeLSUIp1w8Atu//AEDrSWpaHFo+hEhVJ1ND6hbPNtvNqMhcYU5Mpi1zhRI7h1r2b4fSBxNzQmwNuwWv9ox0VPqdALActr/HVADvh67iFtXG5ASkQX1Jckz4wYBJBlcxl4KC0olk/cU8RAxKjAaIVBYBr0Q6xoyJ+/IQwoC9EVAmUa4BsDTfMqrCDpO5fWcK8SHECUeqSaqwZPELTgPV1sjtu4CWNqFY8DRgYpgnAoDBKY30DvIwdeF5VJl0GC+l783A+5qq+aupyCFDdEQ85KBUpARew0XZbWgFWHiCc0BaIrjyVCUbq5CmjrBc0EryvofkggHjLcYNqwoDtrYgDcAkeOecNwBqvyP3/IThlvohkoThk6ayUsNBPiOk5ycMuSfXqw2CHg8r02YyALMt9c/3tibuvLi5ZEcrNc/ALQABcAMTd52cbTOQHcbwQHII4ZwcrTMILII7yWbBYYSDSQjAVZ5wovoLaZzmPYcodjR0C651BrAqFgZkCwPJRgsTnVi2VvfNKUvjZcE/AbiZd0Q08UANrV0oiBEeoMO2mBivEPPUm54wwrh06Nfbsy2jbtnCyf3JlmlRBmxgUWIFoUwlSFNRnh+0EpqGgcEVAA2qvCOr8lv7/tmAmI6HdvDo5gjAVR7dC3pk2+Ca4s71uFUapJfow2dcD73FaYVZxQFr2v7ZteME3QSAmYA+Wxu+Frdhb1ci+gCrkCm9Ljes7g8AbMEOBNV510D2pt9AL+cr2PbWniEx3Wy8X5jubA+Q0KuYHvfWnptaoVHBWQqDKQrSewBsNveH2huAT7CN2nRuwthoOT67aOeNqjvfVfCyq3ZEWwMOqyNahy7iXrdB+sW+znP0L5PyHxY2/GBxAAAAAElFTkSuQmCC";

  address public plotAddress;
  address public oracleAddress;

  string internal _baseImageURI;
  string internal _description;
  string internal _stakedDescription;

  mapping(uint256 => string) internal _imageURIs;

  function initialize(address _oracleAddress, address _plotAddress)
    public
    initializer
  {
    __Ownable_init();
    oracleAddress = _oracleAddress;
    plotAddress = _plotAddress;

    _description = "A collection of 62,500 genesis Plots of land. Get a Plot to access the Critterz metaverse in Minecraft. Each Plot of land is 64 by 64 Minecraft blocks in size. Only owners of the Plots can build or destroy any blocks on it. You will have to stake Plots before building on them. Plots can also be minted using $BLOCK tokens.";
    _stakedDescription = "You should ONLY get Staked Plots from here if you want to rent a Plot. These are NOT the same as Critterz Plot NFTs. Rented Plots also give access to the Critterz Minecraft world, but you cannot break or place any blocks for Plots you rented in and are time limited.";
  }

  /*
  READ FUNCTIONS
  */

  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view override returns (string memory) {
    string[] memory attributes = _getAttributes(tokenId);
    return
      _formatMetadata(tokenId, attributes.concat(additionalAttributes), staked);
  }

  function _formatMetadata(
    uint256 tokenId,
    string[] memory attributes,
    bool staked
  ) internal view returns (string memory) {
    if (bytes(_baseImageURI).length > 0) {
      return
        FormatMetadata.formatMetadata(
          _getName(tokenId, staked),
          staked ? _stakedDescription : _description,
          imageURI(tokenId),
          attributes,
          ""
        );
    } else {
      return
        FormatMetadata.formatMetadataWithSVG(
          _getName(tokenId, staked),
          staked ? _stakedDescription : _description,
          _getSvg(tokenId, staked),
          attributes,
          ""
        );
    }
  }

  function _getName(uint256 tokenId, bool staked)
    internal
    view
    returns (string memory)
  {
    (int256 x, int256 y) = IPlot(plotAddress).getPlotCoordinate(tokenId);
    return
      string(
        abi.encodePacked(staked ? "s" : "", "Plot ", _formatCoordinate(x, y))
      );
  }

  function _getSvg(uint256 tokenId, bool staked)
    internal
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          HEADER,
          _formatLayer(imageURI(tokenId)),
          staked ? _formatLayer(STAKED_LAYER) : "",
          FOOTER
        )
      );
  }

  function _getAttributes(uint256 tokenId)
    internal
    view
    returns (string[] memory)
  {
    (int256 x, int256 y) = IPlot(plotAddress).getPlotCoordinate(tokenId);
    string[] memory attributes = new string[](2);
    attributes[0] = FormatMetadata.formatTraitNumber("x", x, "number");
    attributes[1] = FormatMetadata.formatTraitNumber("y", y, "number");
    return attributes;
  }

  function _formatLayer(string memory layer)
    internal
    pure
    returns (string memory)
  {
    if (bytes(layer).length == 0) {
      return "";
    }
    return string(abi.encodePacked(PNG_HEADER, layer, PNG_FOOTER));
  }

  function _formatCoordinate(int256 x, int256 y)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "(",
          FormatMetadata.intToString(x),
          ",",
          FormatMetadata.intToString(y),
          ")"
        )
      );
  }

  function imageURI(uint256 tokenId) public view returns (string memory) {
    string memory uri = _imageURIs[tokenId];
    if (bytes(uri).length > 0) {
      return uri;
    }

    string memory baseImageURI = _baseImageURI;
    return
      bytes(baseImageURI).length > 0
        ? string(abi.encodePacked(baseImageURI, tokenId.toString()))
        : PLACEHOLDER_LAYER;
  }

  function _verify(bytes32 messageHash, bytes memory signature)
    internal
    view
    returns (bool)
  {
    return
      messageHash.toEthSignedMessageHash().recover(signature) == oracleAddress;
  }

  function _getMessageHash(
    uint256 tokenId,
    string memory uri,
    uint256 exp
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenId, uri, exp));
  }

  /*
  WRITE FUNCTIONS
  */

  function setImageURI(
    uint256 tokenId,
    string calldata uri,
    uint256 exp,
    bytes calldata signature
  ) external {
    require(exp > block.number, "Signature expired");
    require(
      _verify(_getMessageHash(tokenId, uri, exp), signature),
      "Invalid signature"
    );
    _imageURIs[tokenId] = uri;
  }

  /*
  OWNER FUNCTIONS
  */

  function setBaseImageURI(string calldata baseImageURI) external onlyOwner {
    _baseImageURI = baseImageURI;
  }

  function setDescription(string calldata description) external onlyOwner {
    _description = description;
  }

  function setStakedDescription(string calldata stakedDescription)
    external
    onlyOwner
  {
    _stakedDescription = stakedDescription;
  }

  function setOracleAddress(address _oracleAddress) external onlyOwner {
    oracleAddress = _oracleAddress;
  }

  function setPlotAddress(address _plotAddress) external onlyOwner {
    plotAddress = _plotAddress;
  }
}
