// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IyusdiCollectionsBase.sol";

contract IyusdiCollectionsV2 is IyusdiCollectionsBase {

  constructor (address _protocol, uint256 _protocolMintPercent, uint256 _protocolBurnPercent, uint256 _curatorMintPercent, uint256 _curatorBurnPercent) {
    require(_protocol != address(0), '!protocol');
    require(_protocolMintPercent + _curatorMintPercent <= IyusdiCollectionsBase.PERCENT_BASE, '!mintPercent');
    require(_protocolBurnPercent + _curatorBurnPercent <= IyusdiCollectionsBase.PERCENT_BASE, '!burnPercent');
    owner = msg.sender;
    protocol = _protocol;
    protocolMintPercent = _protocolMintPercent;
    protocolBurnPercent = _protocolBurnPercent;
    curatorMintPercent = _curatorMintPercent;
    curatorBurnPercent = _curatorBurnPercent;
  }

}
