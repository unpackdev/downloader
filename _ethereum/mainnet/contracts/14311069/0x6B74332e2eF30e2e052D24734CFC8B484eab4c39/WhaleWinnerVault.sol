// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <8.12.0;
import "./Ownable.sol";
/*


███╗░░░███╗░█████╗░██╗░░██╗███████╗  ░█████╗░  ░██╗░░░░░░░██╗██╗░░██╗░█████╗░██╗░░░░░███████╗  
████╗░████║██╔══██╗██║░██╔╝██╔════╝  ██╔══██╗  ░██║░░██╗░░██║██║░░██║██╔══██╗██║░░░░░██╔════╝  
██╔████╔██║███████║█████═╝░█████╗░░  ███████║  ░╚██╗████╗██╔╝███████║███████║██║░░░░░█████╗░░  
██║╚██╔╝██║██╔══██║██╔═██╗░██╔══╝░░  ██╔══██║  ░░████╔═████║░██╔══██║██╔══██║██║░░░░░██╔══╝░░  
██║░╚═╝░██║██║░░██║██║░╚██╗███████╗  ██║░░██║  ░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║███████╗███████╗  
╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ╚═╝░░╚═╝  ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝  

██╗░░░██╗░█████╗░██╗░░░██╗██╗░░░░░████████╗
██║░░░██║██╔══██╗██║░░░██║██║░░░░░╚══██╔══╝
╚██╗░██╔╝███████║██║░░░██║██║░░░░░░░░██║░░░
░╚████╔╝░██╔══██║██║░░░██║██║░░░░░░░░██║░░░
░░╚██╔╝░░██║░░██║╚██████╔╝███████╗░░░██║░░░
░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░╚══════╝░░░╚═╝░░░

@poseidonsnonce
makeawhale.com

*/


contract WhaleWinnerVault is Ownable{

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private _deposits;

  function depositsOf(address payee) public view returns (uint256) {
    return _deposits[payee];
  }

  /**
  * @dev Stores the sent amount as credit to be withdrawn.
  * @param payee The destination address of the funds.
  */
  function deposit(address payee) public payable onlyOwner {
    uint256 amount = msg.value;
    _deposits[payee] += amount;
    emit Deposited(payee, amount);
  }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address payable payee) public  {
    uint256 payment = _deposits[payee]; 
    require(payment > 0, "You have no balance in the vault");
    _deposits[payee] = 0;
    (bool success, ) = payee.call{value:payment}("");
    require(success, "Transfer failed.");
    emit Withdrawn(payee, payment);
  }




}

