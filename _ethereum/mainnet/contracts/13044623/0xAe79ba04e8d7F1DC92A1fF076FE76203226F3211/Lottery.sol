// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./IRandomNumberGenerator.sol";


contract Lottery is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IRandomNumberGenerator internal randomGenerator_;

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }


    bool public randomGenerated;
    string public mappingForDuctTape = "Pizza";
    string public mappingForStitched = "Beard";
    bytes32 public requestId_;

    event RandomGenerated (uint256 randomNumber);
    
    constructor (address _IRandomNumberGenerator) public {
        randomGenerator_ = IRandomNumberGenerator(_IRandomNumberGenerator);
    }

    function getRandomNumberFromChainlink(
        uint256 _seed
    ) 
        external 
        onlyOwner() 
    {
        require(!randomGenerated, "random number already generated");
        requestId_ = randomGenerator_.getRandomNumber(_seed);
    }

    function numbersDrawn(
        bytes32 _requestId, 
        uint256 _randomNumber
    ) 
        external
        onlyRandomGenerator()
    {
        if(requestId_ == _requestId) {
            if(_randomNumber.mod(2) == 1) {
                mappingForDuctTape = "Pizza";
                mappingForStitched = "Beard";
            } else {
                mappingForDuctTape = "Beard";
                mappingForStitched = "Pizza";
            }
            randomGenerated = true;
            emit RandomGenerated(_randomNumber);
        }
    }
}
