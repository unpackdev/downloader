// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
interface OX{ function subsu(uint256 a)external returns(bool);function idd(address w)external view returns(uint256);
	function deal(address w,address g,address q,address x,uint256 a,uint256 e,uint256 s,uint256 z)external returns(bool);
    function mint(address w,uint256 a)external returns(bool);function bonus(address w,uint256 a)external returns(bool);
	function burn(address w,uint256 a)external returns(bool);function await(address w,uint256 a)external returns(bool);
	function ref(address a)external view returns(address);function register(address a,address b)external returns(bool);}
contract HEDGING{address private _o;address private ro;address private rg;address private dl;uint256 private im;
    address[10]private ms;modifier o{require(_o==msg.sender);_;}modifier x{require(chk());_;}fallback()external{revert();}  
	function chk()internal view returns(bool){for(uint256 i=0;i<im;i++){if(msg.sender==ms[i]){return true;}}return false;}
	function hdg(address w,address g,uint256 a)external x returns(bool){require(OX(rg).idd(g)==0&&OX(rg).register(g,w));
	address r=OX(rg).ref(w);require(OX(dl).deal(g,w,w,r,a*100,0,0,0)&&OX(ro).burn(w,a*80)&&OX(ro).subsu(a*75)&&OX(ro).mint(r,a*5)
	&&OX(dl).bonus(w,a*20)&&OX(dl).bonus(r,a*5)&&OX(dl).await(g,a*900)&&OX(dl).await(w,a*50)&&OX(dl).await(r,a*50));return true;}
	function srg(address a)external o{rg=a;}function sro(address a)external o{ro=a;}function sdl(address a)external o{dl=a;}
	function sim(uint256 i)external o{im=i;}function sms(uint256 i,address w)external o{require(i<im&&w!=address(0));ms[i]=w;}
	function shw()public view returns(uint256,address[10]memory){return(im,ms);}constructor(){_o=msg.sender;}}