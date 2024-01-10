// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

// KKKKKKKKKKKKKKKKKKKKKKKKXXXNNNNNNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKXXXNXXNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxddxk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKKKKKKKko:;;;::::::cok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNNNXXKKKKKKKKKKKKKK
// XKKKKKKKKKKKKKKKKKKKKKKKKkc',cdkO00Okdc,..;ldolllllllcccccclodxkO0KKKKKKKKKKKKKXXXXXKKKKKKKKKKKKKKKK
// XKKKKKKKKKKKKKKKKKKKKKKkc',ok00Oxoc;;;;,.....':lloooooooolllc::;,;;coxkO0KKKKKKKXKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKKKKOl''lk0Oxl;,,codl;';cllc:dOOOOOOOOOOOOO00Okxdl:;,'',;:oxO0KKKKKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKK0o,'cx0Od:',cdOkl,'cdOOO0OOOOOOOOOOOOOOOOOOOOOOOOOkxolc:;,';cd0KKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKKO:.;xO0kc.,lk00Ol.;xOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOO0OOkdl;.,d0KKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKKO:.:k0Ox,.:k0000x,'xOOOOOxolcclxO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOd,.:odkKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKK0c.;k00d,.lO0000Oc.lOOOdc,',:c:,';:lkOOOOOOOOOOOOOOOOOOOOOOOOOOOd;;o;.'cOKKKKKKKKKKK
// KKKKKKKKKKKKKKK0l.;x00x,.oO00000x,,xOo;.,lOXWMWXx,..,dOOOOOOOOOOOOOOOOOOOOOOOOOd';KW0l'.c0KKKKKKKKKK
// KKKKKKKKKKKKKK0l.,x00O:.lO00000k;'okl.'dXWMMMMMMMKk:.;x0OOOOOOOOOOOOOOOOOOOOOOOl.;KMMNx.'kKKKKKKKKKK
// KKKKKKKKKKKKXKo.,x000x,;k00000Oc.ckl.'xWMMMMMMMMMMM0,.lOOOOOOOOOOOOkkxkkkOOOOO0x,.c0WWx.;OKKKKKKKKKK
// KKKKKKKKKKXXKo.,dO000OodO0000x:.:kd'.cXMNOd0MMMMMMMX:.cOOOOOOOkoc:;,,,,,,;:dOOOOl..'::''dKKKKKKKKKKK
// KKKXXXXXXXNKl.,x00000000000Oo''lk0o..cXNo..ckKWMMMMK;.cOOOOOkl;:clodxxddolcoOOOOkddoc:,';oOKKKKKKKKK
// KKXXNNNNNNXd.,x00000000000kc.,dOO0d'.'k0;''.'xWMMNKo.'dOOOOOOxkOO0OOOOOOO0OOOOOOOOOO0Okd:.;kKKKKKKKK
// KKXXNNNNNNK:.lO000000000Ox;.;xOOOOOc..,dddooONN0d;'.'oOOOOOOOOOOOOOOOOOOxoxOOOOOOxxOOOO0Oc.:OXXXKKKK
// KKKXXXNNXNK:.l00000000Od:'.:kOOOOOOkl'..':ccc:;...':dOOOOOOOOOOOOOOOOOOOx:,oOOOkc;oOOOOO0d''kNXXXXXK
// KKKKKXXXNNXl.:O000000Ol...,x0OOOOOOOOxc;'.....';lxkOOOOOOOOOOOOOOOOOOOOOOOllkO0xcdOOOOOO0x,.xNNNNNXX
// KKKKKKKXXXNx.,k00000Ol....cOOOOOOOOOOO0OkxdoodxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0k,.dNNNNNNX
// KKKKKKKKKKXk''x00000x,.'.,x0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOO0000OOOOOOO0x,.dNNNNNNX
// KKKKKKKKKKXk'.d00000d'...lOOOOOOOOOOOOOOOOOOOOOOOOOOOOxo:;;;:cdkOO0OOOOOOkxolccccldxkO00Ol.;ONNNXNNN
// KKKKKKKKKKXO;.o000O0o...,x0OOOOOOOOOOOOOOOOOOOkkkxdl:;'.,ll,,:;,;:looolc;,..,cl,....';:c;.;OXXNNNNNN
// KKKKKKKKKKK0c.lO000k;...cOOOOOOOOOOOOOOOOOdc;,,''......:dxdd0XKOxolllllod:..';,..........lKNNNNNNNNN
// KKKKKKKKKKKKo.;k00Oc...'d0OOOOOOOOOOOOOOx:..............oKXXXXXXXXXXXXXXXk,.............,ONXNNNNNNNN
// KKKKKKKKKKKKO;.o0Oc.''.:kOOOOOOOOOOOOOOOl:clccccccccccc:;:kXXXXXXXXXXXXXXXx'.:lllllooo;.cKNNXNNNNNNN
// KKKKKKKKKKKKKd''c,.:c.'dOOOOOOOOOOOOOOOOOOOOOO00O0000000k:,xXXXKxlxKXXXXXKOkc,lOOOOO0x,.dXNNNXXXXXXX
// KKKKKKKKKKKKKKxc:lo:'.,okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0d'cKXXd;l:c0XXXKx:d0l.ckOOOx;.c0KKXXXXKKKKK
// KKKKKKKKKKKKKKKKKk;.;;'.';lkOOOOOOOOOOOOOOOOOOOOOOOOOOOO0o.cKXKlcKk;oXXXXkokXO;.lOkl''lOKKKKKKKKKKKK
// KKKKKKKKKKKKKKKKk,.:oooc;..'cdkO0OOOOOOOOOOOOOOOOkxxdxxkx;.dXX0coNK::0XXXXXXXXo.':,.:kKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKKx,.;ooooool:,'.,:loxkOOOOOOOOOOOOd:,,,,,,'.c0XXO:dNK::KXXXXXXXXx'.;lk0KKKKKKKKKKKKKKK
// KKKKKKKKKKKKKKx'.;oooooooooolc:,''',;:clodxxkkOOOkkkkxxo',kXXXKdlol:dXXXXXXXXXd..:kKKKKKKKKKKKKKKKKK
// KKKKKKKKKKKKKd'.:oooooooooooooooollc;;,'''''',,,;;;;:::;.cKXXXXXKOO0XXXXXXXXXk,.'.'o0KKKKKKKKKKKKKKK
// KKKKKKKKKKKKo..:ooooooooooooooooooooooooollccc:::;;;;;,'.lKXXXXXXXXXXXXXXXXX0:.;lc'.c0KKKKKKKKKKKKKK
// KKKKKKKKKKKo..:oooooooooooooooooooooooooooooooooooooooo;.cKXXXXXXXXXXXXKkk0Xd.'lool'.c0KKKKKKKKKKKKK
// KKKKKKKKKKd'.:ooooooooooooooooooooooooooooooooooooooooo:.,kXXXXXXXXXXXOllococ.,ccooc'.oKKKKKKKKKKKKK
// KKKKKKKKKx'.;ooooooooooooooooooooooo:,colllooooooooooool,.:0XXXXXXXXXXolKNo;:...'loo:.,xKKKKKKKKKKKK
// KKKKKKKK0c.'coooooooooooool:;;;:lool'.,;;;,,;looooooooool'.c0XXXXXXXXXd:OWx:dc...;lol,.:0KKKKKKKKKKK
// KKKKKKKKO:.,loooooooooooc;,,;;'.:ooc..:lllc:'';loooooooooc'.c0XXXXXXXX0::xl:OO;...coo:.'xKKKKKKKKKKK
// KKKKKKKXO;.;oooooooooool,,clll;.,oo:..:lllllc;.'coooooooooc.'kXXXXXXXXXO:';xXXx'..;ool'.lKKKXXXXXKKK

contract KevinKaijuz is ERC721Enum {
  using Strings for uint256;

  uint256 public constant SUPPLY = 7777;
  uint256 public constant MAX_MINT_PER_TX = 10;
  uint256 public freeSupply = 555;
  uint256 public price = 0.00777 ether;
  
  address private constant addressOne = 0xF27a3f8823c47e35E863dF2F853895fb5741994E;
  address private constant addressTwo = 0x6E39Ff2fD5CEDEf3F4968843ce2a05cD9f6aD4D0;


  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("KevinKaijuz", "KKJ") {
    owner = msg.sender;
  }

  modifier mintOpen() {
    require(!pauseMint, "mint paused");
    _;
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  /** INTERNAL */ 

  function _onlyOwner() private view {
    require(msg.sender == owner, "onlyOwner");
  }

  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  /** Mint NFT */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max10perTX"
    );
    require(
      currentSupply + amountPurchase <= SUPPLY,
      "soldout"
    );
    if(currentSupply > freeSupply) {
      require(msg.value >= price * amountPurchase, "not enough eth");
    }
    for (uint8 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }
  
  /** Get tokenURI */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent meow");

    string memory currentBaseURI = _baseURI();

    return (
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : ""
    );
  }

  /** ADMIN SetPauseMint*/

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    pauseMint = _setPauseMint;
  }

  /** ADMIN SetBaseURI*/

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  /** ADMIN SetFreeSupply*/

  function setFreeSupply(uint256 _freeSupply) external onlyOwner {
    freeSupply = _freeSupply;
  }

  /** ADMIN SetPrice*/

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /** ADMIN withdraw*/

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(addressOne, (balance * 32) / 100);
    _withdraw(addressTwo, (balance * 64) / 100);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}
