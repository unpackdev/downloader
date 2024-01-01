// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IAdapter.sol";

contract AdapterFactory is Ownable {
    event NewAdapter(address indexed adapterAddress);

    constructor() {}

    function deployAdapter(
        bytes memory code,
        address _wrapper,
        address _vault,
        address _admin
    ) external onlyOwner returns(address _adapterAddress) {
        bytes32 salt = keccak256(abi.encodePacked(_wrapper, _vault));

        assembly {
            _adapterAddress := create2(0, add(code, 0x20), mload(code), salt)
        }

        IAdapter(_adapterAddress).initialize(_wrapper, _vault, _admin);

        emit NewAdapter(_adapterAddress);
    }
}