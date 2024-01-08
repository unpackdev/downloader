// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";

contract OP20 is ERC20 {

    address public immutable opeth;
    address public immutable oToken;

    modifier onlyOpeth() {
        require(msg.sender == opeth);
        _;
    }

    constructor (address _oToken, string memory _name, string memory _symbol)
        public
        ERC20(_name, _symbol)
    {
        _setupDecimals(8);
        opeth = msg.sender;
        oToken = _oToken;
    }

    function mint(address account, uint256 amount) external onlyOpeth {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOpeth {
        _burn(account, amount);
    }
}
