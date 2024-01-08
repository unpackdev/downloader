// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AddressUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ILayer.sol";
import "./CMCLayerStorageV0.sol";
import "./AggregatorV3Interface.sol";

contract CMCLayerV0 is
    OwnableUpgradeable,
    ILayer,
    ERC721Upgradeable,
    CMCLayerStorageV0
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function CMCLayer_init(
        string memory _name,
        string memory _symbol,
        address _oracle,
        address _owner,
        uint256 _updateInterval,
        int256 _threshold,
        uint32 _stateCount
    ) public initializer {
        __Ownable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        priceFeed = AggregatorV3Interface(_oracle);
        updateInterval = _updateInterval;
        globalStateCount = _stateCount;
        threshold = _threshold;
        transferOwnership(_owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(ILayer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev layer getter method
     */
    function getLayer(uint256 id)
        public
        view
        override
        returns (uint32 stateCount, uint32 currentState)
    {
        return (globalStateCount, globalCurrentState);
    }

    /**
     * @dev update all CMC layer's shared currentState;
     */
    function updateAll() external {
      require(id.current() > 0, "Err: no layer created");
      (int256 price, uint256 timestamp) = _getPrice();
      if (lastPrice == 0) {
        globalCurrentState = 0;
        lastPrice = price;
        lastUpdatedAt = timestamp;
        return;
      }
      require(timestamp >= lastUpdatedAt + updateInterval, "Err: must update after set interval");
      uint32 desiredState = _desiredState(price);
      require(desiredState < globalStateCount, "Err: new state above state count");
      globalCurrentState = desiredState;
      lastPrice = price;
      lastUpdatedAt = timestamp;
    }

    /**
     * @dev set threshold
     * @param _threshold a new threshold value in bp
     */
    function setThreshold(int256 _threshold) external onlyOwner {
      threshold = _threshold;
    }

    /**
     * @dev creates a layer with states
     */
    function create(address _to, string[] calldata _cids, uint32 _currentState, bytes calldata _data) external onlyOwner {
      require(_cids.length == 3, 'Err: Must provide 3 Content Identifier');
      require(_currentState < globalStateCount, 'Err: Current State must be valid');
      uint256 _id = _nextId();
      layers[_id] = Layer(_cids);
      _safeMint(_to, _id, _data);
    }

    function verifyCid(uint256 _id, uint256 _index) external view validLayerId(_id) returns (string memory){
      return layers[_id].cids[_index];
    }

    function _nextId() internal returns (uint256) {
        id.increment();
        return id.current();
    }

    function _getPrice() internal view returns (int256 price, uint256 timestamp) {
      ( , price, ,timestamp,) = priceFeed.latestRoundData();
    }

    function _desiredState(int256 price) internal view returns (uint32) {
      int256 priceDelta = price - lastPrice;
      int256 percentage = priceDelta * 10000 / lastPrice;
      if (priceDelta > 0) {
        if (percentage >= threshold) {
          return 1;
        }
      } else {
        if (-percentage >= threshold) {
          return 2;
        }
      }
      return 0;
    }

    /**
     * @dev Throws if caller does not own layer of `id`
     */
    modifier onlyLayerOwner(uint256 id) {
        require(ownerOf(id) == _msgSender(), "only layer owner");
        _;
    }

    /**
     * @dev Throws if layer `id` does not exist
     */
    modifier validLayerId(uint256 _id) {
        require(layers[_id].cids.length > 0, "layer is not created");
        _;
    }
}
