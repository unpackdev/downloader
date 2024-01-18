// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract TwitFi is ERC20, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    uint8 private constant _decimals = 9;

    constructor (string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
         _mint(msg.sender, _initialSupply);
    }

    function decimals() public override pure returns (uint8) {
        return _decimals;
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = payable(owner()).call {
            value: amount
        }("");

        require(success, "Failed to send Ether");
    }

    receive() external payable {}
}
