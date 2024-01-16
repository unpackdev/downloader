// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./SSTORE2Map.sol";
import "./BytesUtils.sol";
import "./IRenderer.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Ownable.sol";

contract CompressedAnimatedGifRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  IRenderer animatedGifImageRenderer;

  uint public maxConfigurationIndex = 1;

  uint public constant MAX_NUM_CONFIGURATIONS = 0xFFFFFFFF;

  uint public constant WIDTH_INDEX = 0;
  uint public constant HEIGHT_INDEX = 1;
  uint public constant COLOR_CONFIGURATION_INDEX = 2;
  uint public constant COMPRESSED_DATA_MIN_INDEX = 128;
  uint public constant IMAGE_DATA_START_INDEX = 6;

  event AddedConfiguration(
    uint index
  );

  constructor(address _animatedGifImageRenderer) {
    animatedGifImageRenderer = IRenderer(_animatedGifImageRenderer);
  }

  function owner() public override(Ownable, IRenderer) view returns (address) {
    return super.owner();
  }


  function name() public override pure returns (string memory) {
    return 'Compressed Gif';
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IRenderer).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function propsSize() external override pure returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }
  
  function additionalMetadataURI() external override pure returns (string memory) {
    return "ipfs://bafkreihcz67yvvlotbn4x3p35wdbpde27rldihlzoqg2klbme7u6lehxna";
  }
  
  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }

  function batchAddColorTables(bytes[] memory colorTables) public returns (uint) {
    for (uint i = 0; i < colorTables.length; ++i) {
      require (colorTables[i].length % 3 == 0, "colors must come in r,g,b tuples");
      SSTORE2Map.write(bytes32(maxConfigurationIndex), abi.encodePacked(uint8(colorTables[i].length / 3), colorTables[i]));
      emit AddedConfiguration(maxConfigurationIndex);
      maxConfigurationIndex++;
      require(maxConfigurationIndex <= MAX_NUM_CONFIGURATIONS, "Max number of configurations allowed.");
    }
    return maxConfigurationIndex;
  }

  function getColorTable(uint index) public view returns (bytes memory) {
    return SSTORE2Map.read(bytes32(index));
  }

  function convertProps(bytes calldata props) public pure returns (bytes memory output) {
    uint frameDataSize = uint(BytesUtils.toUint8(props, WIDTH_INDEX)) * uint(BytesUtils.toUint8(props, HEIGHT_INDEX));

    bytes memory frame = new bytes(frameDataSize);
    uint frameIndex = BytesUtils.toUint16(props, IMAGE_DATA_START_INDEX);
    bytes1 lastVal = 0; 
    for(uint i = IMAGE_DATA_START_INDEX + 2; i < props.length; ++i) {
      bytes1 val = props[i];
      uint intVal = uint8(val);
      if (intVal < COMPRESSED_DATA_MIN_INDEX) {
        // stores val into frame at index
        frame[frameIndex] = val;
        lastVal = val;
        frameIndex++;
      } else if (intVal == COMPRESSED_DATA_MIN_INDEX) {
        // denotes a new frame
        output = abi.encodePacked(output, frame);
        frame = new bytes(frameDataSize);
        i++;
        frameIndex = BytesUtils.toUint16(props, i);
        i++;
      } else {
        // denotes duping the last known val x times
        uint qt = intVal - COMPRESSED_DATA_MIN_INDEX;
        for (uint ct = 0; ct < qt; ct++) {
          frame[frameIndex + ct] = lastVal;
        }
        frameIndex += qt;
      }     
    }
    output = abi.encodePacked(output, frame);
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    return animatedGifImageRenderer.renderRaw
    (abi.encodePacked(
      props[WIDTH_INDEX],
      props[HEIGHT_INDEX],
      SSTORE2Map.read(bytes32(uint(BytesUtils.toUint32(props, COLOR_CONFIGURATION_INDEX)))), convertProps(props)));
  }

  function render(bytes calldata props) external override view returns (string memory) {
       return animatedGifImageRenderer.render
    (abi.encodePacked(
      props[WIDTH_INDEX],
      props[HEIGHT_INDEX],
      SSTORE2Map.read(bytes32(uint(BytesUtils.toUint32(props, COLOR_CONFIGURATION_INDEX)))), convertProps(props)));
  }

  function attributes(bytes calldata props) external override pure returns (string memory) {
    return string(
            abi.encodePacked(
              '{"trait_type": "Data Length", "value":', props.length.toString(), '}'
            )
          );
  }
}