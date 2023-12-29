// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.1;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IIQERC20.sol";
import "./IMinter.sol";

contract IQERC20 is IIQERC20, ERC20, Ownable {
    IMinter private _minter;

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Everipedia IQ", "IQ") {}

    modifier ownerOrMinter {
        require(
            (address(_minter) != address(0) && msg.sender == address(_minter)) || msg.sender == owner(),
            "You are not owner or minter"
        );
        _;
    }

    function minter() external view override returns (address) {
        return address(_minter);
    }

    function mint(address _addr, uint256 _amount) external override ownerOrMinter {
        _mint(_addr, _amount);
    }

    function burn(address _addr, uint256 _amount) external override ownerOrMinter {
        _burn(_addr, _amount);
    }

    function setMinter(IMinter _addr) external override onlyOwner {
        _minter = _addr;
    }
}
