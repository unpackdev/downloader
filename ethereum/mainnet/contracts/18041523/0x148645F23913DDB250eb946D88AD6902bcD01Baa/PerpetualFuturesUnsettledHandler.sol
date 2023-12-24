// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Context.sol";
import "./IERC20Metadata.sol";
import "./IPerpetualFutures.sol";

contract PerpetualFuturesUnsettledHandler is Context {
  IPerpetualFutures public perpetualFutures;

  struct UnsettledPositions {
    uint256 tokenId;
    address owner;
    address collateralToken;
    uint256 unsettledAmount;
  }

  UnsettledPositions[] public unsettled;

  event AddUnsettledPosition(
    uint256 indexed tokenId,
    address indexed token,
    uint256 amount,
    uint256 idx
  );
  event SettlePosition(
    uint256 indexed tokenId,
    uint256 collateralAmount,
    uint256 mainAmount,
    uint256 collateralPriceUSD,
    uint256 mainPriceUSD
  );

  modifier onlyPerps() {
    require(_msgSender() == address(perpetualFutures), 'UNAUTHORIZED');
    _;
  }

  modifier onlyRelay() {
    require(perpetualFutures.relays(_msgSender()), 'UNAUTHORIZED');
    _;
  }

  constructor() {
    perpetualFutures = IPerpetualFutures(_msgSender());
  }

  function getAllUnsettled()
    external
    view
    returns (UnsettledPositions[] memory)
  {
    return unsettled;
  }

  function getUnsettledLength() external view returns (uint256) {
    return unsettled.length;
  }

  function addUnsettledPosition(
    uint256 _tokenId,
    address _ownerAtAddTime,
    address _token,
    uint256 _amount
  ) external onlyPerps {
    unsettled.push(
      UnsettledPositions({
        tokenId: _tokenId,
        owner: _ownerAtAddTime,
        collateralToken: _token,
        unsettledAmount: _amount
      })
    );
    emit AddUnsettledPosition(_tokenId, _token, _amount, unsettled.length - 1);
  }

  function settleUnsettledPosition(
    uint256 _idx,
    uint256 _collPriceUSD,
    uint256 _mainPriceUSD
  ) external onlyRelay {
    UnsettledPositions memory _info = unsettled[_idx];
    uint256 _mainSettleAmt = (_info.unsettledAmount *
      10**IERC20Metadata(perpetualFutures.mainCollateralToken()).decimals() *
      _collPriceUSD) /
      _mainPriceUSD /
      10**IERC20Metadata(_info.collateralToken).decimals();
    perpetualFutures.executeSettlement(
      _info.tokenId,
      _info.owner,
      _mainSettleAmt
    );
    unsettled[_idx] = unsettled[unsettled.length - 1];
    unsettled.pop();
    emit SettlePosition(
      _info.tokenId,
      _info.unsettledAmount,
      _mainSettleAmt,
      _collPriceUSD,
      _mainPriceUSD
    );
  }
}
