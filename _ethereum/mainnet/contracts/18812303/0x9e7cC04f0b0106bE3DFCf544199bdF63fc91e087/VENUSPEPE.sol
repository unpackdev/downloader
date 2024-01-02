// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract VENUSPEPE is ERC20, Ownable {

    constructor() ERC20("PEPE on VENUS", "$VENUSPEPE") 
	{	
        _mint(address(0x3765432dbbd40F2e5DE2EBB9A03fd6e31eCbf793), 875000000 * 10**18); // Live Trading
	    _mint(address(0x45473270E345446443021b6F64911ab5Fa858aB3), 250000000 * 10**18); // Airdrop Allocation
	    _mint(address(0xff36c49789b482d59bd6846C98785caDc17BBBd9), 625000000 * 10**18); // Liquidity Pool
	    _mint(address(0x7cFEBaf15436DfCC1466b8042D5D600768D18F7d), 500000000 * 10**18); // Marketing & Development
	    _mint(address(0xc3A63Feb26a340b55D992ac536783A83cE4b1e85), 125000000 * 10**18); // Charity Fund
	    _mint(address(0x0787Cd161a077a58277392CE64f64Ae885412A1F), 125000000 * 10**18); // Community Rewards
    }
}