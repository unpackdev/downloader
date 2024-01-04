pragma solidity 0.6.11;

interface IPeak {
    function mint(uint poolId, uint inAmount) external returns(uint outAmount);
    function redeem(uint poolId, uint inAmount) external returns (uint outAmount);
    function calcMint(uint poolId, uint inAmount) external view returns(uint bBTC, uint fee);
    function calcRedeem(uint poolId, uint bBtc) external view returns(uint sett, uint fee, uint max);
    function portfolioValue() external view returns (uint);
}
