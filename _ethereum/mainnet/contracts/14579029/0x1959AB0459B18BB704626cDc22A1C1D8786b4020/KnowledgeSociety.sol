// SPDX-License-Identifier: MIT

/*

  $$\   $$\ $$\   $$\  $$$$$$\  $$\      $$\ $$\       $$$$$$$$\ $$$$$$$\   $$$$$$\  $$$$$$$$\ 
  $$ | $$  |$$$\  $$ |$$  __$$\ $$ | $\  $$ |$$ |      $$  _____|$$  __$$\ $$  __$$\ $$  _____|
  $$ |$$  / $$$$\ $$ |$$ /  $$ |$$ |$$$\ $$ |$$ |      $$ |      $$ |  $$ |$$ /  \__|$$ |      
  $$$$$  /  $$ $$\$$ |$$ |  $$ |$$ $$ $$\$$ |$$ |      $$$$$\    $$ |  $$ |$$ |$$$$\ $$$$$\    
  $$  $$<   $$ \$$$$ |$$ |  $$ |$$$$  _$$$$ |$$ |      $$  __|   $$ |  $$ |$$ |\_$$ |$$  __|   
  $$ |\$$\  $$ |\$$$ |$$ |  $$ |$$$  / \$$$ |$$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |      
  $$ | \$$\ $$ | \$$ | $$$$$$  |$$  /   \$$ |$$$$$$$$\ $$$$$$$$\ $$$$$$$  |\$$$$$$  |$$$$$$$$\ 
  \__|  \__|\__|  \__| \______/ \__/     \__|\________|\________|\_______/  \______/ \________|
                                                                                              
                                                                                              
                                                                                              
              $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\ $$\     $$\                        
              $$  __$$\ $$  __$$\ $$  __$$\ \_$$  _|$$  _____|\__$$  __|\$$\   $$  |                       
              $$ /  \__|$$ /  $$ |$$ /  \__|  $$ |  $$ |         $$ |    \$$\ $$  /                        
              \$$$$$$\  $$ |  $$ |$$ |        $$ |  $$$$$\       $$ |     \$$$$  /                         
               \____$$\ $$ |  $$ |$$ |        $$ |  $$  __|      $$ |      \$$  /                          
              $$\   $$ |$$ |  $$ |$$ |  $$\   $$ |  $$ |         $$ |       $$ |                           
              \$$$$$$  | $$$$$$  |\$$$$$$  |$$$$$$\ $$$$$$$$\    $$ |       $$ |                           
               \______/  \______/  \______/ \______|\________|   \__|       \__|                        

*/

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract KnowledgeSocietyCoin is ERC20("Knowledge Society Coin", "KS"), Ownable {

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}