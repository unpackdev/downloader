// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./ERC1155.sol";
import "./Governable.sol";

contract BoosterToken is Governable, ERC1155Pausable {
  struct Boost {
    uint256 winIncrease;
    uint256 gasDecrease;
    uint256 price;
  }

  Boost[] public boosters;

  event BoosterInit(uint256 indexed id);
  event BoosterBought(uint256 indexed id);

  constructor(address _governance, string memory _uri) public
    Governable(_governance)
    ERC1155(_uri)
  {
    boosters.push(Boost(0, 0, 0));
  }

  function init(uint256 _winIncrease, uint256 _gasDecrease, uint256 _price) public onlyGovernance {
    boosters.push(Boost(_winIncrease, _gasDecrease, _price));

    emit BoosterInit(boosters.length);
  }

  function initBatch(uint256[] calldata _winIncreases, uint256[] calldata _gasDecreases, uint256[] calldata _prices) external onlyGovernance {
    require(_winIncreases.length == _gasDecreases.length && _gasDecreases.length == _prices.length);
    for(uint8 i = 0; i < _winIncreases.length; i++) {
      init(_winIncreases[i], _gasDecreases[i], _prices[i]);
    }
  }

  function getBooster(uint256 _id) public view returns (uint256, uint256, uint256) {
    Boost storage booster = boosters[_id];
    return (booster.winIncrease, booster.gasDecrease, booster.price);
  }

  function buy(address _to, uint256 _id) payable external whenNotPaused {
    require(msg.value >= boosters[_id].price);
    _mint(_to, _id, 1, "");

    emit BoosterBought(_id);
  }

  function withdraw(address _account) external onlyGovernance {
    (bool success, ) = _account.call{ value: address(this).balance, gas: 2300 }("");
    require(success);
  }

  function pause() external onlyGovernance {
    super._pause();
  }

  function unpause() external onlyGovernance {
    super._unpause();
  }

  function isApprovedForAll(address _account, address _operator) public view override returns (bool) {
    return super.isApprovedForAll(_account, _operator) || governance.isBoosterEscrow(_operator);
  }

  receive() external payable { }
}