pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./console.sol";

// import "./Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {
    bytes32 public commit;
    string public secret;

    function getHash(string memory _input) public pure returns (bytes32) {
        return keccak256(abi.encode(_input));
    }

    function setCommit(bytes32 _hash) public {
        require(commit == 0, "Already committed!");
        commit = _hash;
    }

    function reveal(string memory _input) public {
        bytes32 _hash = getHash(_input);
        require(_hash == commit, "Incorrect secret!");
        secret = _input;
    }
}
