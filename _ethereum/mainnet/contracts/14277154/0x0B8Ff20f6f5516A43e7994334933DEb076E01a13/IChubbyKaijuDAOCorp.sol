// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************************************************
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddddxxxxxdd
kkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkxkkkkkkkkkkkkkkkkkkkkkxxddddddddddddxxkkkxx
kkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkxxdddddxxxxxkkkkkkkkkkkkkkkkxxddddddddddddxxkxkk
kkkkkkkkkkkkkkkkkkkkxxxxxddddxxkxxkkxxkkkkkkkxxkkxxkkkxxddddddddxxxxkkkkkkkkxxkkkxxddddddddddddxxkkk
kkkkkkkkkkkkkkkxxxxddddddddxxxxkxxoooodxkkkkkxxdooddxkxxkkkxxxxdddddxxxkkkkkkkkkkkxxdddddddddddddxkk
kkkkkkkkkkkkxxxdddddoddxxxxkkkxl,.',,''.',::;'.''','',lxxxkkkkxxddddddxxxkkkxxxxxkkxddddddddddddddxk
kkkkkkkkxxxdddddddddddxxxxdddo,.,d0XXK0kdl;,:ok0KKK0x;.'lxxxxxxxxddddddddxxkkxxxxxxddodddddddddddddx
kkkkkxxxddddddddddddddddddddl'.:KMMMMMMMMNKXWMMMWWMMWXc..';;;:cloddddddddddxkkxxdddddodddddddddddddd
kkxxxddddddddddddddddddddddc..c0WMMMMMMMMWXNMMMMMMMWk;,',;::;,'..':oxxxxddodxxxkxxdddddxdddddddddddd
kxxdddddddddddddddddddddoc'.'d0XWMMMMMMMMMWMMMMMMMMWXOKNWWMMMWX0kl,.'cdkkxxxddddxdddxxkkkxxxdddddddd
xddddxxxxxxdddddddddddl:'.,xXNKKNMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMNk:..cxkkxxxddddddxkkkkkkkxddddddd
xxxxxkkkxxxdddddddddo;..ckNMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,.,dxxkkxxxdddxkkkkkxkkxdddddd
kkkkxxxxdddddddoddo:..c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..cxkkkkkxxxxkkkkkkkkkxddddd
kkkxxxddoddddddddd:..xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNWWMMMMMMMMMMWNO,.;dkkkkkxkkxxkkkkkkkxxdddd
kxxxdddddo:'',;:c;. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNWMMMMMWMMMWMMMXc.'okxkkkkkkkkkkkkkkkxdddd
xxdddddodo' .;,',,,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:xXMMMMMMMMMMMWNNNXd..lkkkkkkkkkxkkkkkkkxddd
ddddddddddc..oKKXWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWkc'      ,0MMMMMMMMMWNNNXNWx..okkkkkkkkkkkkkkkkxdod
dddddddddddl..l0XNNWWWMMWXNMMMMMMMMMMMMMMMMMMMMNd.   ....  :XMMMMMMWWW0l,,;d0l.,xkkkxkkkkkkkkkkkxddd
ddddddddddxko'.,lxO0KXNNO;cXMMMMMMMMMMMMMMMMMMMk.  ....... .kMMMMMMMWk.     :x'.lkkkkkkkkkkkkkkkkxdd
ddddddddxxxkkxl;'.'',:cl:..dWMMMMMMMMMMMMMMMMMWl  ........ .kMMMMMMMNc  ... .c, :xxkkkkkkkkkkkkkkxdd
dddddddxkkkkkkkkxdoc:;,''. ;KMMMMMMMMMMMMMMMMMWl  .......  ,KWWMWX0Ox'       '..cxxkkkkkkkkkkkkkkxdd
dddddxxkkkkkkkkxxkkxkkkkxo'.oWMMMMMMMMMMMMMMMMMO'    ...  .xKkoc;,,,;,.   ,:;,...:dkxkkxkkkkkkkkkxdd
ddddxxkkkkkkkkkkkkkxkkxxddc..kWMMMMMMMMMMMMMMMMMXdc:.. ..;:;...'oOXNWO:colkWMWXk;.,xkxkkkkkkkkkkkxdd
ddxxkkxxkkkkkkkkkkkkxxddddo;.;KMMMMMMMMMMMMMMMMMMMMWX0O0XXxcod;cKMMMMWKl:OMMMMMM0,.lkxkkkkkkkkkkkxdd
dxxkkkkkkkkkkkkxxkkxxddddddo,.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMWMKc:KMMMMMNxoKMMWMMM0,.lkxxxkkkkkkkkxxdd
xxkkkkkkkkkkkkkkkkxxddddddddl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWMMMMWWMMMWMMNl.,dkkkxkkkkkkkkxddd
xkkkkkkkkkkkkkkkkxdddddddddodl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMKdOWNxo0WNxlOWKcoXNo..okxxkkkkkkkkkkxddd
kkkkkkkkkkkkkkkkkxddodddddddddo'.,OWMMMMMMMMMMMMMMMMMMMMMN0Oc .lc. .l:. .;. .,, .lkxxkkkkkkkkkkxxddd
kkkkkkkkkkkkkkkkxddddddddddddddo' cNMMMMMMMMMMMMMMMMMMMMMKl,;'. .,,. .'. .,. '' 'xkkxkkkkkkkkkkxdddd
kkkkkkkkkkkkkkkkxddoddddl:,'..';. :NMMMMMMMMMMMMMMMMMMMMMWWWWKlc0WNd,xNx;kWx;xl ,xkkkkxxkkxxkkxxdddd
kkkkkkkkkkkkkkkkxdddddo:..:dxdl'  ,0MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMWWMMWWK; :kkkkkkkkkkxkkxddddd
kkkkkkkkkxkkkkkxxdoddo; 'kNMWMNl.'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:.'dkkkkkxkkkkkkxdddddd
kkkkkkkkkkkxkkkxxddddo' lXNMMWo.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o' 'dkkkkxxkkkkkkxxdddddd
kkkkkkkxkkkkkkkxdc;,,'.,kXNMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXO:,,..ckkkkxkkkxkkxxddddddd
kkkkkkkkkxxkxkxc..;loox0KKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXXXXXXXXXXXKXXk'.cxkxkkxkkkxxdddddddd
kkkkkkkkkkkkxkl..xNMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNWWWWWMMMMMMWO'.ckxkkxkxxxdoddddddx
kkkkkkkkkkkkkx, cNMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..okkkkxddddddddddxx
kkkkkkkkkkkkkx, cNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.'dkxxddddddddddxkk
kkkkkkkkkxkxxx: ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMX; :ddddddddoddxxkkx
kkkkkkkkxxkkxko..dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXXXXXXNNWMMMMMMMMMWk..cdddddddddxxkxxd
kkkkkkkxxkkxkkx, cXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMWWWNNNNWMMMMMMMMN: ,oddddddxxxkxxdd
kkkkkkkkkkkxkko..oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWMMMMMMMMMMMMMMMMWWWMMMMMMMMWk..ldddddxkkxkkxxx
xkkkkkkkkkkxkd,.lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ;dddxxkkkkxxkkk
xxkkkkkkkxkkk: :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo 'dxxkkkkkkkkkkk
dxkkkkkkkkxkx, dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..okxkkkkkkkkkkx
ddxkkxkkkkxkd'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMX; ckkkkkkkkkkxxd
dodxxkkkkxkkx; cWMMMMWNWMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWc ;xkkkxkkkxxddd
dddddxxkkkkxkl..OWMMWNXWMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMd.'dkkkkxxdddddd
ddddddxxkkkkkx; :KWWN0KWMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMk..okxxxdddddddd
ddddddddxxkkkkl..xXX0ccKMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMM0'.lxddddddddddd
***************************************************************************************************/

interface IChubbyKaijuDAOCorp {
    function burnCorpForAddress(uint256 typeId, address burnTokenAddress) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}