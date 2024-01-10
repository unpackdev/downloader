// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface I1inchAggregationRouterV4 {
  struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  event OrderFilledRFQ(bytes32 orderHash,uint256 makingAmount) ;

  event OwnershipTransferred(address indexed previousOwner,address indexed newOwner) ;

  event Swapped(address sender,address srcToken,address dstToken,address dstReceiver,uint256 spentAmount,uint256 returnAmount) ;

  function DOMAIN_SEPARATOR() external view returns (bytes32) ;

  function LIMIT_ORDER_RFQ_TYPEHASH() external view returns (bytes32) ;

  function cancelOrderRFQ(uint256 orderInfo) external;

  function destroy() external;

  function fillOrderRFQ(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount) external payable returns (uint256 , uint256) ;

  function fillOrderRFQTo(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount,address target) external payable returns (uint256 , uint256) ;

  function fillOrderRFQToWithPermit(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount,address target,bytes memory permit) external  returns (uint256 , uint256) ;

  function invalidatorForOrderRFQ(address maker,uint256 slot) external view returns (uint256) ;

  function owner() external view returns (address) ;

  function renounceOwnership() external;

  function rescueFunds(address token,uint256 amount) external;

  function swap(address caller,SwapDescription memory desc,bytes memory data) external payable returns (uint256 returnAmount, uint256 gasLeft);

  function transferOwnership(address newOwner) external;

  function uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] memory pools) external payable returns (uint256 returnAmount) ;

  function uniswapV3SwapCallback(int256 amount0Delta,int256 amount1Delta,bytes memory ) external;

  function uniswapV3SwapTo(address recipient,uint256 amount,uint256 minReturn,uint256[] memory pools) external payable returns (uint256 returnAmount) ;

  function uniswapV3SwapToWithPermit(address recipient,address srcToken,uint256 amount,uint256 minReturn,uint256[] memory pools,bytes memory permit) external  returns (uint256 returnAmount) ;

  function unoswap(address srcToken,uint256 amount,uint256 minReturn,bytes32[] memory pools) external payable returns (uint256 returnAmount) ;

  function unoswapWithPermit(address srcToken,uint256 amount,uint256 minReturn,bytes32[] memory pools,bytes memory permit) external  returns (uint256 returnAmount) ;

  receive () external payable;
}

interface LimitOrderProtocolRFQ {
  struct OrderRFQ {
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
  }
}