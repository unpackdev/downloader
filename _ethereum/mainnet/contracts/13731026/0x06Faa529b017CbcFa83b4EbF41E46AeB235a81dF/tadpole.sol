// contracts/tadpole.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Tadpole is ERC20 {
    address owner;
    address public pondAddress;
    address public frogGameAddress;

    // keep track of block where action was performed
    mapping(address => uint) callerToLastActionBlock;

    /// @dev Constructor
    constructor() ERC20("Tadpole", "TADPOLE") { 
        owner = msg.sender; 
    }

    /// @dev Mint amount of tokens to specified address
    function mintTo(address recepient, uint amount) external onlyPondAddress {
        _mint(recepient, amount);
    }
    
    /// @dev Set Pond contract address
    function setPondAddress(address _pondAddress) public onlyOwner {
        pondAddress = _pondAddress;
        return;
    }

    function setFrogGameAddress(address _frogGameAddress) public onlyOwner {
        frogGameAddress=_frogGameAddress;
        return;
    }

    function updateOriginActionBlockTime() external onlyPondAddress {
        callerToLastActionBlock[tx.origin]=block.number;
    }

    /// @dev Execute if called by Pond contract
    modifier onlyPondAddress() {
        require(pondAddress == msg.sender, "Can be called from Pond contract only");
        _;
    }

    /// @dev Execute if called by FrogGame contract
    modifier onlyFrogGameAddress() {
        require(frogGameAddress == msg.sender, "Can be called from FrogGame contract only");
        _;
    }

    /// @dev Execute if called by owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    /// @dev Don't allow view functions in same block as action that changed the state
    modifier noSameBlockAsAction() {
        require(callerToLastActionBlock[tx.origin] < block.number, "Please try again on next block");
        _;
    }

    function balanceOf(address _owner) public view virtual override(ERC20) noSameBlockAsAction returns (uint256) {
        require(callerToLastActionBlock[_owner] < block.number, "Please try again on next block");
        return super.balanceOf(_owner);
    }

    function burnFrom(address account, uint256 amount) external onlyFrogGameAddress {
        _burn(account, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}