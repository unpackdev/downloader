// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";

import "./ContractDataStorage.sol";
import "./SvgParser.sol";
import "./CyberBrokersMetadata.sol";

interface ICyberBrokersMetadata {
  struct CyberBrokerLayer {
    string key;
    string attributeName;
    string attributeValue;
  }

  struct CyberBrokerTalent {
    string talent;
    string species;
    string class;
    string description;
  }
}

contract CyberBrokersMetadataWrapper is ICyberBrokersMetadata {
  using Strings for uint256;

  // Storage contract, point back to all broker DNA, layers, and talents
  CyberBrokersMetadata public metadataStorageContract;

  constructor(
    address _metadataStorageContract
  ) {
    metadataStorageContract = CyberBrokersMetadata(_metadataStorageContract);
  }

  function layerMap(uint256 layerId) public view returns (CyberBrokerLayer memory) {
    (string memory key, string memory attributeName, string memory attributeValue) = metadataStorageContract.layerMap(layerId);
    return CyberBrokerLayer(key, attributeName, attributeValue);
  }

  function talentMap(uint256 talentId) public view returns (CyberBrokerTalent memory) {
    (string memory talent, string memory species, string memory class, string memory description) = metadataStorageContract.talentMap(talentId);
    return CyberBrokerTalent(talent, species, class, description);
  }

  function brokerDna(uint256 tokenId) public view returns (uint256) {
    return metadataStorageContract.brokerDna(tokenId);
  }

  // Bitwise constants
  uint256 constant private BROKER_MIND_DNA_POSITION = 0;
  uint256 constant private BROKER_BODY_DNA_POSITION = 5;
  uint256 constant private BROKER_SOUL_DNA_POSITION = 10;
  uint256 constant private BROKER_TALENT_DNA_POSITION = 15;
  uint256 constant private BROKER_LAYER_COUNT_DNA_POSITION = 21;
  uint256 constant private BROKER_LAYERS_DNA_POSITION = 26;

  uint256 constant private BROKER_LAYERS_DNA_SIZE = 12;

  uint256 constant private BROKER_MIND_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_BODY_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_SOUL_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_TALENT_DNA_BITMASK = uint256(0x3F);
  uint256 constant private BROKER_LAYER_COUNT_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_LAYER_DNA_BITMASK = uint256(0x0FFF);

  // Contracts
  function contractDataStorage() public view returns (ContractDataStorage) {
    return metadataStorageContract.contractDataStorage();
  }

  function svgParser() public view returns (SvgParser) {
    return metadataStorageContract.svgParser();
  }

  /**
   * On-Chain Metadata Construction
   **/

  // REQUIRED for token contract
  function hasOnchainMetadata(uint256 tokenId) public view returns (bool) {
    return metadataStorageContract.hasOnchainMetadata(tokenId);
  }

  // REQUIRED for token contract
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Unpack the name, talent and layers
    string memory name = metadataStorageContract.getBrokerName(tokenId);

    return string(
        abi.encodePacked(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                name,
                bytes('","description":"'),
                getDescription(tokenId),
                bytes('","external_url":"'),
                metadataStorageContract.getExternalUrl(tokenId),
                bytes('","image":"'),
                metadataStorageContract.getImageCache(tokenId)
            ),
            abi.encodePacked(
                bytes('","attributes":['),
                getTalentAttributes(tokenId),
                metadataStorageContract.getStatAttributes(tokenId),
                metadataStorageContract.getLayerAttributes(tokenId),
                bytes(']}')
            )
        )
    );
  }

  function getBrokerName(uint256 _tokenId) public view returns (string memory) {
    return metadataStorageContract.getBrokerName(_tokenId);
  }

  function getLayers(uint256 tokenId) public view returns (uint256[] memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA -> layers
    uint256 dna = brokerDna(tokenId);
    require(dna > 0, "Broker DNA missing for token");

    uint256 layerCount = (dna >> BROKER_LAYER_COUNT_DNA_POSITION) & BROKER_LAYER_COUNT_DNA_BITMASK;
    uint256[] memory layers = new uint256[](layerCount);
    for (uint256 layerIdx; layerIdx < layerCount; layerIdx++) {
      layers[layerIdx] = (dna >> (BROKER_LAYERS_DNA_SIZE * layerIdx + BROKER_LAYERS_DNA_POSITION)) & BROKER_LAYER_DNA_BITMASK;
    }
    return layers;
  }

  function getDescription(uint256 tokenId) public view returns (string memory) {
    CyberBrokerTalent memory talent = getTalent(tokenId);
    return talent.description;
  }

  function getExternalUrl(uint256 tokenId) public view returns (string memory) {
    return metadataStorageContract.getExternalUrl(tokenId);
  }

  function getImageCache(uint256 tokenId) public view returns (string memory) {
    return metadataStorageContract.getImageCache(tokenId);
  }

  function getTalentAttributes(uint256 tokenId) public view returns (string memory) {
    CyberBrokerTalent memory talent = getTalent(tokenId);

    return string(
      abi.encodePacked(
        abi.encodePacked(
          bytes('{"trait_type": "Talent", "value": "'),
          talent.talent,
          bytes('"},{"trait_type": "Species", "value": "'),
          talent.species
        ),
        abi.encodePacked(
          bytes('"},{"trait_type": "Class", "value": "'),
          talent.class,
          bytes('"},')
        )
      )
    );
  }

  function getTalent(uint256 tokenId) public view returns (CyberBrokerTalent memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA
    uint256 dna = brokerDna(tokenId);
    require(dna > 0, "Broker DNA missing for token");

    // Get the talent
    uint256 talentIndex = (dna >> BROKER_TALENT_DNA_POSITION) & BROKER_TALENT_DNA_BITMASK;

    require(talentIndex < 1460, "Invalid talent index");

    return talentMap(talentIndex);
  }

  function getStats(uint256 tokenId) public view returns (uint256 mind, uint256 body, uint256 soul) {
    return metadataStorageContract.getStats(tokenId);
  }

  function getStatAttributes(uint256 tokenId) public view returns (string memory) {
    return metadataStorageContract.getStatAttributes(tokenId);
  }

  function getLayerAttributes(uint256 tokenId) public view returns (string memory) {
    // Get the layersg
    uint256[] memory layers = getLayers(tokenId);

    // Get the attribute names for all layers
    CyberBrokerLayer[] memory attrLayers = new CyberBrokerLayer[](layers.length);

    uint256 maxAttrLayerIdx = 0;
    for (uint16 layerIdx; layerIdx < layers.length; layerIdx++) {
      CyberBrokerLayer memory attribute = layerMap(layers[layerIdx]);

      if (keccak256(abi.encodePacked(attribute.attributeValue)) != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470) {
        attrLayers[maxAttrLayerIdx++] = attribute;
      }
    }

    // Compile the attributes
    string memory attributes = "";
    for (uint16 attrIdx; attrIdx < maxAttrLayerIdx; attrIdx++) {
      attributes = string(
        abi.encodePacked(
          attributes,
          bytes(',{"trait_type": "'),
          attrLayers[attrIdx].attributeName,
          bytes('", "value": "'),
          attrLayers[attrIdx].attributeValue,
          bytes('"}')
        )
      );
    }

    return attributes;
  }


  /**
   * On-Chain Token SVG Rendering
   **/

  // REQUIRED for token contract
  function render(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return metadataStorageContract.render(tokenId);
  }

  function renderData(
    string memory _key,
    uint256 _startIndex
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return metadataStorageContract.renderData(_key, _startIndex);
  }

  function _renderData(
    string memory _key,
    uint256 _startIndex,
    uint256 _thresholdCounter
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return metadataStorageContract._renderData(_key, _startIndex, _thresholdCounter);
  }

  function renderBroker(
    uint256 _tokenId,
    uint256 _startIndex
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return metadataStorageContract.renderBroker(_tokenId, _startIndex);
  }

  function _renderBroker(
    uint256 _tokenId,
    uint256 _startIndex,
    uint256 _thresholdCounter
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return metadataStorageContract._renderBroker(_tokenId, _startIndex, _thresholdCounter);
  }


  /**
   * Off-Chain Token SVG Rendering
   **/

  function getTokenData(uint256 _tokenId)
    public
    view
    returns (bytes memory)
  {
    uint256[] memory layerNumbers = getLayers(_tokenId);

    string[] memory layers = new string[](layerNumbers.length);
    for (uint256 layerIdx; layerIdx < layerNumbers.length; layerIdx++) {
      string memory key = layerMap(layerNumbers[layerIdx]).key;
      require(contractDataStorage().hasKey(key), "Key does not exist in contract data storage");
      layers[layerIdx] = key;
    }

    return contractDataStorage().getDataForAll(layers);
  }

  function getOffchainSvgParser()
    public
    view
    returns (
      string memory _output
    )
  {
    return metadataStorageContract.getOffchainSvgParser();
  }


  /**
   * Leaving all setters out of this contract
   **/
  /*

  function setContractDataStorageAddress(address _contractDataStorageAddress) public onlyOwner {
    metadataStorageContract.setContractDataStorageAddress(_contractDataStorageAddress);
  }

  function setSvgParserAddress(address _svgParserAddress) public onlyOwner {
    metadataStorageContract.setSvgParserAddress(_svgParserAddress);
  }

  function setLayers(
    uint256[] memory indexes,
    string[]  memory keys,
    string[]  memory attributeNames,
    string[]  memory attributeValues
  )
    public
    onlyOwner
  {
    metadataStorageContract.setLayers(indexes, keys, attributeNames, attributeValues);
  }

  function setTalents(
    uint256[] memory indexes,
    string[]  memory talent,
    string[]  memory species,
    string[]  memory class,
    string[]  memory description
  )
    public
    onlyOwner
  {
    metadataStorageContract.setTalents(indexes, talent, species, class, description);
  }

  function setBrokers(
    uint256[]  memory indexes,
    uint8[]    memory talent,
    uint8[]    memory mind,
    uint8[]    memory body,
    uint8[]    memory soul,
    uint16[][] memory layers
  )
    public
    onlyOwner
  {
    metadataStorageContract.setBrokers(indexes, talent, mind, body, soul, layers);
  }

  function setOnChainMetadata(bool _state) public onlyOwner {
    metadataStorageContract.setOnChainMetadata(_state);
  }

  function setExternalUri(string calldata _uri) public onlyOwner {
    metadataStorageContract.setExternalUri(_uri);
  }

  function setUseIndividualExternalUri(bool _setting) public onlyOwner {
    metadataStorageContract.setUseIndividualExternalUri(_setting);
  }

  function setImageCacheUri(string calldata _uri) public onlyOwner {
    metadataStorageContract.setImageCacheUri(_uri);
  }
  */

}
