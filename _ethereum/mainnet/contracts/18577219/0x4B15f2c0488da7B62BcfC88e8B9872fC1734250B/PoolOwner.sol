// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;

import "Ownable.sol";
import "Address.sol";
import "EnumerableSet.sol";

contract PoolOwner is Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event FeeManagerAdded(address indexed manager);
    event FeeManagerRemoved(address indexed manager);

    bytes4 internal constant _SET_SWAP_FEE_SELECTOR = bytes4(keccak256("setSwapFeePercentage(uint256)"));

    EnumerableSet.AddressSet internal _feeManagers;

    function addSwapFeeManager(address _manager) external onlyOwner {
        _feeManagers.add(_manager);
        emit FeeManagerAdded(_manager);
    }

    function removeSwapFeeManager(address _manager) external onlyOwner {
        _feeManagers.remove(_manager);
        emit FeeManagerRemoved(_manager);
    }

    function listFeeManagers() external view returns (address[] memory) {
        uint256 length = _feeManagers.length();
        address[] memory managers = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            managers[i] = _feeManagers.at(i);
        }
        return managers;
    }

    function executeAction(address target, bytes calldata data) external returns (bytes memory) {
        bytes4 selector = _getSelector(data);
        if (selector == _SET_SWAP_FEE_SELECTOR) {
            require(msg.sender == owner() || _feeManagers.contains(msg.sender), "PoolOwner: not owner or fee manager");
        } else {
            require(msg.sender == owner(), "PoolOwner: not owner");
        }
        return target.functionCall(data);
    }

    function _getSelector(bytes memory _calldata) internal pure returns (bytes4 out) {
        assembly {
            out := and(mload(add(_calldata, 32)), 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
    }
}
