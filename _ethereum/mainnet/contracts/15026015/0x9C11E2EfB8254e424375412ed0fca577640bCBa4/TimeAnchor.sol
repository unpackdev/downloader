//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

/*
8%B%%%%%B%%%%%88%@@@@@@@@@@@@@@@@@%88888888888&&&8&&&&&8&W&W&&&&&&&&&&&&&&W&W&&&&&&&&&888888888888888888888888WW8888&WW&88&W&&&&&&&&&&WWW&&&&&%@@@@@@
888888888888888888888888888888888888888888888&&8&&&&W&88&WMW&&&&&&&&&8&&&&W&W&&&&&&&&&&&&&&&&&&888888888888888&WWWWWMW&W888888888888888888888B@@@@@@@
888888888888888888888888888888888888888888888&&&W8&M&8&W&8&8%BBBBBBBB88&&WW&W&&&&&&&&&&&&&&&&8&&&&&&&W888888888888888888888888888888888888888B@@@@@@@
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888&&&&&&W&M8&W&M&&8@@@@@@@@@B8&W&&W&M8&8&&8&&&&&WMWWWWWWWWWWWW&88888888888888888888888888888888888888B@@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMW888&&&8&&MMWW&WMW&&M&&8BBBBBBBBBB8&W&WM&MuI[Q88&&&&&W&&&&&&&&&&&WW&8&&&8888888888888888888888888888888888B@@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&WMMMW&&&&&&M&&8BBBBBBBBBB8&W&Wab-x00h&&&&&&&&&&&&&&&&&&&&W&88&&&&&&&88888888888&&&&&&&&&&&888&888B@@@@@@@
8888888888888888888888888888888888&&&&&&8888&&&&W&M#MW&M&&8BBBBBBB@BB8&W&jvY0000h&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&888888888&WWWWWWWWWWWWWW&888B@@@@%%B
888888888888888888888888888888&&&&&&&&&&8B@BB%&&&&M#MW&&&&&&&&&&&&&&&&&Zr0000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88888&WWWWWWWWWWWWWW&88888888888
8888888888888888888888B@@@@@B8&&&&&&&&&&&8%BBBB8&&&&&&&&&&&&&&&&&&&&&8I|0O000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&&&&&&&&&88888888WW8
BBBBBBBBBB%%%%%%%%%%%@@@@@B@B8&&&&&&&&&&&&&%BBBBBBBBBBB8&&&%BBBBBBBaL|0000000000aBBBB8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&8&&8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&8%BBBBBBBBBBB&&8BBBBBBkYJL00000000000aB@BB8&&&&%%%%%%%%8&&&&&&&&&&&&&&&&&&&&&&&&WWW&&&&&&&&&&&&W&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B88&&&&&&&&&&&&&&%BBBBBBBBB%&&&%B%BBjz0O000000000000aBB%8&&&&&&%BBBBBBBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMWWMMMM8
@@@@@@@@@@@@@@@@@@@@B@@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&wr0Yr[(rr|[[|r[[[III[Q&&WWW&&&&&&&8BBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMMMMMMM8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&WWWppmwuI>]rrrrrrrunrrnvvnrrrrr}~~]11Ymppp&&&8B%%&&&&&&&&&&&&&&&&&&8&&W##&&&&&88888&MMMMMMMMMMMW8
@@@@@@@@@@@@@@@@@@@@@@@@BBBBB8&&&&&&&&&&&&&&&&&&W&WWxrx}{|-~I[)rrrrrcC0LCCXvvXJrrrrrrrrrr/(tttjrr&&&&&&&&&&&&&&&&&&&&&&&&&WMM&&&&&&&&&&&&&&&&&&&&&888
@@@@@@@@@@@@@@@@@@@@@@@@BBB@B8&&&&&&&&&&&&&&&&&&W)}}lIl[)r[_I[(rrrrr|}0u[[x00x[rrrrrrrrrrrrrrrrrj[[{WW&&&&&&&&&&&&&&&&&&&&&&8&&&&&&&&8888888888888888
@@@@@@@@@@@@@@@@@@@@@BBBBBBBB8&&&&&&&&&&&&&W&&({{{?IIII[)r[_I[)rjrjrjrrrrr([[|rrrrjrrrrrrrrrrrrrrrrj[[1&W&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888888888888
@@@@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&W#d({{{}?lIIIII[)r[_I|jvvvv000000000000000uuvvvvrrrrrrrXJrrrrrj11|dM&&&&&&&&&&&&&&&&&&&8&&&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@B@@@@BB8&&&&&&&&&&&&&&&&&&&W&cj{{{{[?IIIIIII[)rXXc00000OoooooooooooooooO00000JCJrrrrrrrrrrrrrrrtjvWW&&&&&&&&&&&&&&&&&&&&&&&&W&8&MWWW&WW&MM
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&&h}{{{})r}-IIIIIII000000MM#MM##MMMM*WW*######MM#WWW000000rjrrrrrrrrrrrrf[k&&&&&&&&&&&&&&&&&&&&&&&&W&&&W&&W&WW&WW
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&MMWt}{}{}[{r}-IIIIQ00000MM****##**MWWW*WW*M###MWMMWWWWWWW000000rrrrrrrrrrrrr{/&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&&W&&WW8
88888888888888888&&&&&&&&&&&&&&&W&dO}{{)jf[[{r}[?Q00wwqWWW*M****##**#WWW*WM#WWWWWWMWWWWMWWWWWWqww00QvxrrrxJcuurj1Zb&&&&&&&&&&&&&&&&&&8&&&&&MM&&MW&MM&
WWWWWWWWWWWWWWWWWWWWWWWMWWWMMMMMar)}}/rCxt[[1rXU0hhh######*######***#*##*MMWWWWWWWWWWXujXnjjqWWMMooo0LJrrrjCLvUUrttr*W&&&&&&&&&&&&&&&8&&&88&888888888
WWWWWWWWWWWWWWWWWWWWWWMMMMMMMMWj{}{1rrrrrf}[|00m#M########*#########*M*#*#########rrr0000000t][mWW&&Ww00urrrn00Lrrrj{f&&&&&&&&&&&&&&&&&&&&&&&&8888888
8888&&&&&&&&&&&&&&&&&&&&&&&&&&&j}{frrrrrrf[C00#W#MWWWW#*#W*WWWWWWWWMWWWM*MWWWMWMQr000rrjrrrrU00t{WWWWW#0OLrrrrru0nrrrX&&&&&&&&&&&&&&&&8B@@@@@@@@@@@B%
%%%%888888888888888888888888&#{1(rrrrrrruz0wpWMMWWWWWW#*#W*WWW*bqqpjjjYLmYQwqqqjY0rrrrnu0XvrrrrJQ1d%&W#Mpw0zurrrrrrrjf1*&&&&&&&&&&&&&&8@@@@@@@@@@@@@@
@@@@@@@@@@BBBBBBBBBBBBBBBBBBYrtjrrrrrrnC0ZoWWWWWM#####*##W*0{jYbwqwM*###*MW8%pYCXurrrJQ0000JurrnvCun&WWWW#aZ0CnrrrrrrrrrX&&&&&&&&&&&&&8BB@@@@@@@@@@@@
@@@BBB@@@BBBBBBBBBBBBBBBBBB%YrrC00nrrrn00mMMMMMMMMMMMMMM#M[vMWM#WW##WWWMWWW8%Or0zrrY0000000000rrr0t1WWWWWWWm00nrrrrrLCrrY&&&&&&&&&&&&&8B@@@@@@@@B@@@@
888&&&&&&&&&&&&&&&&&&&&&&&#[trrC00urrL00#WWMMWWWWWWWWWMMZ[&MWWMWWWWMMMWWWWW8%J[0zrrrrrrr0crrrrrrr0vxWWWWWWW&#00Lrrrrrrrrt[#&&&&&&&&&&&8B@@@@@@@@B@@@@
8&&&&&&&&&&&&&&&&&&&&&&&&kqrrrrrrrrrvLOw#WWWWWWWMWWWWomXOMWWWWWWWWWWWMMMMMW&8mvYurrzJ0LC0LJJJJrrxXjtWWWWWWWW#w0LvrrrrrrrrrZd&&&&&&&&&&8BBBB@@@@@@@@@@
8&&&&&&&&&&&&&&&&&&&&&&&WXtrjrrrrrrn00mWWWWWWWWWWMMW{jZMMMM#########MMMMMWWMW#*]|rrrruYC0crrrrrrr[Z#WWWWWWWWWWm00nrrrrrrrr?f&&&&&&&&&&8BB@B@@@@@@@@@@
WWWWWWWWWWWWWWWWWWWWWMMWWYjrrrrrrrC00oMM##MMM#####0I*###*###*Moooo*#*#******#MWQr[rrrrrr0crrrrr)}0aMWWWWWWWWWWW*00CrrrrrrrrY&&&&&&&&&&&&8BBB@@@@@@@@@
MMMMMMWMMMMMMMMMMMMMMMM*[trrrrrrrrC00o#*#######**i1*********o******oo******MM#MMd0[[[rrrrrrr)[[z00aWWWWWWWWWWWW*00Crrrrrrrr(l#&&&&&&&&&&&&8B@@@BBBB@@
MMMMMMMMMMMM#M#########*1fruxrrrn00ZMMMMWWWWWWWom1xWWW*MMMMMMMMWWMMMMMqqqdqqbbbWMMwwm|///|/|JwwoMwhoWWWWWWWWWWWWWm00nrruurrt[qk&W&&&&&&&&&&&&&8888888
WWWWWWMMMMMMMMMMMMMM#MM*rrruxrrrn00Z****WWWWWWWZI*MWMW#WM#########*jfjtnXJUXJcjXXXM#Maooaaaa#MMMMMCcMMMMMMMMMMMMWZ00nrruurrjtYn{WWW&&&&&&&&&&&&&&&&&8
&&&&&&&&&&&&&&&&&&&&&&x}rrrrrrrrx00Z****WWWWWMWZI*WM#MW##MMMMMMMMQ[rz00pM*#M*p00zrrZ*##*****####*#Yn###########MMZ00xrrrrrrrrrv0l(MMMMMMMMMMMM&&&&8&8
&&&&&&&&&&&&&W&&&W&&&&x}rrrrrrrC00a#****WWWWWW)jMWWMMM#MM#MMMMMM])r0q#M#M*#Mooooq0rrroooooooo*****oo0h*********###o00Crrrrrrrrv00nIBBB@@@@@@WMWMMMMMM
&&&&&&&Zu|ru|||vvv/[??}1rrrrrrrC00*WMMWMMMMM#M1jM#MM#MM#MM#kZ0OZ-(v##M##M*#Mo*MWMM0zrb*WMdZmwqpmmmmOc0mpqqpqqZmmmm0cvvruvvvvvrv0000/zaB@@BBBWMW&B@BBB
&&&&&&&M*0000000000000vrrrxJnrrC00o###########rc###MM#MW#*}jOOv-cU0{zo#MMjfj###MMMamJrm#jJZZwqqmmZZ0IIIi?[[[[-!IIlIIIl~--?|x0rv00000QCrQB@BBWMW&B@B@@
WWWWWWWWWWp00000000000vx0000urrC00o###########)j####MM#MLI[+II<[I<[[+llIIrjr[[[[[[[[[[[[[[[IIIl-[[>lII>MMMMMMMMMM_+00zIIIII]0xv00000000c[B@B&MM&B@B@@
&&&&&&&&&&&&0000000000vx0/{00QrC00*WWWWWMMMMMM(rMMMMMMMWO[]_lI<[I<[[[[[[[rjr[[[[[[[[}[[[[[[[>IIll[[]II>M#MMWMWWWW_+00zIIIIli[rv00000000O0[XBWM&8B@@@@
&&&8&&&&&&&&&kw0000000vx0Xc0UXrC00*WWWWWWWWWWMnXWWWWWWMWWMjcZZc[cCqjLM*MMjjjo*oMMMamJrwMjLqqqqpwmmmO[<iilllIIl_-[[?iIl~-??|x0xv0000000O000JvhaW&%BBBB
&&&&&&&&&&&&&&&ow00000vr||/0xtrC00*WWWWWWWMWWWnYWWWWWMMW88Mawqpd(rX8WM*MMM##o*oWMM0zrboWMkqqqqqmmZZO}LwqmmZZZZmmppmYcvr/|||||rv0000000000000JqWWWWW&&
&&&&&&&&&&&&&&&&&&0000vrrrj[trrC00*WWWWWWWWWMWWZI*WWWWMMMMM&8%88rrr0dM*MMM#Mo*oMd0rrrMMWMMMMMWMMWMx1#M#MMWWWWWWWWW*00CrrrrrrrQw&&&&&&&&&&&&&&W&WWW&W&
&&&&&&&&&&&&&&&&&&&p00vrrrrrrrr{1O0ZWWWWWWWMWWWZI*WWMWMMMMMW8888%qrrz0QdMM#MopQ0zrrmMWMMMWMWWWWWWMx1#M#MMMWWWWWWWZ001{rrrrrrrQw&&&&&&&&&&&8&&W&&MM&&8
&&&&&&&&&&&&&&&&&&&&&wO0rrrrrrr((00mWWWWWWWWWWWp{OpWMWWWMMMMMW88888YXXrcJJJJJcrXXzMMMMMMMMMWWWWWWbLY##*MM########Z00|(ruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&#oJurrrrrrn00ZWWWWWWWWWWWWWi1MWWWWWMMMMWMMMMMMMWbbbbbbbbb##########MMMMMMM#rp#MWMMWMMMMMWWMZ00nrruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&&W0vrrrrrrj[U00*WWWWWWWWWWWMa0MWWWWWMMMMMMMMMMMM**########**#######*#**o#Yr###*MW8%%%%%%%W00U[jrrrrrrv0MWWWWWWWWWWWWWWWM&&MM&&8
888888&&&&&&&&&&&&&&&&&W&wQrJQrrrrJ00*WWWWWWWWWWWMWW!(W&WWWWWM*MMMMMMM*&8888M&8&&MMMMMMWW#W##*rpWWMM#MW8%%%%%%BW00CrrrrrrrQqWWWWWWWW&&&&&&&&&&&&MM&88
@@@@@@@@BBBBBBBBB&&&&&%B%pQrjrrrrr)|00mWWWWWWWWWWWWWWomo*WMWMM**MMMMMM*&8888M&8WWMMWWWWWW#WdCXWWWWWW#MW8%%%%%%m00|)rrrrrrrQq###############MMMMMMM&88
@@@@@@@@BBBBBBBBB&&&&&%B%#oCnrrrrrrj|COw*WWWWWWWWWWWWWWamjXx}jJ*#MMMMW*###########**###*#Ujdo*WWWWWW#MW8%%%%&qOC|jrrUYrrnCa#WWWWWWW&&&&&&&&&&&&&&8&88
@@@@@@@@@@BBBBBBB&&&&&%BBB80urrrrrrrrC00#WWWWWWWWWWWWWWrc00O00v[M#WWWWWWWWWWWMWWWM##W##*[QW#M*WWWWWW#MWWW8%%&00CrrrrrrrrvOM&&&&&&&&&&&&&&&&&&WW&&8888
@@@@@@@@@@BBBBBBB&&&&&%BBBBBwQrrrrrrr{(00mWWWWWWWWWWWWWrc0rrr0UrMMW&8888888888WWWWW##r([W#W#M*WWWWWWMW&%&W&m00({rrrrrrrQq&WW&&&&&&&M&&&&&&&&WW&W&8888
@@@@@@@@@@BBBBB@B&&&&&%BBBB%bmuxrrrrr--vQmoWWWWWWWWWWWWvxtt/(ft/000*###oa#oaaahh0Xrjj#M*##*M#*MWWWMW8&&8&WomQY|)rrrrrxvmdWW&&&&&&W&&&&&&&&&&&&8&88888
@@@@@@@@@@@@BBBBB&&&&&%BBBBBB80urrrrrrj(?10mdWWWWMWWWMMopYYXcYOhaao####oh#ohhhhhM8WWWW#*#WMWWW&&&W8%%&W&dw0j/tjrrrrrru0MW##W&&&W&&&8BBBBBBBB8&8888888
8888B@@@@@@@BBBBB&&&&&&%BBBBBB%wQrrn00Crj|IJ00*################*MMW&88888888888888WWWWM##&%%%%%%%%%8WWM00C[trrru0nrrQm#WW##W&WW&&8BBB@B@@@@@&&&888888
88888%@@@@@@@BBBB&&&&&&&&888&&&&#0nn00Crrf[!_00wWWMMMMMMMMMMMMMM#MWWWM&88WWW88W888WWWW&8%%%%%%%%%8W&Ww00|}rrrrrrrru0o#M#MMMMM&&&B@@BB@@@@@@@&&8888888
WWW&88%@B@@@@BB%&&&&&&&&&&&&&&&&Mwzurrrrrf[[]~uX0oooW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWooa0UX1frrrrrrrruzwM&&&&&&&&&&&@@BBB@@@@@@@&88888888
888W88%BB@@@@%&&&&&&&&&&&&&&&&W&&&*hJxrrrf[[{r?-?Q00wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwww00Q/ttrYCJnrrjxJa*&&&&&&&&&&&&&BBBB@@@@@@@@&88888888
WWW888%B@BBB&&&&&&&&&&&&&&&&&&&&&&&&&wLrjf[[1r}-IIIIQ0000OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW00000Q[[}rrrrC00ujrLmMMMMMMMMMMWWWM&&BB@@@@@@@@@@888888888
88888888&8&&&&&&&&&&&&&&&&&&&&&&&W&&&W#0nf[[{r}-IIIIIII000000WWWWWWWWWWWWWWWWWWWWWWWWWWW00O000[[[jrrrrrrrrrrn0#WMWWWWWWWW&&&&M&&BB@@@@@@@@@B888888888
888888888&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&pQ|/tr}-IIIIIII>>~ccc000000oooooooooooo*oo000000XYY111rrrrrrrrrruvuOp&&WW&&&&&&&&&WW&W&&@@@@@@BB@B88888888888
88888888888&&&&&&&8&&&&&&&&&&&&&&&&&&8%%%8M*kC{-IIIIIII[)r-~I????}|000000000000000||||||tttrrrrrrrrrrrxCkooW&&&WW&&&&&&&&&WW&W&&BBBBBBBB8888888888888
88888888888&&&&&&&&&&&&&&WMMMMMMMW&&&BBBBBBB%&O00x)IIII[)r[_I[)rrrrIIII~[I~[[[[[[[rrrrrrrrrrrrrrrrrx00O&&&&&&&&WW&&&&&&&&&W&&W&&&&&&&&888888888888888
88888888888888&888888&&&W&BBBBBB%MW&&BBBBBBBBB8&WO00!Il[1r[_I])rrrrrrrrrrrrrrrrrrrrrrrYQrrrrrjrrr00O&&&&&&&&&&&&#MMMMMMMMW&&W&&&&&&&88&WM888888888888
&MMWWWWWWMMMMMMMMMMMMMM&W8BBBBBBBM&&&BBBBBBBBBB%&WWWwww|fu|[I[)rrrrrrr0CYYC0YYY0zrrrrrrjrnuuvuwww##*&&&&&&&&&&&&W&&&&##MMMMMMMMMMMMMMMW8&W88888888888
&WMMMMMMMMMM#WMWW8W&&&W&W&BBBBBBBM&&&BBBBBBBBBBBB%&W#*#o*aomcYUJJzrrrr|/tYC0Ynt/frrrrrzJJqhaahMM#M##&&&&&&&&&&&&W&&&&MM&&&&&&&&&&&&&&&&&&&&8&W&&&8888
&WWWWWWWWWWWW&MWW8W&8&W&W8B@@@@BBM&&&BBBBBBBBBBBBBB%&W#&&#W******b00Yrrrr[[[[|rrrrrY00kMMMMMMMMMM###&&%BBBBBB%&&W&&&&MM&&&&&&&&&8888888888888&&W&8888
&W&&&&&&&&&&&&&&&8&&&&W&W8B@@@@BBM&&&BBBBBBBBBBBBBBBB%&&&#W******#&&k0000000000000rY0##########W&MW#&%BBBB@BB%&&W&&&&MW&&&&&&&&&888888888888888888888
&WWWWWMMMMMMMMMMMMMMMMM&W&BBBBBB%M&&&BBBBBBBBBBBBBBBBBB&&M&W####MW&&k0000000000JXvwoWM##M&WW&WW&&WW#&BBBBBBBB%&&W&&&&MW&&&&&&&888888888888888&WW&8888
@@@BBBBBBB%8888888888888&&WWWWWWW&8&&BBBBBBBBBBBBBBBBBB&&WWWWWWWWWWMk0000O000YuCp*WW&MMWMM&MM&WMM&&#&BBBBBBBB%&&W888&MW&&&&&&&&&&&&&WM&&&&&&&&&&&8888
@@@@@@BB@B%88888888888888&&&&&&&&&&&&BBBBBBBBBBBBBBBBBB&&WMMMMMMMMMMb0000000rX0&WM&&&&M#MM*MMM#MMMMM&BBBBBB@B%&&MWWWWMM&&8888888888&WW888888888888888
@@@@@@@@B888888888888888888888&&&&&&8B@@@@BBBBBBBBBBBBB&&M##########b00000Yx0d###M#M&WM#&M*W&##W&&&&&BBB@@@@B%&8&&&&&&MW88888888888&WW&WWWWWWWWWWWWWW
@@@@@@B%8&&WMMM88&888888888888888&&8B@B@@@@@@BBBBBBBBBB&&M&&&&&&&&&&h00LCuCw&&&&&&MM&WMM&WMW&#MW&&&&&B@@@@@@B%&&W&&&&&MW888%%%88888&WW888888888888888
@@@@@%88&&8&&88&&8&&&&&&8888888888BB@@@@@@@@@@@@@@@BBBB&&M&#WWWWWWWWwvuXC*#WM#&&&&#M&&&&&&&&&&&&&&&&&B@@@@@@B%&&MWWWWWWW8B@@@@B88&&&&&&&&&&&&&&&&&&&&
@@@%88&&88&88&W88&&888&#888888888@@@@@@@@@@@@@@@@@@@@@@&&M&M&&&&&&&&h00b&&&W#W&&##W&MMMMMMMMMMMMMMM#&B@@@@@@B%&&WWWWW8&&8B@@@@B8&W8W88888888888&&W888
88888W88&&&WW88&&88888W&888888888@@@@@@@@@@@@@@@@@@@@@@&&M&#MMMMM#M#####MM#W&&M#M&WM&&8&&&&&&&&&&&&#&B@@@@@@@%&&WW8W&WMM8B@@@@B8&W8W88888888888&&W888
&88&&8&&88WW&88&W&&&&&&&8888888888888888888888&&888888&&&M&&&&&&&&&&&&&&&&&&W#M&W#W&&&&&&&&&&&&&&&&#8B@@@@@@@%8&&W8W&8%%%@@@@@B8&W8W88888888888&&W888
8&&88WWWW&888888888888888888888888888888888888888888&&&&&MMMMMMMMMMMMMMM####W&&MMMWMMMWWWWWWMMMWWWWM8B@@@@@@@%8&&W8W&8B@@@@@@@B88W8W88888888888&&W888
8888WWWWWW88&WWWWWWWWWWWWWW&88888888888888888888888888888&8&88888888888&&&&&88&8888&&&&88888888888888B@@@@@@@%8&&W8W&8B@@$@@@@B88W8W88888888888&&8WWW
*/

// Contract by: @backseats_eth

// NOTE: These are named 'Time Anchor #1-18 – 0001' in the metadata where the 0001 increments
contract TimeAnchors is ERC721A, ERC2981, Ownable {

  // The address who claimed the 64 eth bounty, preserved for all time.
  address public winningAddress;

  // The address whose private key mints Time Anchors
  address public systemAddress;

  // The contract or wallet this contract withdraws to.
  address public withdrawAddress;

  // The URI where our metadata can be found
  string public _baseTokenURI;

  modifier onlySystemAddress() {
    require(systemAddress != address(0), "Set system address");
    require(msg.sender == systemAddress, "Unauthorized");
    _;
  }

  // Events

  event TimeAnchorMinted(address indexed _to);

  // Constructor

  constructor() ERC721A("TTC Time Anchors", "TIMEANCHOR") {}

  // System Address Functions

  /**
  * @notice Allows the Timeline Transit Company to mint Time Anchors to those who are worthy
  */
  function mint(address _to) external onlySystemAddress {
    emit TimeAnchorMinted(_to);
    _mint(_to, 1);
  }

  /**
  * @notice Allows the Timeline Transit Company to send the 64 ETH bounty to a specific address
  */
  function claimReward(address _winner) external onlySystemAddress {
    (bool sent, ) = payable(_winner).call{value: address(this).balance}("");
    require(sent, "Payout failed");
    winningAddress = _winner;
  }

  /**
  * @dev Returns an array of token IDs owned by `owner`.
  *
  * This function scans the ownership mapping and is O(totalSupply) in complexity.
  * It is meant to be called off-chain.
  *
  * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
  * multiple smaller scans if the collection is large enough to cause
  * an out-of-gas error (10K pfp collections should be fine).
  */
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }

  /**
  * @notice Tokens are numbered starting from 1
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  * @notice Allows the team to deposit the 64 ETH bounty for collecting all of the Time Anchors into the contract
  */
  function deposit() external payable onlyOwner {}

  /**
  * @notice Sets the system address that corresponds to the private key signing on the server.
  @dev Ensure that you update the private key on the server between testnet and mainnet deploys and
  that the address used here reflects the correct private key
  */
  function setSystemAddress(address _systemAddress) external onlyOwner {
    systemAddress = _systemAddress;
  }

  /**
  * @notice Sets the withdraw address where funds will be withdrawn to
  */
  function setWithdrawAddress(address _address) external onlyOwner {
    withdrawAddress = _address;
  }

  /**
  * @notice Sets the baseURI where collection assets can be accessed
  */
  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  /**
  @notice Sets the contract-wide royalty info
  */
  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  /**
  * @notice Boilerplate to support ERC721A and ERC2981
  */
  function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
  * @notice An fallback function to only be used by the team to withdraw the bounty from the contract
  in case of an emergency
  */
  function emergencyWithdrawFunds() external onlyOwner {
    require(withdrawAddress != address(0), "Missing withdraw address");
    uint balance = address(this).balance;
    (bool sent, ) = payable(withdrawAddress).call{value: balance}("");
    require(sent, "Withdraw failed");
  }

}
