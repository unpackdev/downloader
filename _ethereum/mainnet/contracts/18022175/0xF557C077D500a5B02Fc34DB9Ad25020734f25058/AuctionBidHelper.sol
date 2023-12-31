pragma solidity =0.8.17;

import "./IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

import "./ConsiderationStructs.sol";
import "./Consideration.sol";
import "./AmountDeriver.sol";

contract AuctionBidHelper is AmountDeriver {
  IWETH9 public immutable WETH;
  Consideration public immutable SEAPORT;

  constructor(IWETH9 weth_, Consideration seaport_) {
    WETH = weth_;
    SEAPORT = seaport_;
  }

  function fulfillAdvancedOrder(
    AdvancedOrder calldata advancedOrder,
    CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable {
    uint256 currentAmount = _locateCurrentAmount(
      advancedOrder.parameters.consideration[0].startAmount,
      advancedOrder.parameters.consideration[0].endAmount,
      advancedOrder.parameters.startTime,
      advancedOrder.parameters.endTime,
      true
    );
    if (
      advancedOrder.parameters.consideration[0].token == address(WETH) &&
      msg.value >= currentAmount
    ) {
      WETH.deposit{value: currentAmount}();
      WETH.approve(address(SEAPORT), currentAmount);
    } else {
      revert("bad input data");
    }
    SEAPORT.fulfillAdvancedOrder(
      advancedOrder,
      criteriaResolvers,
      fulfillerConduitKey,
      recipient
    );
    msg.sender.call{value: address(this).balance}("");
  }
}
