// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract ZeroxyFactory is Context {
    
    function deployContract(bytes32 salt, bytes memory bytecode) public returns(address deployedAddress){
        assembly { // solhint-disable-line
          deployedAddress := create2(           // call CREATE2 with 4 arguments.
            0x0,                            // forward any attached value.
            add(0x20, bytecode),                         // pass in initialization code.
            mload(bytecode),                         // pass in init code's length.
            salt                                  // pass in the salt value.
          )
        }
        require(address(deployedAddress) != address(0), "deployContract call failed");
        return deployedAddress;
    }
    
    function addressLookup(uint256 initNonce, bytes32 initCodeHash ) external view returns (address deploymentAddress, bytes32 salt, uint256 nonce) {
        require(initNonce > 0, "initNonce must be > 0");
        require(initCodeHash.length > 0, "Invalid bytecode");
        uint256 existingContractSize;
        nonce = initNonce;
        while (true) {
            salt = _getSalt(nonce,_msgSender());
            // determine the address where the contract will be deployed.
            deploymentAddress = address(
              uint160(                      // downcast to match the address type.
                uint256(                    // convert to uint to truncate upper digits.
                  keccak256(                // compute the CREATE2 hash using 4 inputs.
                    abi.encodePacked(       // pack all inputs to the hash together.
                      bytes1(0xff),              // start with 0xff to distinguish from RLP.
                      address(this),        // this contract will be the caller.
                      salt,                 // pass in the supplied salt value.
                      initCodeHash          // pass in the hash of initialization code.
                    )
                  )
                )
              )
            );

            assembly { existingContractSize := extcodesize(deploymentAddress) }

          // Exit the loop if no contract is deployed to the target address.
          (uint256 leading,uint256 total) = _getZeroBytes(deploymentAddress);
          if(leading >= 3 && total >= 4 && existingContractSize == 0) {
              break;
          }
          nonce++;
        }
        return (deploymentAddress, salt, nonce);
  }
  function getCodehashFromBytecode(bytes memory bytecode)public pure returns(bytes32) {
     return keccak256(bytecode);
  }
  function _getZeroBytes(address account) internal pure returns (  uint256 leading,   uint256 total ) {
    // convert the address to bytes.
    bytes20 b = bytes20(account);

    // designate a flag that will be flipped once leading zero bytes are found.
    bool searchingForLeadingZeroBytes = true;

    // iterate through each byte of the address and count the zero bytes found.
    for (uint256 i; i < 20; i++) {
      if (b[i] == 0) {
        total++; // increment the total value if the byte is equal to 0x00.
      } else if (searchingForLeadingZeroBytes) {
        leading = i; // set leading byte value upon reaching a non-zero byte.
        searchingForLeadingZeroBytes = false; // stop search upon finding value.
      }
    }

    // special handling for the null address.
    if (total == 20) {
      leading = 20;
    }
  }
  function _getSalt(uint256 _nonce,address _sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, _sender));
    }
}