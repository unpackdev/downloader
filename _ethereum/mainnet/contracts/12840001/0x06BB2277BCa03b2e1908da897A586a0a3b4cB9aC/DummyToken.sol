pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ERC20.sol";
import "./Ownable.sol";



/**
    *@title DummyToken contract
    * @dev It is deployed only when the Migrate function is called. 
    *  Owner of DummyToken contract is MIgrator contract.
**/
contract DummyToken is ERC20("Dummy.Token", "DMT"), Ownable {

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0), "ERC20: only minting!");
    }
}
