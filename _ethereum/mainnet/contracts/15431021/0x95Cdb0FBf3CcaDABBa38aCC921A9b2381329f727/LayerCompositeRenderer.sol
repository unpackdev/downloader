// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IRenderer.sol";
import "./BytesUtils.sol";
import "./SvgUtils.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract LayerCompositeRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

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
    return "ipfs://bafkreigjwztwrolwcbkbz3ombzkvxg2767bckeobrfwdjfohvxgozbepv4";
  }
  
  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }
  
  function name() public override pure returns (string memory) {
    return 'Layer Composite';
  }

  function encodeProps(address[] memory renderers, bytes[] memory rendererProps) public pure returns (bytes memory output) {
    for (uint i = 0; i < renderers.length; ++i) {
      output = abi.encodePacked(output, renderers[i], rendererProps[i].length, rendererProps[i]);
    }
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    bytes memory backgroundImages;

    for (uint i = 0; i < props.length; i += 0) {
      IRenderer destinationRenderer = IRenderer(BytesUtils.toAddress(props, i));
      uint start = i + 20 + 32;
      uint end = start + BytesUtils.toUint256(props, i + 20); 
      backgroundImages = abi.encodePacked(backgroundImages, i == 0  ? '' : ',', 'url(', 
      destinationRenderer.render(props[start:end])
      ,')');
      i = end;
    }

    return abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200" style="',
      'background-image:', backgroundImages, ';background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;">',
      '</svg>'
    );
  }

  function render(bytes calldata props) external override view returns (string memory) {
        return string(
      abi.encodePacked(
        'data:image/svg+xml;base64,',
        Base64.encode(renderRaw(props)) 
      )
    );
  }

  function attributes(bytes calldata) external override pure returns (string memory) {
    return ""; 
  }
}