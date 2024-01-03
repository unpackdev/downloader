pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Morotz - the third time is the charm!
 */
contract Morotz {

    uint public pot;
    address public winner;
    address[] participants;
    
    receive() external payable {
        require(msg.value == 0.05 ether, 'Send 0.05 ETH to participate.');
        
        participants.push(msg.sender);
        pot += msg.value;
        
        if(participants.length >= 3) {
            pickWinnerAndPayout();
        }
    }
    
    function pickWinnerAndPayout() private {
        uint winnerIndex = getWinnerIndex();
        winner = participants[winnerIndex];
        bool payOutSuccess = payable(winner).send(pot);
        
        if(payOutSuccess) {
            pot = 0;
            delete participants;
        }
   }
   
   function getWinnerIndex() private view returns (uint) {
        uint no = uint(keccak256(abi.encodePacked(blockhash(block.number - 1))));
        return no % participants.length;
    }
}