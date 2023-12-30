pragma solidity >=0.4.22 <0.7.0;
contract TrainDefi{
    function setMoney() public payable {}
    function TakeMoney() public{
        if(msg.sender == 0xA7258EC040748652576Ffb447B228272B87AdE4a ){
            msg.sender.transfer(address(this).balance);
        }
    }
}