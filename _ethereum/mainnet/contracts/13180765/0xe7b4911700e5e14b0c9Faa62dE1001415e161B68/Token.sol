// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
// pragma abicoder v2;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeMath.sol";

uint256 constant BASE = 1000000000000000000;

contract KombatCoin is ERC20("KombatCoin", "KMBC") {
    constructor(
        address _vestingContract,
        address _publicSale,
        address _launchpad,
        address _charity,
        address _bounty,
        address _marketing,
        address _exchangeListing,
        address _partnership
    ) {
        // mint for private sale with 1 years vesting
        _mint(_exchangeListing, 1250000000 * BASE);

        // mint for Public Sale
        _mint(_publicSale, 400000000 * BASE);

        // mint for private sale with 1 years vesting
        _mint(_vestingContract, 125000000 * BASE);

        // mint for private sale with 2 years vesting
        _mint(_vestingContract, 125000000 * BASE);

        // mint for Launchpad IEO 
        _mint(_launchpad, 100000000 * BASE);

        // mint for Partnership
        _mint(_partnership, 500000000 * BASE);

        // mint for Strategic Development
        _mint(_vestingContract, 500000000 * BASE);

        // mint for Founders
        _mint(_vestingContract, 500000000 * BASE);

        // mint for Core Team
        _mint(_vestingContract, 250000000 * BASE);

        // mint for Marketing 
        _mint(_marketing, 1000000000 * BASE);
    
        // mint for charity 
        _mint(_charity, 125000000 * BASE);
    
        // mint for bounty
        _mint(_bounty, 125000000 * BASE);
    }
}
