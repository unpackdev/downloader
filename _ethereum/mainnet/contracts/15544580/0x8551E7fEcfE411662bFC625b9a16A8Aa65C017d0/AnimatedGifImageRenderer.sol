// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IRenderer.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC165.sol";
import "./Ownable.sol";

contract AnimatedGifImageRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;
  
  bytes public constant GIF_89_A = hex"474946383961";
  bytes public constant APPLICATION_EXTENSION = hex"21FF0B4E45545343415045322E300301FFFF00";
  bytes public constant GRAPHIC_CONTROL_EXTENSION = hex"21F904090A000000";
  bytes public constant IMAGE_DESCRIPTOR = hex"2C00000000800080000007";

  uint public IMAGE_DATA_CHUNK_SIZE = 126;

  uint public WIDTH_INDEX = 0;
  uint public HEIGHT_INDEX = 1;
  uint public NUM_COLORS_INDEX = 2;

  function owner() public override(Ownable, IRenderer) view returns (address) {
    return super.owner();
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
    return "ipfs://bafkreicoe7rlsewtos62vt765vrdrlkm4q5lx7p3j53mf5kf3xy3cez2dy";
  }

  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }

  function name() public override pure returns (string memory) {
    return 'Multi Frame gif';
  }

  function getBestColorTableSize(uint8 numColors) internal pure returns (uint) {
    if (numColors > 64) {
      return 128;
    }
    if (numColors > 32) {
      return 64;
    }
    if (numColors > 16) {
      return 32;
    }
    if (numColors > 8) {
      return 16;
    }
    if (numColors > 4) {
      return 8;
    }
    if (numColors > 2) {
      return 4;
    }
    return 2;
  }

  function getLogicalScreenDescriptor(uint8 numColors) internal pure returns (bytes1) {
    require(numColors < 128, "Only a maximum of 127 colors allowed");
    if (numColors > 64) {
      return hex"F6";
    }
    if (numColors > 32) {
      return hex"F5";
    }
    if (numColors > 16) {
      return hex"F4";
    }
    if (numColors > 8) {
      return hex"F3";
    }
    if (numColors > 4) {
      return hex"F2";
    }
    if (numColors > 2) {
      return hex"F1";
    }
    return hex"F0";
  }

  function getGifHeader(bytes calldata props) internal view returns (bytes memory) {
    return abi.encodePacked(GIF_89_A, props[WIDTH_INDEX], hex"00", props[HEIGHT_INDEX], hex"00", getLogicalScreenDescriptor(uint8(props[NUM_COLORS_INDEX]) + 1), hex"0000");
  } 

  function getColorTable(bytes calldata props) internal view returns (bytes memory) {
    uint8 numColors = uint8(props[NUM_COLORS_INDEX]);
    bytes memory paddedZeros = new bytes((getBestColorTableSize(numColors + 1) - numColors) * 3);
    return abi.encodePacked(props[3:3 + (numColors * 3)], paddedZeros);
  }

  function getImageDescriptor(bytes calldata props) internal view returns (bytes memory) {
    return abi.encodePacked(
      hex"2C00000000", props[WIDTH_INDEX], hex"00", props[HEIGHT_INDEX], hex"000007"
    );
  }

  function getImageData(bytes memory imageDescriptor, bytes calldata props) public view returns (bytes memory) {
    bytes memory imageData = "";
    for (uint i = 0; i < props.length; i+=IMAGE_DATA_CHUNK_SIZE) {
      uint end = i + IMAGE_DATA_CHUNK_SIZE;
      bool isLastChunk = end > props.length;
      bytes memory chunk = props[i:(isLastChunk ? props.length : end)];
      imageData = abi.encodePacked(imageData, uint8(chunk.length + (isLastChunk ? 2 : 1)), hex"80", chunk);
    }
    return abi.encodePacked(
      GRAPHIC_CONTROL_EXTENSION,
      imageDescriptor,
      imageData,
      hex"8100"
    );
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    uint frameImageDataSize = uint(uint8(props[WIDTH_INDEX])) * uint(uint8(props[HEIGHT_INDEX]));
    bytes memory imageDescriptor = getImageDescriptor(props);
    bytes memory imageData = "";
    uint currentFameImageDataSize = 0;
    for (uint i = (3 + uint8(props[NUM_COLORS_INDEX]) * 3); i < props.length; i+=frameImageDataSize) {
      uint end = i + frameImageDataSize;
      bool isLastChunk = end > props.length;
      bytes memory chunk = props[i:(isLastChunk ? props.length : end)];
      currentFameImageDataSize += chunk.length;
      imageData = abi.encodePacked(imageData, getImageData(imageDescriptor, props[i: end]));
    }
    return abi.encodePacked(getGifHeader(props), getColorTable(props), APPLICATION_EXTENSION, imageData, hex"3B"); 
  }

  function render(bytes calldata props) external override view returns (string memory) {
    return string(
      abi.encodePacked(
        'data:image/gif;base64,',
        Base64.encode(renderRaw(props))
      )
    );
  }

  function attributes(bytes calldata props) external override pure returns (string memory) {
    uint i = 0;
    while(props[i] != 0x00) {
      i++;
    }
      return string(
            abi.encodePacked(
              '{"trait_type": "Data Length", "value":', i.toString(), '}'
            )
          );
  }
}