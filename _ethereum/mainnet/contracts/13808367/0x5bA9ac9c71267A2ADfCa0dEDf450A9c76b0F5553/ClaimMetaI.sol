// SPDX-License-Identifier: MIT
/* ============================ MetaINDEX Initial Seed Claim =================================
                                https://metai.nftindex.tech/
 -------------------------------------- December 2021 ----------------------------------------
 ####     ####                             ######                ####                       
 ####    #####            ###             ######                 ####                       
 #####   #####   =====   ####    =====      ##    =====        ==####    =====   ===   ===   
######  ######  ####### ####### #######    ####  ########    ########   ####### ####  ####  
####### ###### ######### ######  #######   ####  #########  #########  ######### ########   
### ###### ### ###   ### ####      #####   ####  ###  ####  ###  #### ####   ###  ######    
### ###### ### ######### ####   ########   ####  ###  #### ####  #### ##########  #####     
###  ####  ### ###       ####   ###  ###   ####  ###  ####  ###  #### ####        ######    
###  ####  ### #########  ##### ########   ####  ###  ####  #########  ########  ### ####   
###  ####  ###  ########  ##### ########   ####  ###  ####   ########   ####### ####  ####  
                                                                                        
                 ######## ####        #####     ###   #####    ####                                                                                                                    
                ######### ####        ######    ###   #####   #####                                                                                                                    
               ####       ####        ######    ###   ######  #####                                                                                                                    
               ####       ####       ### ####   ###   ###### ######                                                                                                                    
               ###        ####       ###  ###   ###   ###### ######                                                                                                                    
               ####       ####      ##########  ###   ### ##### ####                                                                                                                   
               #####      ####      ##########  ###   ### ##### ####                                                                                                                   
                ######### ######## ####    ###  ###  #### ####   ###                                                                                                                   
                 ######## ####### ####      ### ###  ####  ###   ####                         
=========================================================================================== */                           

pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract ClaimMetaI is AccessControl
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	IERC20 public token;

	address public Creator = _msgSender();
	mapping (address => uint256) claimers;
	mapping (address => uint256) public Sended;
	uint256 public constant AmountUSDT = 1374402.410521 * 10**6;

	// total supply
	uint256 public Amount = 13854220204180822063973;
	address public TokenAddr = 0xeFC996CE8341cd36c55412B51DF5BBCa429a7617;

	uint256 persent100 = 10000000000000000;

	uint8 public ClaimCount;

	event textLog(address,uint256,uint256);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

	// 10**14 detail on https://github.com/nftindex-tech/metai/blob/main/var_for_sol.txt
	claimers[0x744ce174630F8A63C0aC161E222E44954bb9CE52] = 800347839598900;
	claimers[0xAd5C1d11317C2b94cD3688Fc692E19F3Ec4632DE] = 735526564462870;
	claimers[0x7DCA2F7da83C26FCeBC5B0562BA2F707ed8Fe00b] = 732951254980800;
	claimers[0x8ac51a5d5921Bf5640ddc6633f13FcD0d8e19be6] = 727588945089910;
	claimers[0xe28d49b487C9dd7054F4D9c74629a47079641747] = 509312261562940;
	claimers[0x7777515751843e7cdcC47E10833E159c47777777] = 363794472544950;
	claimers[0x617A60bC8d802E31e66fAd00526B783a510D4eB8] = 233556051373860;
	claimers[0xCfb7f0d9223C6684Ee105B9b7eFb3A221B2432d6] = 225552572977870;
	claimers[0xeF88b12D4816776C0f0F36d42cF668EDddf67d3E] = 218380769403790;
	claimers[0xf75b052036dB7d90D18C10C06d3535F0fc3A4b74] = 218283959416420;
	claimers[0x8595f8141E90fcf6Ee17C85142Fd03d3138A6198] = 218276683526970;
	claimers[0x93dF35071B3bc1B6d16D5f5F20fbB2be9D50FE67] = 189101154312930;
	claimers[0xa542e3CDd21841CcBcCA70017101eb6a2fc68723] = 181897236272480;
	claimers[0x6c4Cd639a31C658549824559ECC2d04BED1a9ab9] = 181897236272480;
	claimers[0xd79c0707083A92234F0ef5FD4Bfba3cd2b7bc81D] = 177677220390960;
	claimers[0xeE74a1e81B6C55e3D02D05D7CaE9FD6BCee0E651] = 174621346821580;
	claimers[0xf18210B928bc3CD75966329429131a7fD6D1b667] = 145886904348480;
	claimers[0xF33782f1384a931A3e66650c3741FCC279a838fC] = 145808824596020;
	claimers[0xE144E7e3948dCA4AD395794031A0289a83b150A0] = 145517861776880;
	claimers[0xf2f62B5C7B3395b0ACe219d1B91D8083f8394720] = 145517789017980;
	claimers[0x627Dbe3Eb5E9d6aaDAfc0642F06eF016ABc5EF60] = 145517789017980;
	claimers[0xdFA56E55811b6F9548F4cB876CC796a6A4071993] = 123690120665280;
	claimers[0x3A484fc4E7873Bd79D0B9B05ED6067A549eC9f49] = 115592055706430;
	claimers[0x9e0eD477f110cb75453181Cd4261D40Fa7396056] = 112776286488940;
	claimers[0x256b09f7Ae7d5fec8C8ac77184CA09F867BbBf4c] = 109138341763490;
	claimers[0x0b4d6032be01bF08610D35d219Cda708ce2687e1] = 109138341763490;
	claimers[0x667bA99128E89F23aB3F053973387f7456C72aC1] = 87674467883334;
	claimers[0xF6168297046Ca6fa514834c30168e63A47256AF4] = 87310673410789;
	claimers[0x61368A18346A0694A2d627A445Fdfa282f7d271D] = 80762372904980;
	claimers[0x0be82Fe1422d6D5cA74fd73A37a6C89636235B25] = 80034783959890;
	claimers[0x9B3F13C74f5Ae0437f9F5675449B42b4b84d0e3a] = 73521869480493;
	claimers[0x02A325603C41c24E1897C74840B5C78950223366] = 73486483454081;
	claimers[0xeDf32B8F98D464b9Eb29C74202e6Baae28134fC7] = 73486483454081;
	claimers[0x2220d8b0539CB4613A5112856a9B192b380be37f] = 73108137202634;
	claimers[0x21130c9b9D00BcB6cDAF24d0E85809cf96251F35] = 72991333369367;
	claimers[0xCf57A3b1C076838116731FDe404492D9d168747A] = 72948067634714;
	claimers[0x65BBA95Af97029e5ae3e01A10Cd4752966E058eF] = 72831653403500;
	claimers[0xf3143D244F33eb40252464d3b692FA519847B7a9] = 72762532453716;
	claimers[0x6Acb64A76e62D433a9bDCB4eeA8343Be8b3BeF48] = 72758894508991;
	claimers[0xDaac8766ef95E86D839768F7EFf7ed972CA30628] = 72758894508991;
	claimers[0x7AEBDD84821190c1cfCaCe051E87913ae5d67439] = 72758894508991;
	claimers[0xd50A9175FF32345270611378942490AD9355946B] = 72758894508991;
	claimers[0x239D5c0CfD4ED667ad78Cdc7F3DCB17D09740a0d] = 72758894508991;
	claimers[0x7F052861bf21f5208e7C0e30C9056a79E8314bA9] = 72758894508991;
	claimers[0x61b3c4c9dc16B686eD396319D48586f40c1F74E9] = 72758894508991;
	claimers[0xa2cF94Bf60B6a6C08488B756E6695d990574e9C7] = 72758894508991;
	claimers[0x64F8eF34aC5Dc26410f2A1A0e2b4641189040231] = 72758894508991;
	claimers[0x21c69AB0962FAbd811b1f376eF85F5CAE5317eb2] = 72758894508991;
	claimers[0x7AE29F334D7cb67b58df5aE2A19F360F1Fd3bE75] = 72758894508991;
	claimers[0x96C7fcC0d3426714Bf62c4B508A0fBADb7A9B692] = 72758894508991;
	claimers[0x44e02B37c29d3689d95Df1C87e6153CC7e2609AA] = 72758894508991;
	claimers[0x3cB704A5FB4428796b728DF7e4CbC67BCA1497Ae] = 72758894508991;
	claimers[0x35E3c412286d59Af71ba5836cE6017E416ACf8BC] = 72758894508991;
	claimers[0xA136A3AbC184Bf70De3614822b2A6E6D8Df018e5] = 72758894508991;
	claimers[0x77335205Eb73c00214BDb38B66BC353A892b9da7] = 72758894508991;
	claimers[0x125EaE40D9898610C926bb5fcEE9529D9ac885aF] = 72758894508991;
	claimers[0xff8994c6a99a44b708dEA64897De7E4DD0Fb3939] = 72758894508991;
	claimers[0xf6EA8168a1D1D5d36f22436ad2030d397a616619] = 72758894508991;
	claimers[0x355e03d40211cc6b6D18ce52278e91566fF29839] = 72758894508991;
	claimers[0x55E9762e2aa135584969DCd6A7d550A0FaadBcd6] = 72758894508991;
	claimers[0x710A169B822Bf51b8F8E6538c63deD200932BB29] = 72758894508991;
	claimers[0xb521154e8f8978f64567FE0FA7359Ab47f7363fA] = 72758894508991;
	claimers[0x90B251964554493d24b251d5c357b601aEb32eb9] = 72758894508991;
	claimers[0xFB81414570E338E28C98417c38A3A5c9C6503516] = 72758894508991;

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

	function TokenAmountSet(uint amount)public virtual onlyAdmin
	{
		Amount = amount;
	}

	function TokenAddrSet(address addr)public virtual onlyAdmin
	{
		TokenAddr = addr;
	}

	function ClaimCheckEnable(address addr)public view returns(bool)
	{
		bool status = false;
		if(claimers[addr] > 0)status = true;
		return status;
	}
	function ClaimCheckAmount(address addr)public view returns(uint)
	{
		uint value;
		value = Amount.mul(claimers[addr]);
		value = value.div(persent100);
		return value;
	}
	function Claim(address addr)public virtual
	{
		//address addr;
		//addr = _msgSender();
		require(TokenAddr != 0x0000000000000000000000000000000000000000,"Admin not set TokenAddr");



		bool status = false;
		if(claimers[addr] > 0)status = true;

		require(status,"Token has already been requested or Wallet is not in the whitelist [check: Sended and claimers]");
		uint256 SendAmount;
		SendAmount = ClaimCheckAmount(addr);
		if(Sended[addr] > 0)SendAmount = SendAmount.sub(Sended[addr]);
		Sended[addr] = SendAmount;
		claimers[addr] = 0;

		IERC20 ierc20Token = IERC20(TokenAddr);
		require(SendAmount <= ierc20Token.balanceOf(address(this)),"Not enough tokens to receive");
		ierc20Token.safeTransfer(addr, SendAmount);

		ClaimCount++;
		emit textLog(addr,SendAmount,claimers[addr]);
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
	function MetaiBalance()public view returns(uint256)
	{
	        IERC20 ierc20Token = IERC20(TokenAddr);
	        return ierc20Token.balanceOf(address(this));
	}

}