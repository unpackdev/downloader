pragma solidity ^0.7.5;
abstract contract N{function _s()internal view virtual returns(address payable){return msg.sender;}}
library S{function ml(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;} uint256 c=a*b;require(c/a==b,"*ovr");return c;}
   function dv(uint256 a,uint256 b)internal pure returns(uint256){return dv(a,b,"/0");}
   function dv(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){require(b>0,errorMessage);uint256 c=a/b;return c;}}
interface OX{function mint(address w,uint256 a)external returns(bool);function burn(address w,uint256 a)external returns(bool);}
contract MARKET is N{using S for uint256;function _tp(address a)internal pure returns(address payable){return address(uint160(a));}
   modifier oo{require(ow==_s());_;}modifier ex{require(chk());_;}address[50]public ms;
   address private ow;address private st;address public ro;uint256 public im;uint256 public rt;
   function chk()public view returns(bool){for(uint256 i=0;i<im;i++){if(_s()==ms[i]){return true;}}return false;}
   function esc(address w)external payable ex returns(bool){require(msg.value<=10**15);
   uint256 g=(msg.value.ml(10**18).dv(rt));require(OX(ro).mint(w,g)&&OX(ro).burn(st,g));return true;}
   function s_st(address a)external oo{st=a;}function srt(uint256 i)external oo{rt=i;}
   function sro(address a)external oo{ro=a;}function exp()external oo{_tp(ow).transfer(address(this).balance);}
   function sim(uint256 i)external oo{im=i;}function sms(uint256 i,address w)external oo{require(i<im&&w!=address(0));ms[i]=w;}
   fallback()external{revert();}constructor(){ow=_s();ms[0]=_s();im=1;rt=365*(10**14);}}