// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC165Storage.sol";

import "./IMintableOwnedERC20.sol";
import "./IProject.sol";


contract CommonGoodProjectToken is IMintableOwnedERC20, ERC20Burnable, ERC165Storage, Pausable, Ownable {

    IProject public project;


    modifier onlyOwnerOrProjectTeam() {
        require( msg.sender == owner() || msg.sender == project.getTeamWallet(), "token owner or team");
        _;
    }
    //---

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _registerInterface(type( IMintableOwnedERC20).interfaceId);
    }

    function performInitialMint( uint initialTokenSupply) external override onlyOwner { //@PUBFUNC @gilad
        mint( owner()/*tokenOwner*/, initialTokenSupply);
    }

    function setConnectedProject( IProject project_) external onlyOwner {  //@PUBFUNC
        project =  project_;
    }

    function pause() public onlyOwnerOrProjectTeam { //@PUBFUNC
        _pause();
    }

    function unpause() public onlyOwnerOrProjectTeam { //@PUBFUNC
        _unpause();
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function changeOwnership( address dest) external override { //@PUBFUNC
        return transferOwnership(dest);
    }

    function mint(address to, uint256 amount) public override onlyOwner { //@PUBFUNC
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

}
