pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface IComptroller {
    struct CompMarketState {
        uint224 index;
        uint32 block;
    }

    function claimComp(address holder) external;
    function compSupplyState(address) external view returns (CompMarketState memory);
    function compSupplierIndex(address, address) external view returns (uint256);
    function compAccrued(address) external view returns (uint256);

}