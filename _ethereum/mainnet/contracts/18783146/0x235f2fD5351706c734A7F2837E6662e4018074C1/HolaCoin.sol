// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Math.sol";

struct TokenDistribution {
    address holder;
    uint256 ratio;
}

contract HolaCoin is ERC20, ERC20Burnable, Ownable {
    using Math for uint256;

    uint256 public constant DENOMINATOR = 1e18;

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply,
        TokenDistribution[] memory initialDistribution
    ) ERC20(name, symbol) {
        _transferOwnership(initialOwner);

        // mint to initial distribution
        uint256 totalDistributed;

        for (uint256 i = 0; i < initialDistribution.length; i++) {
            uint256 amount = initialSupply.mulDiv(
                initialDistribution[i].ratio,
                DENOMINATOR
            );

            _mint(initialDistribution[i].holder, amount);

            totalDistributed += amount;
        }

        require(
            totalDistributed <= initialSupply,
            "HolaCoin: Total minted exceeds initial supply"
        );

        if (totalDistributed < initialSupply) {
            uint256 remaining = initialSupply - totalDistributed;
            _mint(initialOwner, remaining);
        }
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function mintTo(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual override onlyOwner {
        super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override onlyOwner {
        super.burnFrom(account, amount);
    }
}
