// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
abstract contract CN{function _s()internal view virtual returns(address payable){return msg.sender;}} // USELESS COMPATIBILITY
library SM{function ml(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b,"ml overflow");return c;}} // USELESS SAFEMATH
interface OUT{//GLOBAL RESERVE SYSTEM CONNECTION INTERFACE //GLOB HADGE DEFI SYSTEM //DAO ETHEREM
    function idd(address w)external view returns(uint256);function mint(address w,uint256 a)external returns(bool);function bonus(address w,uint256 a)external returns(bool);
	function burn(address w,uint256 a)external returns(bool);function await(address w,uint256 a)external returns(bool);function subsu(uint256 a)external returns(bool);
	function ref(address a)external view returns(address);function register(address a,address b)external returns(bool);
	function deal(address w,address g,address q,address x,uint256 a,uint256 e,uint256 s,uint256 z)external returns(bool);}
contract HDG is CN { using SM for uint256; modifier ths{require(own==_s());_;} 
    address private own; address private rot; address private reg; address private del; 
    uint256 private imems; address[500]private mems; mapping (address=>address) public mems_sc;
    function hdg(address w,address g,uint256 a)external returns(bool){require(a>99999&&check(w)&&g!=w&&g!=address(0)&&OUT(reg).idd(g)==0&&OUT(reg).register(g,w));
    address r=OUT(reg).ref(w);require(OUT(rot).burn(w,a.ml(80))&&OUT(rot).subsu(a.ml(75))&&OUT(rot).mint(r,a.ml(5))&&OUT(del).deal(g,w,w,r,a.ml(100),0,0,0)&&
    OUT(del).bonus(w,a.ml(20))&&OUT(del).bonus(r,a.ml(5))&&OUT(del).await(g,a.ml(900))&&OUT(del).await(w,a.ml(50))&&OUT(del).await(r,a.ml(50)));return true;}
    function check(address w)internal view returns(bool){for(uint256 i=0;i<imems;i++){if(w==mems[i]&&mems_sc[w]==_s()){return true;}}return false;}
    function setreg(address a)external ths{reg=a;}function setrot(address a)external ths{rot=a;}function setdel(address a)external ths{del=a;}
	function s_im(uint256 i) external ths returns(bool){imems=i;return true;}
	function s_w_sc(uint256 i,address w,address sc)external ths returns(bool){require(i<imems && w!=address(0) && w!=sc && sc!=address(0));mems[i]=w;mems_sc[w]=sc;return true;}
	function g_w_sc(uint256 i)external ths view returns(uint256, uint256, address, address){return(imems,i,mems[i],mems_sc[mems[i]]);}
	fallback()external{revert();} constructor()public{own=_s();}}