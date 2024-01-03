pragma solidity ^0.4.24;

//Original contract at https://github.com/chiro-hiro/thedivine 

contract TheDivineV2{

    /* the random variable */
    bytes32 randomValue;

    /* Address nonce */
    mapping (address => uint256) internal nonce;

    /* Event */
    event NewRand(address _sender, uint256 _complex, bytes32 _randomValue);
       
    /**
    * Construct function
    */
    constructor() public {
        randomValue = keccak256(abi.encode(this));
    }
    
    /**
    * Get result from PRNG
    */
    function getRandomNumber() public returns(bytes32 result){
        uint256 complex = (nonce[msg.sender] % 11) + 10;
        result = keccak256(abi.encode(randomValue, nonce[msg.sender]++));
        // Calculate digest by complex times
        for(uint256 c = 0; c < complex; c++){
            result = keccak256(abi.encode(result));
        }
        //Update new immotal result
        randomValue = result;
        emit NewRand(msg.sender, complex, result);
        return;
    }

    /**
    * No Ethereum will be trapped
    */
    function () public payable {
        msg.sender.transfer(msg.value);
    }
    
}