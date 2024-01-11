// SPDX-License-Identifier: MIT
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/*
WWWWWWWWWNkc''''...'...'...............................  .     ..,o0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWWKd;..''''''..''...............        .............  ......,xKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWW0l'..',''......................                    ... ......':oKWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWO:'...'''..................................               .   ..'oXWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWW0:....'................  ........     ..........             .   .,dKWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWNd'...................  .............       .........              .:xXWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWNd'..............................................................  .'c0NWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWd'................    .........''..''''',,,,,,,''.'',,;,,,',,,,,....cONWWWWWWWWWWWWWWWWWWWWWWWW
WWWWNd................   .....',,;;;;;;;;:::cccclllllccccccc::::::ccc;...cONWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWx'....     ............,,;:ccccccccccccllllllllllllcccccccccccccl:..ckXWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWx,....      ..........',:cclllllllllllllloooooooooolllllllllllllll;':OXWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWk,....        ........';:clllllllloooooooddxxdddddddooodddxddoolcl:,lONWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWO,....    ............';:looooooooddddxxxkkkkkkxxxxxxdxxkkxxdlc:,';lONWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWW0;....................';loooooodddooddddxxxxxxxxdxxxxxxkkxdl:,''',;oXWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWKc...................,:loooooooolc;;;;;;;;;;;::clodxkkkkxdl:;::clooxXWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWXo.................';clooddddollccccccccccccclllllodxxxdollllllooooxXWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWNx................':lloodddddddxdooooooooollllooooodddoolllllllllolxXWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWKc... ...........,clooddxxxxxxxdddoooollccllllooooddollllll:;,,;:cxXWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWNd'.............';looddxxxdddooolcccc;,',;:lloodddxxdooooodc..;::cdKWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWW0ddxdoc;'....'',:ldddxxxxxdolcc::coo:'.;:codddxddxkxdoddool::llood0NWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWNOxdooodol:,..',;cddxxkkOOkxdollllloooccllodxxxxddxxxddddoolllooddxkXWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWKxdoddddlllc;'',:lxxxkkOO000OkxddddddooooddxxxxdddxxxxdddddooooddxxkKWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWXkdodddo:;col;,,:oxxkkOO000KKK0OOkxxddddxxxxxxxxddxxkkxdddddddddxxxxKWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWKkddxdocldddl;;codxkkkOO00000K00OkkxxxxkkxxxxxxddxkOOOkxdddxddxxxdxKWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWWKxxxddooddxdolldddxxkkkOOOO000OOOkkkkkkkxxxxdddxkOOOOOxxdxxxdddddONWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWWNKOkxxOkdodddoodddddxxxxkkkkkkkkkkkkkkkkxdoodxkOOOkOOOkdddddddddxKWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWWWNK00000OxddooooodddddxxxxxxkkkkkkkkkkkxdolldxxdlloddddoodddddddONWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWWWWWNK000000xooooooooooddddddxxxxkkkkkkkkxdollllllcccclllllodddddoclodkO0KXNWWWWWWWWWWWWWWWWWWW
WWWWWWXKOxdoodxxxlclooooooooooddddddxxxxxxxxxxxdddddoooodooooooodddddo:;;;;;::cloxkkO0KXNNWWWWWWWWWW
WWWX0Oxddoollclllc:lllloooooooooodddddxxxxxxxxxxxddxxdddooooooooooddo:,,,,,;;;;:::::ccllodxk0KXNWWWW
X0Oxddddooolllcc:;;cllllllloooooodddddddddddddddddddxxxdddddddoooodo:,,,,,,,,;;;;;;;::ccccccllodkOKX
xddddddoolc:;,,'..,:cllllllloooooddddddddddddddoodddxxdoollllcccloo:,',,,,,,,,;;;;;;;::::ccccccccllo
xddddolc:,''....'::;:cccllllooooooddddddddddddooollcc;,'.....,;codc'.''''',,,,,,,;;;;;;;::::ccccclll
dddol:;,'''...':c::,,:ccccllllooooooddddddddddol:,,'''''''..,;cloc'.....'''',,,,,,,;;;;;;;::::cccccc
ooolc:::;,'..;cc::;,,:c:ccccllllooooooooddddddolc:;;:::::;;::clol,.......''''',,,,,,,,;;;;;:::c:::cc
llllcc:;,'',:ccc:;;;,:::ccccccclllooooooddddoooollcccc::ccccccll;..........'''',,,,,,,,;;;;;::::;::c
llccc:;;,,;clccc:::;;:c:cccccccccllllllooooooooollcccccc:ccccll;'............''',,,,,,,;;;;;;:::;;::
llccc:::::clccccc:::;:::ccc:::::::ccclllllooooolllccccccccllll:'..............''',,,,,,;;;;;;;::;;::
lcccccc::cccccccc:::;;:ccccc:::::::::ccccllllllllllllllllllll:'................''',,,,,,;;;;;;;:;,;:
cccccc:::cccccccc::::;:cccccc:::::::::::::ccllllllllllcccccc;,''................'',,,,,,,;;;;;;;;,;;
cccccc::c::cccccc::::;;:cccccccc::;;;;;;;;::::cccccccc:::::;,'''''..............''',,,,,,,;;;;;;;,;;
ccccc::c::::ccccc::::;,,:ccllllllccc:::;;;;;;;;;;:::::::::;'''''''...............'',,,,,,,,,,;;;;,,;
cc:::::::;::cccc:::::;;',:cclllllllllccc::::::::::::ccccc;''''''''.'.............''',,,,,,,,,,,;;,,;
c::::;;;;;::ccc:::::;;;,',;:cllllllllllcccccccccccccccc::'.''''''''''.............''',,,,,,,,,,;;,,,
:::::;,,;::ccc::::;;;;;;'',;:cclllllllllcccccccccccccc::;'.''''''''''''...........''',,,,,,,,,,,,,,,
:::::::,',::::::::;;;;;,,',,;::ccllllccccccccccccccc::::;'.''''''''''''''''''''....''',,,,,,,,,,,,''
::::;::;,,;:::::;;;;;;;,,,;;;;;:ccccccccccc:::::::::::::,..''''''''''''''''''''.....''',,,,,,,,,,'''
;;;;;;;;;;::::::;;;;;;;,,',;;;;;::cccc:::::;;;;;;::::::;,'''''''''''''''''''''......'''''''''',,,'''
;;;,;;;;;;;;:;;;;;;;;,,,,,,;;;:::::::::::::::::::::::::;,''''''''''''....'''''.......'''''''''''''..
;;;,,,,;;;;;;;;;;;;;,,,,,,;:::::::::::::::::::::::::::;;;,''''''''''.......'''.......''''''''''''...
*/
contract EmotionalDamage is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseURI = "";
  uint256 public cost = 0.022 ether;
  uint256 public maxSupply = 2222;
  uint256 public maxMintAmount = 2222;
  bool public paused = true;

  constructor(
  ) ERC721("EmotionalDamage", "ED") {}
  function contractURI() public view returns (string memory) {
    return "https://gateway.pinata.cloud/ipfs/QmYLWmnLu4YEH9f5JHhforLmHJ5iMgxY5bVVvo7iULAe4m";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value >= cost * _mintAmount);
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }


  function pause(bool _state, string memory _newBaseURI) public onlyOwner {
    paused = _state;
    baseURI = _newBaseURI;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}