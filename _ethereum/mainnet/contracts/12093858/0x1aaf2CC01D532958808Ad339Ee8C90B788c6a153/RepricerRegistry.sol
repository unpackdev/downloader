// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import "./IRepricer.sol";
import "./AddressRegistryParent.sol";

contract RepricerRegistry is AddressRegistryParent {
    function generateKey(address _value) public override view returns(bytes32 _key){
        require(IRepricer(_value).isRepricer(), "Should be repricer");
        return keccak256(abi.encodePacked(IRepricer(_value).symbol()));
    }
}
