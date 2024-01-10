// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// This is a modified version of LibSvg.sol of aavegotchi-contracts
// https://github.com/aavegotchi/aavegotchi-contracts/blob/80f4031b65ae8a16831879cd40b00796892860fe/contracts/Aavegotchi/libraries/LibSvg.sol
library LibSvg {
  event StoreSvg(SvgTypeAndSizes[] typesAndSizes);
  event UpdateSvg(SvgTypeAndIdsAndSizes[] typesAndIdsAndSizes);

  struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
  }

  struct SvgTypeAndSizes {
    bytes32 svgType;
    uint256[] sizes;
  }

  struct SvgTypeAndIdsAndSizes {
    bytes32 svgType;
    uint256[] ids;
    uint256[] sizes;
  }

  function _getSvg(SvgLayer[] storage svgLayers, uint256 id)
    internal
    view
    returns (bytes memory svg)
  {
    require(id < svgLayers.length, 'LibSvg: SVG type or id does not exist');

    SvgLayer storage svgLayer = svgLayers[id];
    address svgContract = svgLayer.svgLayersContract;
    uint256 size = svgLayer.size;
    uint256 offset = svgLayer.offset;
    svg = new bytes(size);
    assembly {
      extcodecopy(svgContract, add(svg, 32), offset, size)
    }
  }

  function _storeSvg(
    mapping(bytes32 => SvgLayer[]) storage svgLayers,
    string calldata svg,
    SvgTypeAndSizes[] calldata typesAndSizes
  ) internal {
    emit StoreSvg(typesAndSizes);
    address svgContract = _storeSvgInContract(svg);
    uint256 offset;
    for (uint256 i; i < typesAndSizes.length; i++) {
      SvgTypeAndSizes calldata svgTypeAndSizes = typesAndSizes[i];
      for (uint256 j; j < svgTypeAndSizes.sizes.length; j++) {
        uint256 size = svgTypeAndSizes.sizes[j];
        svgLayers[svgTypeAndSizes.svgType].push(
          SvgLayer(svgContract, uint16(offset), uint16(size))
        );
        offset += size;
      }
    }
  }

  function _updateSvg(
    mapping(bytes32 => SvgLayer[]) storage svgLayers,
    string calldata svg,
    SvgTypeAndIdsAndSizes[] calldata typesAndIdsAndSizes
  ) internal {
    emit UpdateSvg(typesAndIdsAndSizes);
    address svgContract = _storeSvgInContract(svg);
    uint256 offset;
    for (uint256 i; i < typesAndIdsAndSizes.length; i++) {
      SvgTypeAndIdsAndSizes calldata svgTypeAndIdsAndSizes = typesAndIdsAndSizes[i];
      for (uint256 j; j < svgTypeAndIdsAndSizes.sizes.length; j++) {
        uint256 size = svgTypeAndIdsAndSizes.sizes[j];
        uint256 id = svgTypeAndIdsAndSizes.ids[j];
        svgLayers[svgTypeAndIdsAndSizes.svgType][id] = SvgLayer(
          svgContract,
          uint16(offset),
          uint16(size)
        );
        offset += size;
      }
    }
  }

  function _storeSvgInContract(string calldata svg) internal returns (address svgContract) {
    require(bytes(svg).length < 24576, 'SvgStorage: Exceeded 24,576 bytes max contract size');
    // 610000 -- PUSH2 (size)
    // 6000 -- PUSH1 (code position)
    // 6000 -- PUSH1 (mem position)
    // 39 CODECOPY
    // 610000 PUSH2 (size)
    // 6000 PUSH1 (mem position)
    // f3 RETURN
    bytes memory init = hex'610000600e6000396100006000f3';
    bytes1 size1 = bytes1(uint8(bytes(svg).length));
    bytes1 size2 = bytes1(uint8(bytes(svg).length >> 8));
    init[2] = size1;
    init[1] = size2;
    init[10] = size1;
    init[9] = size2;
    bytes memory code = abi.encodePacked(init, svg);

    assembly {
      svgContract := create(0, add(code, 32), mload(code))
      if eq(svgContract, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
}
