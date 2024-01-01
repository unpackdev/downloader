//SPDX-License-Identifier: MIT




pragma solidity 0.8.9;



/**
 * @dev Collection of functions related to the address type
 */

contract P2EGameContractV1 {
    address public TokenAdr = 0x74EBd915BA8b7C85aeB5dED74306cf255eA403D7;
   
   

    address public ceoAddress = 0xd930F9AE8FB1616C372A9e875b0bc4e452f28F1B;
    address public smartContractAddress;

    mapping(address => uint256) public playerToken;
    



 
    constructor() {
        smartContractAddress = address(this);
      
    }
 
   

   

       function setToken(address _adr, uint256 amount) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        playerToken[_adr] = amount;
    }
   
       

    
function depositToken(uint256 amount) public  {
      
        ERC20(TokenAdr).transferFrom(msg.sender, smartContractAddress, amount);
    }




    function changeSmartContract(address smartContract) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        smartContractAddress = smartContract;
    }


    
    function withdrawToken(uint256 amount) public {
        require(
            playerToken[msg.sender] >= amount,
            "Cannot Withdraw more then your Balance!!"
        );

        address account = msg.sender;

      

        

        ERC20(TokenAdr).transfer(account, amount);

        playerToken[msg.sender] = 0;
    }
    function changeCeo(address _adr) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");

        ceoAddress = _adr;
    }

 function emergencyWithdraw() public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }
     function emergencyWithdrawToken(address _adr) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        ERC20(_adr).transfer(ceoAddress, ERC20(_adr).balanceOf(address(this)));
    } 
 

    
}
interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}