// SPDX-License-Identifier: MIT
/* =================================================== DEFI HUNTERS DAO ===========================================================
	                                        https://defihuntersdao.club/
------------------------------------------------------- February 2021 -------------------------------------------------------------
                                                                        (NN)  NNN
 NNNNNNNNL     NNNNNNNNL       .NNNN.      .NNNNNNN.          .NNNN.    (NN)  NNN
 NNNNNNNNNN.   NNNNNNNNNN.     JNNNN)     JNNNNNNNNNL         JNNNN)    (NN)  NNN                                  JNN
 NNN    4NNN   NNN    4NNN     NNNNNN    (NNN`   `NNN)        NNNNNN    (NN)  NNN     ____.       ____.  .____.    NNN       ___.
 NNN     NNN)  NNN     NNN)   (NN)4NN)   NNN)     (NNN       (NN)4NN)   (NN)  NNN   JNNNNNNN.   JNNNNN) (NNNNNNL (NNNNNN)  NNNNNNN.
 NNN     4NN)  NNN     4NN)   NNN (NNN   NNN`     `NNN       NNN (NNN   (NN)  NNN  (NNN""4NNN. NNNN"""` `F" `NNN)`NNNNNN) JNNF 4NNL
 NNN     JNN)  NNN     JNN)  (NNF  NNN)  NNN       NNN      (NNF  NNN)  (NN)  NNN  NNN)   4NN)(NNN       .JNNNNN)  NNN   (NNN___NNN
 NNN     NNN)  NNN     NNN)  JNNNNNNNNL  NNN)     (NNN      JNNNNNNNNL  (NN)  NNN  NNN    (NN)(NN)      JNNNNNNN)  NNN   (NNNNNNNNN
 NNN    JNNN   NNN    JNNN  .NNNNNNNNNN  4NNN     NNNF     .NNNNNNNNNN  (NN)  NNN  NNN)   JNN)(NNN     (NNN  (NN)  NNN   (NNN 
 NNN___NNNN`   NNN___NNNN`  (NNF    NNN)  NNNNL_JNNNN      (NNF    NNN) (NN)  NNN  (NNN__JNNN  NNNN___.(NNN__NNN)  NNNL_. NNNN____.
 NNNNNNNNN`    NNNNNNNNN`   NNN`    (NNN   4NNNNNNNF       NNN`    (NNN (NN)  NNN   4NNNNNNN`  `NNNNNN) NNNNNNNN)  (NNNN) `NNNNNNN)
 """"""`       """"""`      """      """     """""         """      """  ""   ""`     """"`      `""""`  `""` ""`   `"""`    """"`
--------------------------------------------------------------------------------------------------------------------------------*/
pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface IToken
{
        function approve(address spender,uint256 amount)external;
        function allowance(address owner,address spender)external view returns(uint256);
        function balanceOf(address addr)external view returns(uint256);
        function decimals() external view  returns (uint8);
        function name() external view  returns (string memory);
        function symbol() external view  returns (string memory);
        function totalSupply() external view  returns (uint256);
}

contract DDAOallocV02 is AccessControl, Ownable
{
        using SafeERC20 for IERC20;
        using SafeMath for uint256;

	event DDAOSale(uint256 id,bool enabled,string name,address vault,uint256 min1,uint256 min2,uint256 min3,address[] tokens);
	event DDAOAllocate(uint256 number,address payer,address addr, uint256 sale,uint256 level,uint256 amount,uint256 amount_human);

	struct saleStruct
	{
		uint256 id;
		bool enabled;
		string name;
		address vault;
		mapping(uint8 => uint256)min;
		address[] tokens;
	}
	mapping(uint256 => saleStruct)public Sale;
    	uint256 public AllocCount = 0;
	mapping (uint256 => uint256) public AllocSaleCount;
	mapping (uint256 => uint256) public AllocSaleAmount;
	mapping (uint256 => mapping(uint256 => uint256)) public AllocSaleLevelCount;
	mapping (uint256 => mapping(uint256 => uint256)) public AllocSaleLevelAmount;


	struct info
	{
		address addr;
		uint8 decimals;
		string name;
		string symbol;
		uint256 totalSupply;
	}
        constructor()
        {
        	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		_setupRole(DEFAULT_ADMIN_ROLE, 0x208b02f98d36983982eA9c0cdC6B3208e0f198A3);
		_setupRole(DEFAULT_ADMIN_ROLE, 0x80C01D52e55e5e870C43652891fb44D1810b28A2);

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

	function TokenAllowance(address TokenAddr,address addr)public view returns(uint256 value)
	{
		value = IToken(TokenAddr).allowance(addr,address(this));
	}
	function TokenInfo(address TokenAddr)public view returns(info memory val)
	{
		val.addr = TokenAddr;
		val.decimals = IToken(TokenAddr).decimals();
		val.name = IToken(TokenAddr).name();
		val.symbol = IToken(TokenAddr).symbol();
		val.totalSupply = IToken(TokenAddr).totalSupply();
	}
	function SaleModify(uint256 id,string memory name,address vault,bool enabled,uint256 min1,uint256 min2,uint256 min3,address[] memory tokens)public onlyAdmin
	{
		uint256 i = id;
		Sale[i].id = id;
		Sale[i].name = name;
		Sale[i].vault = vault;
		Sale[i].enabled = enabled;
		Sale[i].min[1] = min1;
		Sale[i].min[2] = min2;
		Sale[i].min[3] = min3;
		Sale[i].tokens = tokens;
		//if(SaleMax < id)SaleMax = id;
		emit DDAOSale(id,enabled,name,vault,min1,min2,min3,tokens);
	}
        function SaleEnable(uint256 id,bool trueorfalse)public onlyAdmin
        {
                Sale[id].enabled = trueorfalse;
        }
	function SaleEnabled(uint256 id)public view returns(bool trueorfalse)
	{
		trueorfalse = Sale[id].enabled;
	}
	function LevelMin(uint256 sale,uint8 level)public view returns(uint256 MinAmount)
	{
		MinAmount = Sale[sale].min[level];
	}

	function Allocate(uint256 sale, uint8 level, address addr, uint256 amount, uint8 token)public
	{
		require(Sale[sale].enabled == true,"Sale with this ID is disabled");
		require(Sale[sale].tokens[token] != address(0),"Sale Token by ID not exists");
                require(amount <= IERC20(Sale[sale].tokens[token]).balanceOf(_msgSender()),"Not enough tokens to receive");
		require(IERC20(Sale[sale].tokens[token]).allowance(_msgSender(),address(this)) >= amount,"You need to be allowed to use tokens to pay for this contract [We are wait approve]");
		require(amount >= Sale[sale].min[level] * 10**IToken(Sale[sale].tokens[token]).decimals(),"Amount must be more then LevelMin for this level");

		AllocCount += 1;
		AllocSaleCount[sale]    			= AllocSaleCount[sale].add(1);
		AllocSaleAmount[sale]   			= AllocSaleAmount[sale].add(amount);
		AllocSaleLevelCount[sale][level]        	= AllocSaleLevelCount[sale][level].add(1);
		AllocSaleLevelAmount[sale][level]       	= AllocSaleLevelAmount[sale][level].add(amount);

		uint256 amount_human = amount.div(10**IToken(Sale[sale].tokens[token]).decimals());
                IERC20(Sale[sale].tokens[token]).safeTransferFrom(_msgSender(),Sale[sale].vault, amount);
		emit DDAOAllocate(AllocCount,_msgSender(), addr, sale,level, amount,amount_human);
	}

}