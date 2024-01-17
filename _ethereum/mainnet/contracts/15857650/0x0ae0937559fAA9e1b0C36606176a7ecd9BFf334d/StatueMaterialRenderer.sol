// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IRenderer.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./BytesUtils.sol";
import "./RarityCompositingEngine.sol";
import "./TransmutationRitual.sol";

contract StatueMaterialRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;
  IRenderer public defaultLiveServiceVisualRenderer;
  IRenderer public compactMiddlewareRenderer;
  RarityCompositingEngine public rce;
  TransmutationRitual public ritual;

  bytes public propsPrefix;

  constructor(
    bytes memory _propsPrefix,
    address _compactMiddlewareRenderer,
    address _defaultLiveServiceVisualRenderer,
    address _ritual,
    address _rce
  ) {
    defaultLiveServiceVisualRenderer = IRenderer(
      _defaultLiveServiceVisualRenderer
    );
    compactMiddlewareRenderer = IRenderer(_compactMiddlewareRenderer);
    propsPrefix = _propsPrefix;
    rce = RarityCompositingEngine(_rce);
    ritual = TransmutationRitual(_ritual);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'StatueMaterialRenderer';
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IRenderer).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function propsSize() external pure override returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }

  function additionalMetadataURI()
    external
    pure
    override
    returns (string memory)
  {
    return 'ipfs://bafkreihcz67yvvlotbn4x3p35wdbpde27rldihlzoqg2klbme7u6lehxna';
  }

  function renderAttributeKey() external pure override returns (string memory) {
    return 'image';
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    uint256 tokenId = BytesUtils.toUint256(props, 32);
    uint256 attributeIndex = BytesUtils.toUint256(props, 64);
    RarityCompositingEngine.AttributeData memory ad = rce.decodeAttributeData(
      rce.attributeStorage().indexToData(attributeIndex)
    );

    bytes32 spell = ritual.getSpell(tokenId);
    bytes5 materialSeed = ritual.getComputedSeed(tokenId, spell);

    // empty seed
    if (uint256(spell) == 0) {
      return defaultLiveServiceVisualRenderer.renderRaw(props);
    }

    return
      compactMiddlewareRenderer.renderRaw(
        abi.encodePacked(
          propsPrefix,
          BytesUtils.slice(ad.prefix, 0, 2), // skip value
          materialSeed, // material seed
          BytesUtils.slice(ad.prefix, 2, 4), // config index
          rce.rendererPropsStorage().indexToRendererProps(ad.rendererDataIndex)
        )
      );
  }

  function render(bytes calldata props)
    external
    view
    override
    returns (string memory)
  {
    uint256 tokenId = BytesUtils.toUint256(props, 32);
    uint256 attributeIndex = BytesUtils.toUint256(props, 64);
    RarityCompositingEngine.AttributeData memory ad = rce.decodeAttributeData(
      rce.attributeStorage().indexToData(attributeIndex)
    );

    bytes32 spell = ritual.getSpell(tokenId);
    bytes5 materialSeed = ritual.getComputedSeed(tokenId, spell);

    // empty seed
    if (uint256(spell) == 0) {
      return defaultLiveServiceVisualRenderer.render(props);
    }

    return
      compactMiddlewareRenderer.render(
        abi.encodePacked(
          propsPrefix,
          BytesUtils.slice(ad.prefix, 0, 2), // skip value
          materialSeed, // material seed
          BytesUtils.slice(ad.prefix, 2, 4), // config index
          rce.rendererPropsStorage().indexToRendererProps(ad.rendererDataIndex)
        )
      );
  }

  function attributes(bytes calldata props)
    external
    pure
    override
    returns (string memory)
  {
    return '';
  }
}
