pragma solidity 0.5.16;

contract AddressChecker {
    function isContract(address _address) external view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}