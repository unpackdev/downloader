// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Context.sol";

abstract contract EIP712Listable is Context, Ownable {
    using ECDSA for bytes32;

    address internal sigKey = address(0);

    bytes32 internal DOM_SEP;    

    uint256 chainid = 1;

    function setDomainSeparator(string memory _name, string memory _version) internal {
        DOM_SEP = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainid,
                address(this)
            )
        );
    }

    function getSigKey() public view returns (address) {
        return sigKey;
    }

    function setSigKey(address _sigKey) public onlyOwner {
        sigKey = _sigKey;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }
  
}