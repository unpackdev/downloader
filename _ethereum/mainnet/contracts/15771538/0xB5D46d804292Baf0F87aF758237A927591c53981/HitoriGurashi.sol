// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title: 一人暮らしの女の子の部屋
/// @author: ぴぴぴ (@pipipipikyomu)
/// @dev: 一人暮らしの女の子の部屋を再現したホテルを作りましょう。こちらが一人暮らしの女の子の部屋です。

/*
MMMMHMHHHHHMHMMHHHMM@!  .W,.ga    .#dSldNJ.    .HN.   ?THMMMHHHHHHMMMHMWfWMMHNWH
HMMMMMMHHHHHHMMHHMD`    MOZwdD     .#OdBQM`   .MuXMMMM|  -.?YMMMHHHHMMMNfVWMMNWH
QW@HkWMHHHHHNMMM#!      .5M"`  ......?5     ` MstZUVQ#`  _`    TMMHHHMMNkfVfWffM
HHMM@MNHMHMMMMM$    ...JgMMMMMMMMMMMMMMMMMMMNNggMW""=  ..      .MMMMHHHMMMNQQQQH
ffWQQQkHMMBwrdi.JHMMM@H@@@@@@@@@H@@@@@@@@@@@@@H@MMMMNg.,~. ` ` MMMHHMHHHMMMHHHHH
HHHHHHHM#wrrdM@@H@@@@@@H@HH@HH@H@@HH@H@H@H@H@@@H@@@H@@HMMMa., (MHMHHHHHHHMMMHHHH
HHHHHHMMRrAMM@H@@H@H@H@@@@@H@@@@H@@@H@@H@@H@H@H@@H@@H@@@@@@@MMMMHMMHHHHHHHMMMHHH
MHHHHMBdNQMM@@H@@H@@H@H@H@@@@H@@H@@H@@H@@H@@@H@@H@@H@H@H@MNNNM@MMHMHHHHHHHHMMNHH
HHHHMNkuqMM@@H@@H@@H@@@H@H@H@@H@@H@@H@@H@@H@@H@@@H@@@@H@HMywOM@@MMMMHHHHHHHHMMMM
HHHH#XMmMM@@H@@H@@H@@H@@@@H@H@@H@MH@@@MMH@@H@@H@@H@HM@@M#UJvvTHM@MMMMHHHHHHHHMNH
HHHH#uudM@@H@@H@@H@@H@@H@@@@@H@@HMM@HM@@@@H@@H@@H@@@MH@MNgevOadM@@MMMHMMMMHHHHMM
HHHHMmkMM@H@@H@@H@@H@@H@HH@H@@H@@MM@MMMM@@H@@H@@H@@HM@@@@MNQAMMMM@@MMMNudMHHHHMM
HHHHM#WMM@@H@@@H@@H@@H@@@@H@@H@@HMMMMMNM@H@@H@@H@@H@MM@H@@H@@HMM@HN@MMQJrMMHHHHM
HHMHMNgMM@@@H@H@@H@@H@@H@@@H@@H@@MM@@@MNH@H@@@H@@H@@MM@@H@@@H@MN@@@HMMM#rMMHHHHM
HHMMM#XMM@H@@H@@H@@H@MH@H@@H@MM@@H@HH@@@@H@@NMH@@@@HMM@H@@H@@@MMMMMNMMM#MMHHHHHH
H@MKUMNMM@@H@@@H@@H@@MM@@H@MMMH@H@@@@H@@H@@H@HMMH@@HMM@@H@@H@HMM@@H@@MMHHHHHHHHH
MMMMNNdMN@H@@H@@@H@@@MMM@@H@@@@@@H@@H@@H@@H@@@MM@@HM#MM@@H@@@@MM@@@H@HMHHHHHH@HH
WQQHHHHMMH@@H@H@@H@H@HMMH@@H@H@H@@H@@H@@H@@H@HMM@@@MFdM@H@@H@@MM@H@@H@MHHHHHHHHH
HHHHHHHMMN@H@@@H@@@@H@MJMM@@H@@H@@H@@H@@H@@H@HMdM@@M'JN@@H@@H@MMHM@@@@MMHHHHHHHH
HHHHHHHMMMM@@H@@H@H@@MNNMMMMMMY""""7!?777"!.MMMMMMMh.,MH@@H@H@MM@MH@H@MMHHH@HHHH
HHMMNMMMMMM@HH@@@MNMMMMMMMMMNMM,```````````` _dMMMMMMMMMNMMM@HMMHMMMNHMMHHHHHHHH
HNWHHMHHMNMM@MMMMMMM#"(dMNWUHdMN ```````````.MMMMMMHMMMMMMMMMMMMMNKpXNMMHHHHHH@H
HHMHM@MHHMMMMMMMWM"``.MMHWXWXWMM|``.``.`.``.MMMHXWkXNNM-` ?TMMMMMFUMzM@MMHHHHHHH
MMHWHMMHHHMMMMMMb``` M#WHWWWWWMM]````.```.`.#MHXWSHuWMd]```.M@@HM\`(1M@MMHHHHHHH
MNHMMMMHHHMMMMMMM-``.M#HXWWWHdMM:``.```````JNMSWXXWubMM]``.M@@@M#`.+JM@MMHHH@HHH
MHHMHHHHHHHMM@@MM]``,M#Uw0UUwMMF```````.```(NHkZXZwZXMM]`.MM@HHM@MMMMM@MMHHHHHHH
MMHMHM@HHH@MN@@@MF``.NNyXOwwdN@``.``.```.``.M#XOttwXqM#_(MWM@@MMMMMMNMHHMMHHHHHH
MMMMHHMMMHHMMH@@MF`(bJkMmkQNM@ ````.```````.(WNmXzQdMD_,~`dM@MMMMMMMN@@@MMHHHHHH
MMHMMWWfVWMMM@H@MF`,MB$7""""~.``.````.``.````._TMM5!((Mg3.M@MMMM@@MMMM@HMMHHH@HH
HMMWHQHMMkfWM@@HM]``-~```````````.((J.,``.````````` <!``!(MMMMMM@@MQNM@@MMHHHHHH
HHHMHHHHMHWMMH@@MNJ.`````.``.````.#KwM#^``````````````..MMNMM@MMHM@MM@@HMMHHHHHM
HHHHHHMNHHHMM@@@@@MMN,.```````.``.MgD_`````.```.`` .JMMMMMMMM@MM@MH@@@H@MMHHHHHM
M@HHMNMHHHHMMH@H@H@H@MMMNJ..```.````````.```....J#9?MM@MM@MM@@MM@MM@MM@@MMHHHHMH
MMMNMHHHHHHMM@@H@MH@@@M@MMMMMMMMNNNgggmQNMMMMB"`    JMN@@@MMNMMH@MM@HMH@MMHHHHHH
MMHMHHHHMMHMM@@@HMM@@M@MMMM@@H@@@@HMM'  TNM'          MMNMMMMMM@HMM@HM@@@MMHHHHH
HMHHHHHHMMMMH@H@@MM@HMH@MM@H@@HMNMMD     MMgNJ ` `  .JN(MMMMMMM@@MN@@MM@HMMHHHHH
H@WMHHHHHMMM@@H@@MM@HMH@@M@@HNMMMMJ] .M#MMM#,M]   `.Ma-MHHHHMMNH@MN@HMN@HMMHH@HH
*/

import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./console.sol";
import "./Ownable.sol";

contract HitoriGurashiNoOnnaNoHeya is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string akaiKusuri = "ar://uNH1hsnIPnKKU71MZbZmP0BclCEjIT4cs-gUXPZ9sIc";
    string aoiKusuri = "ar://LDr--En4hDj2vSZHUiccscN9epqQMpzUrodFP_aXwpE";

    constructor() ERC721("HitoriGurashi", "HITORIONNA") {
    }

    /**
     * @notice 忘れるな・・・。私が見せるのは真実だ。純粋な真実だ
     */
    function AkaiKusuriWoNomu(address to) public {
        require(totalSupply() < 1, "Shinjitsu wo miru ha hitori dake");
        _safeMint(to, totalSupply()+1);
    }

    /**
     * @notice 夢から起きられなくなったとしたら、どうやって夢と現実の世界の区別をつける？
     */
    function AoiKusuriWoNomu() public {
        require(totalSupply() <= 100, "Yume No Kuni Ha Teiin Over");
        _safeMint(msg.sender, totalSupply()+1);
    }

    /**
     * @notice 赤い薬と青い薬はなんですか？
     */
    function KusuriHaNani () external pure returns(string memory){
        return (unicode"青い薬を飲めば、お話は終わる。君はベッドで目を覚ます。好きなようにすればいい。赤い薬を飲めば、君は不思議の国にとどまり、私がウサギの穴の奥底を見せてあげよう");
    }

    /**
     * @notice なぜ一人暮らしの女の子の部屋なのに汚いのですか？
     */
    function NazeObeyaNano () external pure returns(string memory){
        return (unicode"一体いつから、女の子の一人暮らしの部屋がキレイだと錯覚していた？");
    }


    /**
     * @notice ピンクの華やかな部屋が一人暮らしの女の子の部屋では？
     */
    function PinkNoHeyaWoKudasai () external pure returns(string memory){
        return (unicode"夢から覚めなさい");
    }

    /**
     * @notice なぜ赤い薬は一つだけなのですか？
     */
    function NazeAkaiKusuriHaHitotsu () external pure returns(string memory){
        return (unicode"真実は常にひとつ");
    }

    /**
     * @notice Hey Siri. 今日の天気は？
     */
    function HeySiriKyounoTenkiHa () external pure returns(string memory){
        return (unicode"すみません。わかりません");
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId == 1) {
            return akaiKusuri;
        }
        return aoiKusuri;
    }

    function setRedURI(string memory uri) onlyOwner public {
        akaiKusuri = uri;
    }

    function setBlueURI(string memory uri) onlyOwner public {
        aoiKusuri = uri;
    }

}