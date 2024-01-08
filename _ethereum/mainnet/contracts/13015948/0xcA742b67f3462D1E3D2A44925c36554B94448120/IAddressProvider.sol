pragma solidity >=0.5.0 <0.7.0;

interface IAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256) external view returns (address);
}
