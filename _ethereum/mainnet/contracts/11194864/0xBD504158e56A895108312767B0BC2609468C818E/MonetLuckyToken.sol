pragma solidity =0.5.16;

import "./Minter.sol";
import "./MonetTokenERC20.sol";

contract MonetLuckyToken is MonetTokenERC20 , Minter{
    string public constant name = 'Monet Lucky';
    string public constant symbol = 'L-MNT';
    uint8 public constant decimals = 18;

    
    function mint(uint value) external onlyMinter returns (bool){
        _mint(msg.sender,value);
        return true;
    }
    
    function mintFrom(address from,uint value) external returns(bool){
        _mint(from,value);
        return true;
    }

    function burn(uint value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _burn(from, value);
        return true;
    }
}
