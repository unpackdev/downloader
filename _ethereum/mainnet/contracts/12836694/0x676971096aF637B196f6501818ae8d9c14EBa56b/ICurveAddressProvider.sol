// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ICurveAddressProvider {

    function get_registry() external view returns(address);
    function get_address(uint256 id) external view returns(address);
    function get_id_info(uint256 id) external view returns(address targetAddr, bool isSet, uint256 verNum, uint256 lastModifiedTime, string memory description);
    function max_id() external view returns(uint256);


}