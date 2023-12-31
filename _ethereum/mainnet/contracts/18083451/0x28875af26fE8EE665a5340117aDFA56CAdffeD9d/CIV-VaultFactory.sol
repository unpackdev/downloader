// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact info@civfund.org
contract CIVFundShare is ERC20, Ownable {
    constructor(address _owner) ERC20("CIVFundShare", "XCIV") {
        _transferOwnership(_owner);
    }

    function mint(uint _amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), _amount);
        return true;
    }

    function burn(uint _amount) public returns (bool) {
        _burn(_msgSender(), _amount);
        return true;
    }
}

contract CIVFundShareFactory {
    function createCIVFundShare() public returns (CIVFundShare) {
        CIVFundShare fundRepresentToken = new CIVFundShare(msg.sender);
        return fundRepresentToken;
    }
}
