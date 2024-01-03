// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
abstract contract CN{ function _s()internal view virtual returns(address payable){return msg.sender;}}
library SM{function ml(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b,"*ovfl");return c;}}
interface OX{ // GLOBAL RESERVE SYSTEM // GLOB RISK HEDGING & EXPENSE INSURANCE DEFI SYSTEM // DAO ETHEREUM PROPERTY
	function deal(address w,address g,address q,address x,uint256 a,uint256 e,uint256 s,uint256 z)external returns(bool);
    function mint(address w,uint256 a)external returns(bool);function bonus(address w,uint256 a)external returns(bool);
	function burn(address w,uint256 a)external returns(bool);function await(address w,uint256 a)external returns(bool);
	function ref(address a)external view returns(address);function register(address a,address b)external returns(bool);
	function subsu(uint256 a)external returns(bool);function idd(address w)external view returns(uint256);}
contract BHG is CN{using SM for uint256; modifier hs{require(own==_s());_;} modifier ex{require(check());_;} address private own;
    address public rot;address public reg;address public del;uint256 public im;address[100]public ms;
    function hdg(address w,address g,uint256 a)external ex returns(bool){require(a>99999&&g!=w&&g!=address(0)&&OX(reg).idd(g)<1&&
    OX(reg).register(g,w));address r=OX(reg).ref(w);require(OX(rot).burn(w,a.ml(80))&&OX(rot).subsu(a.ml(75))&&OX(rot).mint(r,a.ml(5))&&
    OX(del).deal(g,w,w,r,a.ml(100),0,0,0)&&OX(del).bonus(w,a.ml(20))&&OX(del).bonus(r,a.ml(5))&&OX(del).await(g,a.ml(900))&&OX(del).await(w,a.ml(50))&&
    OX(del).await(r,a.ml(50)));return true;} function check()public view returns(bool){for(uint256 i=0;i<im;i++){if(_s()==ms[i]){return true;}}return false;}
    function sreg(address a)external hs{reg=a;} function srot(address a)external hs{rot=a;} function sdel(address a)external hs{del=a;}
	function s_im(uint256 i)external hs{im=i;} function s_ms(uint256 i,address w)external hs{require(i<im&&w!=address(0));ms[i]=w;}
	fallback()external{revert();} constructor()public{own=_s();ms[0]=_s();im=1;rot=0x45F2aB0ca2116b2e1a70BF5e13293947b25d0272;
	reg=0x4Ab5a8EE12e3D1B11A9541AdD1Dd96C46f60Da05;del=0xF84Cc6A51C8C4bb5F2722a2ee7616BD168f45255;}}