// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract HourBlastERC20 is ERC20, Ownable {
    address public hourblastContract;

    constructor(address _hourblastContract, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        if (_hourblastContract == address(0)) {
            revert CannotBeZero();
        }

        // set minter
        hourblastContract = _hourblastContract;
    }

    modifier onlyHourblast() {
        if (msg.sender != hourblastContract) {
            revert CallerNotMinter();
        }
        _;
    }

    function mint(address to, uint256 amount) public onlyHourblast {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyHourblast {
        _burn(from, amount);
    }

    function setHourblastContract(address _hourblastContract) public onlyOwner {
        if (_hourblastContract == address(0)) {
            revert CannotBeZero();
        }

        emit MinterUpdated(hourblastContract, _hourblastContract);

        // set new minter
        hourblastContract = _hourblastContract;
    }

    error CannotBeZero();
    error CallerNotMinter();

    event MinterUpdated(address previousMinter, address newMinter);
}
