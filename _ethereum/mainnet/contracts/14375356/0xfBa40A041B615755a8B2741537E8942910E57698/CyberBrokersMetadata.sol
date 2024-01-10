// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

import "./ContractDataStorage.sol";
import "./SvgParser.sol";

contract CyberBrokersMetadata is Ownable {
  using Strings for uint256;

  bool private _useOnChainMetadata = false;
  bool private _useIndividualExternalUri = false;

  string private _externalUri = "https://cyberbrokers.io/";
  string private _imageCacheUri = "ipfs://QmcsrQJMKA9qC9GcEMgdjb9LPN99iDNAg8aQQJLJGpkHxk/";

  // Mapping of all layers
  struct CyberBrokerLayer {
    string key;
    string attributeName;
    string attributeValue;
  }
  CyberBrokerLayer[1460] public layerMap;

  // Mapping of all talents
  struct CyberBrokerTalent {
    string talent;
    string species;
    string class;
    string description;
  }
  CyberBrokerTalent[51] public talentMap;

  // Directory of Brokers
  uint256[10001] public brokerDna;

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
  uint256 constant private BROKER_TALENT_DNA_BITMASK = uint256(0x2F);
  uint256 constant private BROKER_LAYER_COUNT_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_LAYER_DNA_BITMASK = uint256(0x0FFF);

  // Contracts
  ContractDataStorage public contractDataStorage;
  SvgParser public svgParser;

  constructor(
    address _contractDataStorageAddress,
    address _svgParserAddress
  ) {
    // Set the addresses
    setContractDataStorageAddress(_contractDataStorageAddress);
    setSvgParserAddress(_svgParserAddress);
  }

  function setContractDataStorageAddress(address _contractDataStorageAddress) public onlyOwner {
    contractDataStorage = ContractDataStorage(_contractDataStorageAddress);
  }

  function setSvgParserAddress(address _svgParserAddress) public onlyOwner {
    svgParser = SvgParser(_svgParserAddress);
  }

  /**
   * Save the data on-chain
   **/
  function setLayers(
    uint256[] memory indexes,
    string[]  memory keys,
    string[]  memory attributeNames,
    string[]  memory attributeValues
  )
    public
    onlyOwner
  {
    require(
      indexes.length == keys.length &&
      indexes.length == attributeNames.length &&
      indexes.length == attributeValues.length,
      "Number of indexes much match keys, names and values"
    );

    for (uint256 idx; idx < indexes.length; idx++) {
      uint256 index = indexes[idx];
      layerMap[index] = CyberBrokerLayer(keys[idx], attributeNames[idx], attributeValues[idx]);
    }
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
    require(
      indexes.length == talent.length &&
      indexes.length == species.length &&
      indexes.length == class.length &&
      indexes.length == description.length
    , "Number of indexes must match talent, species, class, and description");

    for (uint256 idx; idx < indexes.length; idx++) {
      uint256 index = indexes[idx];
      talentMap[index] = CyberBrokerTalent(talent[idx], species[idx], class[idx], description[idx]);
    }
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
    require(
      indexes.length == talent.length &&
      indexes.length == mind.length &&
      indexes.length == body.length &&
      indexes.length == soul.length &&
      indexes.length == layers.length,
      "Number of indexes must match talent, mind, body, soul, and layers"
    );

    for (uint8 idx; idx < indexes.length; idx++) {
      require(talent[idx] <= talentMap.length, "Invalid talent index");
      require(mind[idx] <= 30, "Invalid mind");
      require(body[idx] <= 30, "Invalid body");
      require(soul[idx] <= 30, "Invalid soul");

      uint256 _dna = (
        (uint256(mind[idx])   << BROKER_MIND_DNA_POSITION) +
        (uint256(body[idx])   << BROKER_BODY_DNA_POSITION) +
        (uint256(soul[idx])   << BROKER_SOUL_DNA_POSITION) +
        (uint256(talent[idx]) << BROKER_TALENT_DNA_POSITION) +
        (layers[idx].length   << BROKER_LAYER_COUNT_DNA_POSITION)
      );

      for (uint16 layerIdx; layerIdx < layers[idx].length; layerIdx++) {
        require(uint256(layers[idx][layerIdx]) <= layerMap.length, "Invalid layer index");
        _dna += uint256(layers[idx][layerIdx]) << (BROKER_LAYERS_DNA_SIZE * layerIdx + BROKER_LAYERS_DNA_POSITION);
      }

      uint256 index = indexes[idx];

      brokerDna[index] = _dna;
    }
  }

  /**
   * On-Chain Metadata Construction
   **/

  // REQUIRED for token contract
  function hasOnchainMetadata(uint256) public view returns (bool) {
    return _useOnChainMetadata;
  }

  function setOnChainMetadata(bool _state) public onlyOwner {
    _useOnChainMetadata = _state;
  }

  function setExternalUri(string calldata _uri) public onlyOwner {
    _externalUri = _uri;
  }

  function setUseIndividualExternalUri(bool _setting) public onlyOwner {
    _useIndividualExternalUri = _setting;
  }

  function setImageCacheUri(string calldata _uri) public onlyOwner {
    _imageCacheUri = _uri;
  }

  // REQUIRED for token contract
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Unpack the name, talent and layers
    string memory name = getBrokerName(tokenId);

    return string(
        abi.encodePacked(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                name,
                bytes('","description":"'),
                getDescription(tokenId),
                bytes('","external_url":"'),
                getExternalUrl(tokenId),
                bytes('","image":"'),
                getImageCache(tokenId)
            ),
            abi.encodePacked(
                bytes('","attributes":['),
                getTalentAttributes(tokenId),
                getStatAttributes(tokenId),
                getLayerAttributes(tokenId),
                bytes(']}')
            )
        )
    );
  }

  function getBrokerName(uint256 _tokenId) public view returns (string memory) {
    string memory _key = 'broker-names';
    require(contractDataStorage.hasKey(_key), "Broker names are not uploaded");

    // Get the broker names
    bytes memory brokerNames = contractDataStorage.getData(_key);

    // Pull the broker name size
    uint256 brokerNameSize = uint256(uint8(brokerNames[_tokenId * 31]));

    bytes memory name = new bytes(brokerNameSize);
    for (uint256 idx; idx < brokerNameSize; idx++) {
      name[idx] = brokerNames[_tokenId * (31) + 1 + idx];
    }

    return string(name);
  }

  function getLayers(uint256 tokenId) public view returns (uint256[] memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA -> layers
    uint256 dna = brokerDna[tokenId];
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
    if (_useIndividualExternalUri) {
      return string(abi.encodePacked(_externalUri, tokenId.toString()));
    }

    return _externalUri;
  }

  function getImageCache(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_imageCacheUri, tokenId.toString(), ".svg"));
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

  function getTalent(uint256 tokenId) public view returns (CyberBrokerTalent memory talent) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA
    uint256 dna = brokerDna[tokenId];
    require(dna > 0, "Broker DNA missing for token");

    // Get the talent
    uint256 talentIndex = (dna >> BROKER_TALENT_DNA_POSITION) & BROKER_TALENT_DNA_BITMASK;

    require(talentIndex < talentMap.length, "Invalid talent index");

    return talentMap[talentIndex];
  }

  function getStats(uint256 tokenId) public view returns (uint256 mind, uint256 body, uint256 soul) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA
    uint256 dna = brokerDna[tokenId];
    require(dna > 0, "Broker DNA missing for token");

    // Return the mind, body, and soul
    return (
      (dna >> BROKER_MIND_DNA_POSITION) & BROKER_MIND_DNA_BITMASK,
      (dna >> BROKER_BODY_DNA_POSITION) & BROKER_BODY_DNA_BITMASK,
      (dna >> BROKER_SOUL_DNA_POSITION) & BROKER_SOUL_DNA_BITMASK
    );
  }

  function getStatAttributes(uint256 tokenId) public view returns (string memory) {
    (uint256 mind, uint256 body, uint256 soul) = getStats(tokenId);

    return string(
      abi.encodePacked(
        abi.encodePacked(
          bytes('{"trait_type": "Mind", "value": '),
          mind.toString(),
          bytes('},{"trait_type": "Body", "value": '),
          body.toString()
        ),
        abi.encodePacked(
          bytes('},{"trait_type": "Soul", "value": '),
          soul.toString(),
          bytes('}')
        )
      )
    );
  }

  function getLayerAttributes(uint256 tokenId) public view returns (string memory) {
    // Get the layersg
    uint256[] memory layers = getLayers(tokenId);

    // Get the attribute names for all layers
    CyberBrokerLayer[] memory attrLayers = new CyberBrokerLayer[](layers.length);

    uint256 maxAttrLayerIdx = 0;
    for (uint16 layerIdx; layerIdx < layers.length; layerIdx++) {
      CyberBrokerLayer memory attribute = layerMap[layers[layerIdx]];

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
    uint256
  )
    public
    pure
    returns (string memory)
  {
    return string("To render the token on-chain, call CyberBrokersMetadata.renderBroker(_tokenId, _startIndex) or CyberBrokersMetadata._renderBroker(_tokenId, _startIndex, _thresholdCounter) and iterate through the pages starting at _startIndex = 0. To render off-chain and use an off-chain renderer, call CyberBrokersMetadata.getTokenData(_tokenId) to get the raw data. A JavaScript parser is available by calling CyberBrokersMetadata.getOffchainSvgParser().");
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
    return _renderData(_key, _startIndex, 2800);
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
    require(contractDataStorage.hasKey(_key));
    return svgParser.parse(contractDataStorage.getData(_key), _startIndex, _thresholdCounter);
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
    return _renderBroker(_tokenId, _startIndex, 2800);
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
    require(_tokenId <= 10000, "Can only render valid token ID");
    return svgParser.parse(getTokenData(_tokenId), _startIndex, _thresholdCounter);
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
      string memory key = layerMap[layerNumbers[layerIdx]].key;
      require(contractDataStorage.hasKey(key), "Key does not exist in contract data storage");
      layers[layerIdx] = key;
    }

    return contractDataStorage.getDataForAll(layers);
  }

  function getOffchainSvgParser()
    public
    view
    returns (
      string memory _output
    )
  {
    string memory _key = 'svg-parser.js';
    require(contractDataStorage.hasKey(_key), "Off-chain SVG Parser not uploaded");
    return string(contractDataStorage.getData(_key));
  }

}
