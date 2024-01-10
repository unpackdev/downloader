// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./SafeMath.sol";

contract veToken is ERC20 {
    using SafeMath for uint256;

    address public operator;

    uint256 public constant maxSupply = 100 * 1000000 * 1e18; //100mil

    constructor() ERC20("veToken Finance", "VE3D") {
        operator = msg.sender;
    }

    function setOperator(address _operator) external {
        require(msg.sender == operator, "!auth");
        operator = _operator;
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        require(totalSupply().add(_amount) < maxSupply, "Exceeed max supply!");

        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");

        _burn(_from, _amount);
    }
}
