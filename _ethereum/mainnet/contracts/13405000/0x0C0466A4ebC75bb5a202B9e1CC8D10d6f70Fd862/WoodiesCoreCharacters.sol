// SPDX-License-Identifier: MIT

/*

* Thanks to all 111 @Ultra_DAO team members, and for this project especially:
* Project Lead: @chriswallace
* Project Mgr: @healingvisions
* Legal: @vinlysneverdie
* Artists: @grelysian | @Jae838 | @DesLucrece | @sadcop
* Story By: @crystaladalyn
* Community & Marketing: @rpowazynski | @OmarIbisa
* Discord Mods: @OmarIbisa | @ResetNft
* Meme-Daddy: @ryan_goldberg_
* Website & Web3: @calvinhoenes | @bitcoinski | @ximecediazArt
* Smart Contracts: @bitcoinski

0000K0K00KKK0KKKK000K000KKK000000000KKKKKK0KK0000K00K00KKKK0KK000KKKKKKKKKK000KKK00000000000000000000000000000000000000000000
0K00KKKKKKKKK0KKKKK000K0KK0000KK0Okxdolllox0KK000K0xdxOKKKK00KKK0KKKKKKKKKK0000K000000000000000000000000000000000000000000000
KK0KKK0KKKKKKKK00K00KKK000K0Odl;'.....''''';cdOOo:,',,;:oOKKK00KKKKKKKKKKKK00000000000000000000000000000000000000000000000000
KKKKKKKKKKKKK0000KKKKK0kxol;'..'',,;;;;::cc;'''..;;;ccc;',lkK00KKKKKKKKKK0000000000000000000000000000000000000000000000000000
KKKK00000K00K0KK0xolc:;....,:ccccccc::;;,,:ccc:,...;::c;;:,,lOKKK000K00KK0000000000000000000000000000000000000000000000000000
KK0KK00KKK00K0kc;,,,;;'..;cccccccccc:cccc;,,;;;;;. .,'';:cc;.;dOK0000K0000000000000000000000000000000000000000000000000000000
KKKKKKKK00KK0d,,:c:;,..';:;;;;;;;;;;;;;,'',,,::,,'....',,::;...oK00000KK0KK00000000000000000000000000000000000000000000000000
KKKKKKK00000o',:;:;'..,;;;;;;;;;;:;,'..':;dOldOldx.........'.  ,ddxkO0KKKKKKKKKKKKKKK00KKK0KKKKK00000000000000000000000000000
KKKKKKKK0K0l.';;::'..;ccccccccc::,'. .;okc,;'''..,..''',,''...''''''',;cd0KKKK00K000KK0KKK0KKKKKKK000000000000000000000000000
KKKKKKKK00l',:cc;...;cccccccc:;'...  :x:.....',,,,'..''''''''''',;::;,,'',:cclox0KK00KKKKKKKKKKKKK000000000000000000000000000
KKKKKK00Ko';cc:;. .;cc:::;;;:;,'. ...,,. .......,;:,'.............',;;;;:;'....,;:lx0KK0KKKKKKKKKK000000000000000000000000000
0KKKKK0Kx,,cc:,. .,:;:::;::;,,'.....  ';. ........,;::,...',,,,,........';:;;,',;;,,;cdO0KKKKKKKKK000000000000000000000000000
0KKKK0K0:'::;'.  ';;::ccc:'......... .';,.........',,:c:,. .,'',;;........,',::'.',:;,,;:dOK0KKKKK000000000000000000000000000
0KK0K0Kk'.;;,...,cccccc:;'........  ...,;:'........''':::;. .....,;;,........';;;'..''::'.,d0K00KK000000000000000000000000000
KK00KKKx..c:'..,cccccc:,.........   ...':c:'..........',;:;. .....',;:,....''.''';,...',,;'.oKK0KK000000000000000000000000000
0KK0K0Kk'.:,..':cc:::;;,''......   ....,cc:;,..........';:c' ........,:'.........';......':'.ck0KK0KK0KKKK000KKKK000000000000
00KK00KO,.,. .::;;;:;,''...............'c:;;c;. ........';c;. ........',,.........''......',..'ckK0KK0KKKKK00KKKKK00000000000
K00K0KK0: .  ';;::c:'..........''......'::;cc::. .........:;. ..........,,.....................',o0K00KKKKK0KKKKKK00000000000
K000KKKKc   .;:ccc:'..........,:........;;;cc:;:.  .......';.  ..........'. .........  ........;;'l0K0K0KKKKKKKKK000000000000
0K00KK0Ko. .;cc:c:'...........:;. .......;:c:;;c:.  .......'.. ............:c;,,;;,,,:c;,,,'. .':'.dKK00KKK0KKKKKK00000000000
0K00K00Kd. 'ccc:;,'''........,:,. .......;cc;;:cc:. ........'. .'',,,,;:::odllloxxolodolooddl:..',.c0KKKKKK0KKKKKK00000000000
00KK000Ko..;c:;;,,'....... .,;,'. .......,c:,:c:cc;. ..........:olodddxxooxdllloxkdllodlllodoll'.'.:0K0KKKKKKKK00000000000000
00KK00K0: ':;;;,.......... .c,.'. ........;;;ccc:::,  .......,cloooooddoloddollldkxolodolllodoll' .oKKKK00KKKKKKKK00000000000
00KK00Kk'.,;:c,............,c,,,.  ........,:cc:;;c:..,;,;::looddxxdollllldxollloxkdolddlllodolol.,OKK00KK0KKKKKKK00000000000
K0KK00Ko..cc:;.... ........,c,',.  ........':c:;;ccc,.:ooooooollloxxollolclddlllloxxolodoolodoloo;,xK0000KKKKKKKKK00000000000
KKKK0K0:.;cc;'............ ,c;''.   ........;:;;:ccc;.:doooollllldxdl:,''',;,:lllodkdlll;,;;:clddc'c0K00KKKKKK000000000000000
KK00KKk'.:c:''''.......... .;,....  .........,;:cc:::';dooooollodxo;'',;:c:;..;olloxxol'..,;,',:lo;;kK0K0KKKKK000000000000000
KK00KKo.':;,,'............  .,.....  .........:cc:,:;'coooooloodxl,';::;,,'...:lllldkdl,...';:;',lc'oK0K0KKKKK000000000000000
KK00K0:.,;,'............... .',......  .......,::,;c,'cooolloxxdo;..''......':llllldxdlc,.....,'.;l.c0KK0KKKKK000K00000000000
K000KO,.:;'................  .......... .......',;c:.,ooolloddolll;......';cllllllldxdlloc;''..';lc.:00KKKKKKKKKKK00000000000
00K0Kx.':'................    ....  ....  ......':c'.collloddolllloolccclllloolllloxxoloollodollloc.cKK00KKKKKKKKK00000000000
00K0Kl.,;...............  ...  ..........    ....',.'lllooddlllloooolllllllc;;clloddolooolloddollol'lK0KKKKKKKK00K00000000000
K0KK0:.,'.............   .....  ......    ..  ..... .:loddollooooollllllc;'..'cooddolloooooodl,;ox:,xK000KKKKK000K00000000000
0K0KO,.'................ ......   ....       ...',;'..':lloooooolllll;''. .,:lodoolllooolc:,...cxo':0K00KKKKKK000K00000000000
000Kx..........''....... .......    ..',;;'. ......,:;'..,loolllllll,  ...:llodolllloool,....,ooo;,xK0KK0KKKKK000000000000000
000Ko......',,'.................  .;cooooxdc........,::c;..;lllllll;    ..,looolllloool'   ..;ooc'l0K0KKKKKKKKKKK000000000000
0KKKl..,,,'',:c. .'........... ..:lolloolc:l,.........,::;'.'loolol.    ..,lolllllodoo;    ..,ol..c0K00KKKKKKKKKK000000000000
KKKKl.,;::ldk0Kc .'........... ,odxxdooc'':o:..'......':c::,.,clool.    ..,lollllooool'    ..,c'...dK0000KKKKKKKKK00000000000
0KKKOxxO0KK0K0Kx..'...... .... 'oddxdl,.,lllc..........':ccc,..:ooc.    ..;oolllodolol.    .';'....,kK00K000KKKKKK00000000000
KKKKK0000KK0K0K0c.''.......... .:oodo:,:c:cdc. ..''.....';;::. .loo,   ...cxxolodoolc:'..,;.,,....'.:0K00KKKKKKKKK00000000000
KKK0KK00KKK0KK0Kk'.,........... .lodl;oKOldXx'...'......':::;. .:olc.  ..;oddlodollc:clcckkc:;....,..xK0KKKK00KKKK00000000000
00000000000000KKKl.''........... ;dlllcdOxldodc..........;cc:'..,llll:;;codooddooooooddc;oxc:;....;;.c0KKKKKKKKK0K00000000000
00000000000000KKKO,.,........... .:cdOOklcddldl...........;::'...lollllooooddollolcclolc;;:cdl....;:.,OKKKKKKKKK0K00000000000
00000000000000KK0Kd.',.........  ,:,',cxxlodcoOc..........;:;.. .collooooddolcllllccc::ccldkx;....,:..xK0KKKKKK00000000000000
00000000000000KK000l','........ ,O0k:c0Kxcd0k:;'..........;c;.. .:olooooddol:'';;;;,''coloo:'.....,:..xK0KKKKKK00000000000000
00000000000000K0KK00c''....... .xKKKOdddocoKKl'::..'......,:,....':loodxdllllc;,'''..;ll;'.......':c''xK0KKKKKK00000000000000
00000000000000K0KK0KOc''..... .dKK0KKKKKKOdddokK0c.'......',....   ..';;:cloooolcccc:,'....... ..':c.,OK0KKKKKK00000000000000
000000000000000KK0K0KO:''... .d000K0KKKK0KK000K0KO:.'.....''... ....    .:c:;;::::::l:...........';:.:0KKKKKKKK00K00000000000
000000000000000000KKKKOc....,kKK0KKK000K0KK0000K0Kk;.'........ .:ollcc,.cK0Okxddddk0K0l.........';:,'dKK0KKKKKK00K00000000000
000000000000000KKKK00KKOl,,lOKK0KK00000KK000000K00Kk;.'......  'oddolo,.dK000KK0KK0KKK0c........,cc';OK00KKK0KKKKK00000000000
000000000000000KK00KKK00K0O0K0KK0K00000KKOkxddxOKKKKx'.'......:loodoll''kK0K0K000KK000KOc......':c,'dK00KKKK0KKKK000000000000
000000000000000KK000K000KK0000KK00K0kxdoc,,,'..':c:;;,..'....:ooloollo,,OK0K0000K00K00KKOc.....;c;'l0K00KKKK0KKKK000000000000
00000000000000000KKKK000KK0KK0KKOd:,,''..;col:;..,:clol;'...;loooolldd,'okxxxkO0KKKKK00KK0o...,c;'l0K00KKKKKKKKKK000000000000
000000000000000KK00KKKK0KK00KK0o;,;coloc.;llo::'.cdollodl;,:loooolldxdc...,,,,:x0KKK00000K0x;',,;d0K00KK0KKKKKKKKK00000000000
000000000000000KKKKKKKKK0KK0KO:'cdloooo:.lo:ol:;.'lloddooddolooolloxdoc..;lclx,.;:cox0KK00KK0xldOK00K0KK0KKKKKKKKK00000000000
00000000000000KKKKKKKKKK0K0K0:.:xdolood;.:dccdl:;.,odooodxdooooolloxo:.';co::ko.:l:,,;lkK00K0KKK0K0KK0000KKKKKKKKK00000000000
00000000000000KKKKKKKKKKKK0Kd.;ooddddoo,;kXKxodo:;,',:loooolooollooc'.,:lo::d0k,,ooolc''d000KK00KKK0KKKK0KKK0KKKKK00000000000
000000000000000KKKKKKKK0KKKO,.loloooddc,xX00Oooddl:;,'',;;;:cccc:;'',:looc:lkNXl,looooo,.dK000000K000000000000000000000000000
000000000000000KKKKKKKK00KKl.,ooodddoocckkxdxddxxooolc:;,'......',;codxdx00OKNNd':oolool.,OK00KK0K000000000000000000000000000
000000000000000KK0KKKK0K0KO; ;oddolodc:kOdoxxdd0Kocolccclc,.''.,coloxxxxdxkOXNKd''ooooll'.xK00KK00000000000000000000000000000
000000000000000KK0KKK0000Kk'.lxollool,lXNxlooxOKN0dddooool:',,':dkkOK0dxkxdokXNKl':doool,.oKK00KKK000000000000000000000000000
000000000000000KKKKKK00K0Kx..collloo;'dXKOxk0XNXOdoxxd0N0c,cd,.:O0KNN0dododxOKXXO,'ooooo,.lKKK0KKK000000000000000000000000000
000000000000000KKKKKK0KK0Kd..collool''odllxKNNNKxkxxkdkXk,.:o;,cxdo0NNKOolcdOOOOk;.ooloo,.lK0KK00K000000000000000000000000000

*/

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract WoodiesCoreCharacters is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    string public _contractURI;
    string public _baseTokenURI;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Woodies Core Characters", "WOODIESCORE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

         _contractURI = "ipfs://QmU91u5nbdMSgGBWZQkptuHnJJXeu5XNRjTuxsA2TdNdHZ";
         _baseTokenURI = "https://woodiesnft.com/api/core/";
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;    
    }    

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     function setContractURI(string memory uri) external onlyOwner{
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

}