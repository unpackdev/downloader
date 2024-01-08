// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./Errors.sol";

contract SwishToken is AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply = 100 * 1000000 * 1e18; // 100M
    uint256 public totalCliffs = 1000;
    uint256 public reductionPerCliff;

    constructor() ERC20("Swish Token", "BENT") {
        reductionPerCliff = maxSupply / totalCliffs;

        _mint(msg.sender, 50 * 1000000 * 1e18); // mint 50M

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address _to, uint256 _amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), Errors.UNAUTHORIZED);

        uint256 supply = totalSupply();

        //use current supply to gauge cliff
        //this will cause a bit of overflow into the next cliff range
        //but should be within reasonable levels.
        //requires a max supply check though
        uint256 cliff = supply / reductionPerCliff;
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            _amount = (_amount * reduction) / totalCliffs;

            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }

            //mint
            _mint(_to, _amount);
        }
    }
}
