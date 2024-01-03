// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20MinterPauser.sol";
import "./IERC20.sol";


contract UpgradableCoin is ERC20MinterPauser {

    event TransferOut(address _source, string _destination, uint256 _amount);

    function initialize(address multisig) public initializer {
        ERC20MinterPauser.initialize("Wrapped ANATHA", "wANATHA");

        uint8 decimals = 18;

        _setupDecimals(decimals);

        uint256 _initialSupply = 300000000 * 10 ** uint256(decimals); // 300M

        _mint(multisig, _initialSupply);
    }

    function transferOut(string memory _destination, uint256 _amount) public {
        _burn(msg.sender, _amount);

        emit TransferOut(msg.sender, _destination, _amount);
    }
    
    function salvage(address token) external {

        uint256 balance = IERC20(token).balanceOf(address(this));
        
        require(
            IERC20(token).transfer(getRoleMember(DEFAULT_ADMIN_ROLE, 0), balance)
        );

    }

}