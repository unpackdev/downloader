// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract VENUSPEPE is ERC20, Ownable {

	bool public tradingEnabled;
	mapping(address => bool) public isWhitelisted;
	
	event WalletWhitelisted(address wallet, bool value);
	event TradingEnabled(bool value);
	
    constructor() ERC20("PEPE on VENUS", "$VENUSPEPE") {	
	
       _mint(address(0x1e327cFF330A690BE5b785669d757E293Ed5AAF5), 875_00_00_000 * 10**18); // Presale Allocation
	   _mint(address(0x45473270E345446443021b6F64911ab5Fa858aB3), 250_00_00_000 * 10**18); // Airdrop Allocation
	   _mint(address(0xff36c49789b482d59bd6846C98785caDc17BBBd9), 625_00_00_000 * 10**18); // Liquidity Pool
	   _mint(address(0x7cFEBaf15436DfCC1466b8042D5D600768D18F7d), 500_00_00_000 * 10**18); // Marketing & Development
	   _mint(address(0xc3A63Feb26a340b55D992ac536783A83cE4b1e85), 125_00_00_000 * 10**18); // Charity Fund
	   _mint(address(0x0787Cd161a077a58277392CE64f64Ae885412A1F), 125_00_00_000 * 10**18); // Community Rewards
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {      
	   if(!tradingEnabled)
	   {
	      require(isWhitelisted[address(sender)], "Trading not started yet");
	   }
	   super._transfer(sender, recipient, amount);
    }
	
	function openTrading() external onlyOwner {
	   require(!tradingEnabled, "Trading already started");
	   
       tradingEnabled = true;
	   emit TradingEnabled(true);
    }
	
	function whitelistWallet(address wallet, bool status) external onlyOwner{
        require(wallet != address(0), "Zero address");
		
		isWhitelisted[wallet] = status;
        emit WalletWhitelisted(wallet, status);
    }
}