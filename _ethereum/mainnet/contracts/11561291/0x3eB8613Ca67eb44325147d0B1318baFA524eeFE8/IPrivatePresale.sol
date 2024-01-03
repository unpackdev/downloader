pragma solidity >=0.6.6;

interface IPrivatePresale {
    function totalPrivatePresaleDistribution() external view returns (uint);
    function privatePresaleDistributed() external view returns (uint);
    function availablePrivatePresaleAmountOf(address account) external view returns (uint);

    function distribute(address[] calldata _accounts, uint[] calldata _amounts) external;
    function editDistributed(address _account, uint _amount) external;
    function privatePresaleClaim(uint amount) external;
    function startPrivatePresaleDistribution() external;
}   