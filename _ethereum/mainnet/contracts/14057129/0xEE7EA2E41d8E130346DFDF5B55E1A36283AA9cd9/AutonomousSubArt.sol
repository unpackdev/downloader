// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

import "./base64.sol";
import "./console.sol";
import "./CollectiveCanvas.sol";

/**
 * @title Autonomous Sub Art contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract AutonomousSubArt is ERC721Enumerable, Ownable {

    struct Layer {
      address creator;
      uint256 timestamp;
      uint256 funded;
      uint256 withdrawIndex;
      uint256 tokenId;
      bytes   data;
    }

    struct LayerIndex {
      uint256 parentId;
      uint256 index;
    }

    struct Fork {
      uint256 basePrice;
      uint256 priceIncrementInterval;
      uint256 ownerWithdrawnIndex;
      uint256 totalFunded;
      Layer[] layers;
    }

    uint256 constant DEFAULT_BASE_PRICE               = 24000000000000000; //0.024 ETH
    uint256 constant DEFAULT_PRICE_INCREMENT_INTERVAL = 10;
    uint256 constant ACTIVATION_GAP_SIZE              = 10;

    mapping(uint256 => Fork)       private _forks; // Mapping from parentId => Fork
    mapping(uint256 => LayerIndex) private _index; // Mapping from tokenId  => LayerIndex

    CollectiveCanvas private _autonomousArt;
    uint256          private _tokenCount;
    uint256          private _rootBalance;
    uint256          private _totalFundsReceived;

    constructor(string memory name, string memory symbol, address parentAddress) ERC721(name, symbol) {
      _autonomousArt = CollectiveCanvas(parentAddress);
      _tokenCount    = 0;
      _rootBalance   = 0;
    }

    function mint(uint256 parentId, bytes memory layer) public payable returns (uint256) {
      require(isForkActivated(parentId), "Invalid parent, not yet activated");
      require(currentPriceToMint(parentId) <= msg.value, "Eth value sent is not sufficient");
      
      _autonomousArt._validateLayer(layer);

      Fork    storage fork      = _forks[parentId];
      uint256         mintIndex = _tokenCount;
      uint256         forkIndex = fork.layers.length;

      fork.layers.push(Layer({creator: msg.sender,
                              timestamp: block.timestamp,
                              funded: msg.value,
                              withdrawIndex: forkIndex,
                              tokenId: mintIndex,
                              data: layer}));
      fork.totalFunded += msg.value;

      _index[mintIndex] = LayerIndex({parentId: parentId, index: forkIndex});

      _tokenCount         += 1;
      _rootBalance        += msg.value / (forkIndex + 1 + 1 + 1);
      _totalFundsReceived += msg.value;

      _safeMint(msg.sender, mintIndex);

      return mintIndex;
    }

    function isForkActivated(uint256 parentId) public view returns (bool) {
      uint256 parentLayerCount = _autonomousArt.layerCount();
      return parentLayerCount > parentId && parentLayerCount - parentId > ACTIVATION_GAP_SIZE;
    }

    function balanceOfToken(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), "Query for nonexistent token");

      uint256 parentId          = _index[tokenId].parentId;      
      uint256 layerIndex        = _index[tokenId].index;
      uint256 withdrawFromIndex = _forks[parentId].layers[layerIndex].withdrawIndex;

      return _balanceOfLayerIndex(parentId, withdrawFromIndex);
    }

    function balanceOfParent(uint256 parentId) public view returns (uint256) {
      return _balanceOfLayerIndex(parentId, _forks[parentId].ownerWithdrawnIndex);
    }

    function balanceOfRoot() public view returns (uint256) {
      return _rootBalance;
    }

    function totalForkFunded(uint256 parentId) public view returns (uint256) {
      return _forks[parentId].totalFunded;
    }

    function totalFunded() public view returns (uint256) {
      return _totalFundsReceived;
    }

    function tokenCount() public view returns (uint256) {
      return _tokenCount;
    }

    function withdrawForToken(uint256 tokenId) public {
      require(ownerOf(tokenId) == msg.sender, "Unauthorized attempt to withdraw");

      uint256 balance = balanceOfToken(tokenId);

      LayerIndex storage layerIndex = _index[tokenId];
      Layer      storage layer      = _forks[layerIndex.parentId].layers[layerIndex.index];

      layer.withdrawIndex = _forks[layerIndex.parentId].layers.length;

      payable(msg.sender).transfer(balance);
    }

    function withdrawForParent(uint256 parentId) public {
      require (_autonomousArt.ownerOf(parentId) == msg.sender, "Unauthorized attempt to withdraw");

      uint256 balance = balanceOfParent(parentId);

      Fork storage fork = _forks[parentId];

      fork.ownerWithdrawnIndex = fork.layers.length;

      payable(msg.sender).transfer(balance);
    }

    function withdrawForRoot() public {
      require(_autonomousArt.ownerOf(0) == msg.sender, "Unauthorized attempt to withdraw");

      uint256 balance = _rootBalance;
      _rootBalance    = 0;

      payable(msg.sender).transfer(balance);
    }

    function currentPriceToMint(uint256 parentId) public view returns (uint256) {
      uint256 basePrice              = getForkBasePrice(parentId);
      uint256 priceIncrementInterval = getForkPriceIncrementInterval(parentId);
      uint256 forkLayerCount         = _forks[parentId].layers.length;

      return basePrice * ((forkLayerCount / priceIncrementInterval) + 1);
    }

    function getForkBasePrice(uint256 parentId) public view returns (uint256) {
      uint256 basePrice = _forks[parentId].basePrice;

      if (basePrice == 0) {
        basePrice = DEFAULT_BASE_PRICE;
      }

      return basePrice;
    }

    function getForkPriceIncrementInterval(uint256 parentId) public view returns (uint256) {
      uint256 priceIncrementInterval = _forks[parentId].priceIncrementInterval;

      if (priceIncrementInterval == 0) {
        priceIncrementInterval = DEFAULT_PRICE_INCREMENT_INTERVAL;
      }

      return priceIncrementInterval;
    }

    function setForkConfiguration(uint256 parentId, uint256 basePrice, uint256 priceIncrementInterval) public {
      require(_autonomousArt.ownerOf(parentId) == msg.sender, "Unauthorized attempt to configure fork");
      require(basePrice > 0, "Base price can not be 0");
      require(basePrice >= _forks[parentId].basePrice, "Base price can only increase");

      _forks[parentId].basePrice              = basePrice;
      _forks[parentId].priceIncrementInterval = priceIncrementInterval;
    }

    function layerCount(uint256 parentId) public view returns (uint256) {
      return _forks[parentId].layers.length;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      LayerIndex storage index = _index[tokenId];
      Fork       storage fork  = _forks[index.parentId];

      string memory svgUri  = _encodeSvgUriAtLayerIndex(index.parentId, fork.layers.length-1);
      string memory json    = Base64.encode(abi.encodePacked('{"name":"Autonomous Sub Art #', Strings.toString(index.parentId), ".", Strings.toString(index.index), '","image":"', svgUri, '"}'));
      string memory jsonUri = string(abi.encodePacked("data:application/json;base64,", json));

      return jsonUri;
    }

    function imageForFork(uint256 parentId) public view returns (string memory) {
      uint256 layerLength = _forks[parentId].layers.length;
      return _encodeSvgUriAtLayerIndex(parentId, layerLength > 0 ? layerLength-1 : 0);
    } 

    function historicalImageAt(uint256 tokenId) public view returns (string memory) {
      require(_exists(tokenId), "Query for nonexistent token");

      LayerIndex storage index = _index[tokenId];

      return _encodeSvgUriAtLayerIndex(index.parentId, index.index);
    }

    function historicalImageAtLayerIndex(uint256 parentId, uint256 layerIndex) public view returns (string memory) {
      require(_forks[parentId].layers[layerIndex].creator != address(0));

      return _encodeSvgUriAtLayerIndex(parentId, layerIndex);
    }

    function layerAt(uint256 parentId, uint256 layerIndex) public view returns (Layer memory) {
      return _forks[parentId].layers[layerIndex];
    }

    function _balanceOfLayerIndex(uint256 parentId, uint256 layerIndex) private view returns (uint256) {
      Fork    storage fork              = _forks[parentId];
      uint256         balance           = 0;

      for (uint256 i=layerIndex;i<fork.layers.length;i++) {
        balance += (fork.layers[i].funded / (i + 1 + 1 + 1));
      }

      return balance;
    }

    function _encodeSvgUriAtLayerIndex(uint256 parentId, uint256 layerIndex) private view returns (string memory) {
      return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(_encodeSvgAtLayerIndex(parentId, layerIndex))));
    }

    function _encodeSvgAtLayerIndex(uint256 parentId, uint256 layerIndex) private view returns (bytes memory) {
        string memory parentSvg  = _autonomousArt.historicalImageAt(parentId);
        bytes  memory svg        = abi.encodePacked('<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" style="background-image:url(', parentSvg, ')">');

        for (uint256 i=0 ; i <= layerIndex && i < _forks[parentId].layers.length ; i++) {
          svg = abi.encodePacked(svg, '<g>', _forks[parentId].layers[i].data, '</g>');
        }

        svg = abi.encodePacked(svg, '</svg>');

        return svg;
    }

}