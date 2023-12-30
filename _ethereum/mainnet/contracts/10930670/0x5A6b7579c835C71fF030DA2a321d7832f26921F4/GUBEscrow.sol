pragma solidity >=0.4.22 <0.6.0;

contract GUBEscrow{
   enum State {INIT,ACTIVE,COMPLETED}
   State public state;
   address payable _gubAddy;
   uint public contractBalance;
   uint public numberOfBets;
   string[] public BetIDRec;
   
   struct Players{
       uint _playerid;
       uint _amount;
       uint _winnerid;
       address payable _playerAddress;
   }
   
   struct Winners{
       uint _playerid;
       address payable _winnerAddress;
   }
   struct Bet{
       uint pot;
       uint serviceFee;
       uint splitPot;
       uint betterCount;
       uint winnerCount;
       bool isactive;
   }
   
   mapping (string => Bet) public bets;
   mapping (string => Players[]) public wagers;
   mapping (string => Winners[]) public winners;
   
   constructor(address payable _gub) public{
       _gubAddy = _gub;
       state = State.INIT;
   }
   
   function collectWagers(string memory _betid, uint _playerid, uint _winnerid) public payable {
       require(_gubAddy != msg.sender, "Funds cannot be sent from originating wallet");
       require(_playerid > 0, "You must submit a valid GU Playerid");
       require(_winnerid > 0, "You must submit a valid GU Playerid");
       require(msg.value > 0);
       bytes memory isEmpty = bytes(_betid);
       require(isEmpty.length > 0, "You need a betid");
       if(wagers[_betid].length != 0){
           for (uint i=0; i<= wagers[_betid].length - 1; i ++){
             require(_playerid != wagers[_betid][i]._playerid ,"You can only send one wager per bet.");
             require(msg.sender != wagers[_betid][i]._playerAddress, "You can only send one wager per bet.");
            }
       }
       if(bets[_betid].isactive == false){
           BetIDRec.push(_betid);
           numberOfBets ++;
       }
       else{
           require(msg.value >= bets[_betid].pot / bets[_betid].betterCount);
       }
      
       bets[_betid] = Bet(
           bets[_betid].pot + msg.value,
           bets[_betid].serviceFee,
           bets[_betid].splitPot,
           wagers[_betid].length + 1,
           bets[_betid].winnerCount,
           bets[_betid].isactive = true
           );
        wagers[_betid].push(Players(_playerid, msg.value, _winnerid, msg.sender));
        contractBalance = address(this).balance;
        state = State.ACTIVE;
   } 

   function parseWinnersandPayout(string memory _betid, uint _winner) public {
       require(_gubAddy == msg.sender, "Sender not Authorized");
       bytes memory isEmpty = bytes(_betid);
       require(isEmpty.length >0, "BetID required");
       require(_winner > 0, "winnerid required");
       for(uint i = 0; i <= wagers[_betid].length - 1; i ++){
           if(wagers[_betid][i]._winnerid == _winner){
                winners[_betid].push(Winners(wagers[_betid][i]._playerid, wagers[_betid][i]._playerAddress));
           }
       }
       bets[_betid].winnerCount = winners[_betid].length;
       contractBalance = address(this).balance;
       bets[_betid].serviceFee = bets[_betid].pot * 7/100;
       bets[_betid].pot = bets[_betid].pot - bets[_betid].serviceFee;
       bets[_betid].splitPot = (bets[_betid].pot) / bets[_betid].winnerCount;
       _gubAddy.transfer(bets[_betid].serviceFee);
       for(uint i = 0; i <= winners[_betid].length-1; i++){
           winners[_betid][i]._winnerAddress.transfer(bets[_betid].splitPot);
       }
       delete bets[_betid];
       delete wagers[_betid];
       delete winners[_betid];
       if(BetIDRec.length <= 1){
           if(keccak256(abi.encodePacked(_betid)) == keccak256(abi.encodePacked(BetIDRec[0]))){
               delete BetIDRec[0];
               BetIDRec.length--;
           }
       }
       else{
        for(uint i = 0; i <= BetIDRec.length-1; i++){
           if(keccak256(abi.encodePacked(_betid)) == keccak256(abi.encodePacked(BetIDRec[i]))){
               delete BetIDRec[i];
               string memory moveID = BetIDRec[BetIDRec.length-1];
               BetIDRec[i] = moveID;
               BetIDRec.length--;
           }
        }
       }
       numberOfBets--;
   }
   

  
   
   function refundPlayer(string memory _betid, uint _playerid) public payable{
       require(_gubAddy == msg.sender, "Sender not Authorized");
       uint serviceFee;
       for(uint i = 0; i <= wagers[_betid].length-1; i++){
          if(wagers[_betid][i]._playerid == _playerid){
              if(i == 0 || i == 1){
                for(uint j = 0; j <= wagers[_betid].length-1; j++){
                    serviceFee = (wagers[_betid][j]._amount * 7) / 100;
                    _gubAddy.transfer(serviceFee);
                    wagers[_betid][j]._amount = wagers[_betid][j]._amount - serviceFee;
                    wagers[_betid][j]._playerAddress.transfer(wagers[_betid][j]._amount);
                }  
                contractBalance = address(this).balance;
                delete bets[_betid];
                delete wagers[_betid];
                delete winners[_betid];
                if(BetIDRec.length <= 1){
                    if(keccak256(abi.encodePacked(_betid)) == keccak256(abi.encodePacked(BetIDRec[0]))){
                        delete BetIDRec[0];
                        BetIDRec.length--;
                    }
                }
                else{
                    for(uint x = 0; x <= BetIDRec.length-1; x++){
                        if(keccak256(abi.encodePacked(_betid)) == keccak256(abi.encodePacked(BetIDRec[x]))){
                            delete BetIDRec[x];
                            string memory moveID = BetIDRec[BetIDRec.length-1];
                            BetIDRec[x] = moveID;
                            BetIDRec.length--;
                        }
                    }
                }
                numberOfBets--;
                return;
              }
              serviceFee = (wagers[_betid][i]._amount * 7) / 100;
              _gubAddy.transfer(serviceFee);
              wagers[_betid][i]._amount = wagers[_betid][i]._amount - serviceFee;
              wagers[_betid][i]._playerAddress.transfer(wagers[_betid][i]._amount);
              bets[_betid].pot = bets[_betid].pot - wagers[_betid][i]._amount;
              bets[_betid].betterCount = bets[_betid].betterCount - 1;
              contractBalance = address(this).balance;
              delete wagers[_betid][i];
              Players memory moveItem = wagers[_betid][wagers[_betid].length -1];
              wagers[_betid][i] = moveItem;
              wagers[_betid].length--;
          }
       }
   }
   
   
}