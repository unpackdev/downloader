
pragma solidity ^0.8.0;

interface IValidator {
    
    function verify(
        address _signer,
        address _receiver,
        string memory message,
        bytes memory _sig
    ) external pure returns (bool);
    
}