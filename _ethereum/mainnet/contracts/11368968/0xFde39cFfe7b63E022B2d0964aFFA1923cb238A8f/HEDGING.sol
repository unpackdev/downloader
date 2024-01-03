// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
abstract contract N{function _s()internal view virtual returns(address payable){return msg.sender;}}
library M{function ml(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b,"*ovf");return c;}}
interface OX{ function deal(address w,address g,address q,address x,uint256 a,uint256 e,uint256 s,uint256 z)external returns(bool);
    function mint(address w,uint256 a)external returns(bool);function bonus(address w,uint256 a)external returns(bool);
	function burn(address w,uint256 a)external returns(bool);function await(address w,uint256 a)external returns(bool);
	function ref(address a)external view returns(address);function register(address a,address b)external returns(bool);
	function subsu(uint256 a)external returns(bool);function idd(address w)external view returns(uint256);}
contract HEDGING is N{using M for uint256;modifier hs{require(_o==_s());_;} modifier ex{require(check());_;}
    address private _o;address public ro;address public rg;address public dl;uint256 public im;address[50]public ms;
    function hdg(address w,address g,uint256 a)external ex returns(bool){require(a>99999&&g!=w&&g!=address(0)&&OX(rg).idd(g)<1&&
    OX(rg).register(g,w));address r=OX(rg).ref(w);require(OX(ro).burn(w,a.ml(80))&&OX(ro).subsu(a.ml(75))&&OX(ro).mint(r,a.ml(5))&&
    OX(dl).deal(g,w,w,r,a.ml(100),0,0,0)&&OX(dl).bonus(w,a.ml(20))&&OX(dl).bonus(r,a.ml(5))&&OX(dl).await(g,a.ml(900))&&OX(dl).await(w,a.ml(50))&&
    OX(dl).await(r,a.ml(50)));return true;} function check()public view returns(bool){for(uint256 i=0;i<im;i++){if(_s()==ms[i]){return true;}}return false;}
    function sreg(address a)external hs{rg=a;} function srot(address a)external hs{ro=a;} function sdel(address a)external hs{dl=a;}
	function s_im(uint256 i)external hs{im=i;} function s_ms(uint256 i,address w)external hs{require(i<im&&w!=address(0));ms[i]=w;}
	fallback()external{revert();}constructor(){_o=_s();ms[0]=_s();im=1;}}