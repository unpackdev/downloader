// contracts/ClaimFatmenDAF.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* ===============================================================
              https://fatmen-airdrop.dartflex.art/
------------------------------------------------------------------

      #######   ###    ###########     ## ####### ##   ####   
       #    #    ###   #   #   # ##   ##   #    #  ##    #    
       ####     ## ##      #     ### ###   ####    # #   #    
       ####     #   #      #     # # # #   ####    # ##  #    
       #       #######     #     #  #  #   #       #   # #    
       #       #     #     #     #  #  #   #    #  #   ###    
      ####    ###   ###  #####  ###   ### ####### ####   #    

   ###      #####   #######  ######   #######   #####   ####### 
    ###       #      #    #   #   ##   #    #  ##   ##   #    # 
   ## ##      #      #    #   #    #   #    #  #     #   #    # 
   #   #      #      ######   #    #   ######  #     #   ###### 
  #######     #      #  ##    #    #   #  ##   #     #   #      
  #     #     #      #   ##   #   ##   #   ##  ##   ##   #      
 ###   ###  #####   ###   ## #####    ###   ##   ###    ####    

=============================================================== */

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract ClaimFatmenDAF is AccessControl
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	IERC20 public token;
	

	uint public constant DafForFatmen = 50;
	address public Creator = _msgSender();
	mapping (address => uint256) public Sended;

	address public TokenAddr = 0x255d578049b0Cc729dceC2F12Fa59867Eb0eCECB;
	address public FatmenContract = 0xEae1d1c686005a5A8510683c34D6BB2455988282;

	uint8 public ClaimCount;

	event textLog(address,uint256);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		// claimers arrays detailed view on https://github.com/dArtFlex/fatmen-airdrop/blob/main/fatmen_nft_address_list.sol
		// Because the gas is very large, then we will take the data directly from the Fatmen's contract
		// https://etherscan.io/address/0xeae1d1c686005a5a8510683c34d6bb2455988282
	}


	// Start: Admin functions
	event adminModify(string txt, address addr);
	modifier onlyAdmin() 
	{
		require(IsAdmin(_msgSender()), "Access for Admin's only");
		_;
	}

	function IsAdmin(address account) public virtual view returns (bool)
	{
		return hasRole(DEFAULT_ADMIN_ROLE, account);
	}
	function AdminAdd(address account) public virtual onlyAdmin
	{
		require(!IsAdmin(account),'Account already ADMIN');
		grantRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin added',account);
	}
	function AdminDel(address account) public virtual onlyAdmin
	{
		require(IsAdmin(account),'Account not ADMIN');
		require(_msgSender()!=account,'You can`t remove yourself');
		revokeRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin deleted',account);
	}
	// End: Admin functions

	function TokenAddrSet(address addr)public virtual onlyAdmin
	{
		TokenAddr = addr;
	}
	function FatmenAddrSet(address addr)public virtual onlyAdmin
	{
		FatmenContract = addr;
	}

	function ClaimCheckEnable(address addr)public view returns(bool)
	{
		uint256 val;
		IERC20 ierc20Token = IERC20(FatmenContract);
		val = ierc20Token.balanceOf(addr);
		bool status = false;
		if(val > 0)status = true;
		return status;
	}
	function ClaimCheckAmount(address addr)public view returns(uint)
	{
		uint value;
		uint256 val;
		IERC20 ierc20Token = IERC20(FatmenContract);
		val = ierc20Token.balanceOf(addr);
		
		value = DafForFatmen.mul(val);
		return value;
	}
	function Claim(address addr)public virtual
	{
		require(TokenAddr != 0x0000000000000000000000000000000000000000,"Admin not set TokenAddr");

		require(ClaimCheckEnable(addr),"Wallet is not in the whitelist");
		require(Sended[addr]==0,"Token has already been requested");
		uint256 SendAmount;
		SendAmount = ClaimCheckAmount(addr);
		SendAmount = SendAmount.mul(10**18);
		if(Sended[addr] > 0)SendAmount = SendAmount.sub(Sended[addr]);
		Sended[addr] = SendAmount;

		IERC20 ierc20Token = IERC20(TokenAddr);
		require(SendAmount <= ierc20Token.balanceOf(address(this)),"Not enough tokens to receive");
		ierc20Token.safeTransfer(addr, SendAmount);

		ClaimCount++;
		emit textLog(addr,SendAmount);
	}
	
	function AdminGetCoin(uint256 amount) public onlyAdmin
	{
		payable(_msgSender()).transfer(amount);
	}

	function AdminGetToken(address tokenAddress, uint256 amount) public onlyAdmin 
	{
		IERC20 ierc20Token = IERC20(tokenAddress);
		ierc20Token.safeTransfer(_msgSender(), amount);
	}
	function TokenBalance()public view returns(uint256)
	{
	        IERC20 ierc20Token = IERC20(TokenAddr);
	        return ierc20Token.balanceOf(address(this));
	}

}