// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

abstract contract IPopMarketplace {
    function submitMlp(address _token0, address _token1, uint _liquidity, uint _endDate, uint _bonusToken0, uint _bonusToken1) public virtual;
    function endMlp(uint _mlpId) public virtual returns(uint);
    function cancelMlp(uint256 _mlpId) public virtual;
}
