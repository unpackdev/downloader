/*
https://avocadoguild.com/
Avocado Guild underline the value of inspiring positive impacts on people’s lives. Our mission to unlock the hidden talents of our guild members by empowering them with the education, encouragement, and digital instruments they need to achieve their full potential in the Metaverse.
*/

pragma solidity ^0.8.4;
import "./ERC20.sol";
import "./Ownable.sol";

contract AvocadoGuildToken is Ownable, ERC20 {
    constructor(string memory name_, string memory symbol_)
        Ownable()
        ERC20(name_, symbol_)
    {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
