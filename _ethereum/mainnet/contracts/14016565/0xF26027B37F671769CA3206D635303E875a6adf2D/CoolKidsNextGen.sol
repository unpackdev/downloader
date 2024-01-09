// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

//   _____            _ _  ___     _     _   _           _    _____            
//  / ____|          | | |/ (_)   | |   | \ | |         | |  / ____|           
// | |     ___   ___ | | ' / _  __| |___|  \| | _____  _| |_| |  __  ___ _ __  
// | |    / _ \ / _ \| |  < | |/ _` / __| . ` |/ _ \ \/ / __| | |_ |/ _ \ '_ \ 
// | |___| (_) | (_) | | . \| | (_| \__ \ |\  |  __/>  <| |_| |__| |  __/ | | |
//  \_____\___/ \___/|_|_|\_\_|\__,_|___/_| \_|\___/_/\_\\__|\_____|\___|_| |_|

// XXXXXXXXXXXXXXXXXXXXXX0OOKXXXXXXXXXKOOOOOOOOOOOOOOOOOOOOOOkxdolcccccld0X0KXXXXXXXXXXXXXXXX
// XXXXXXXXXXXXXXXXXXXXX0kOKXXXXXXXXXKOOOOOOOOOOOOOOOOOOOxl:,,,;;;::cc,. oX0OKXXXXXXXXXXXXXXX
// XXXXXXXXXXXXXXXXXXXX0kxkKXXXXXXXXKOkOOOkdolc::;,;;;,,;;;cldkOOOOOOd'.:xOKOOKXXXXXXXXXXXXXX
// XXXXXXXXXXXXXXXXKKK0kxxxkKKKKXXXKkl::,'..'';:ccloxxooxOOOOOOOOOOkc..,;,'ckO0XXXXXXXXXXXXXX
// XXXXXXXXXXXXXXXKOkOOkxkOkkkxOXKx;..,;:loxkOOOOxldOOOOOOOOOOOOOOo'  .'cxc.;kOKXXXXXXXXXXXXX
// XXXXXXXXXXXXXXKOkkkOOkkkkkxlc:'.'lkOOOOOOOOxc,,lkOOOOOOOOOOOOkc.  .cxOOx'.lkOKXXXXXXXXXXXX
// XXXXXXXXXXXXXKOkOOOK0kkxc;'.  'lkOOOOOOOOkc,;ldOOOOOOOOOOOOOd'  .cxOOOOO: ;kOKXXXXXXXXXXXX
// XXXXXXXXXXXXK0k0XXXX0d:'','.,okOOOOOOOOOkc,oOOOOOOOOOOOOOOk:. 'lkOOOOOOOl.,kOOKXXXXXXXXXXX
// XXXXXXXXXXXK0k0XXKx:'.;ol,;oOOOOOOOOOOOOOkOOOOOOOOOOOOOOOd'.,okOOOOOOOOOd..x0kOOOKXXXXXXXX
// XXXXXXXXXXX0kOX0o'.,lxOxcokOOOOOOOOOOOOOOOOOOOOOOOOOOOOOl';dOOOOOOOOOOOOx'.dXK0Ok0XXXXXXXX
// XXXXXXXXXXKOOKO,.;dOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOxcoOOOOOOOOOOOOOOd..xXXXKOOKXXXXXXX
// XXXXXXXXXXOk0Xo ,kOOOOOOOOOOd:dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOk, ,lkXXX0k0XXXXXXX
// XXXXXXXXX0kOXXc ,kOOOOOOOOOd,cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOk:  ..cKXXKOOKXXXXXX
// XXXXXXXXKOOKXo. ,kOOOOOOOOO;;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOc  ,d:'kXXX0k0XXXXXX
// XXXXXXXKOk0Xk.  ,kOOOOOOOOk,;kOOOOOOOOOOOOOOOOOxxOOOOOOOOOOOOOOOOOOOOl.'okOl.lXKX0kOKXXXXX
// XXXXXXX0kOX0;.,.'kOOOOOOOOO;.dOOOOOOOOOOOOOOO0o.:OOOOOOOOkolokOOOOOOklckOOOo.:0OOkkkO00KXX
// XXXXXXKOOKXd.'dooOOOOOOOOOOl.;OOOOOOOOOOxoc:cl, ;kOOOxl:'...ckOOOOOOOOOOOOOd.;0OkkkOkxxk0X
// XXXXXX0k0XXl ,kOOOOOOOOOOOko..oOOOOOOkl,.,cdOKo..ll;'.';ld,.dOOOOOOOOOOOOOOd.,xkkkkkkkOOKX
// XXXXXKOO0XXd..dOOOxoxOOxl;.';..dOOOOd'.,d0XKXXO, ..;lx0KXKc.lOOOOOOOOOOOOOOd.,kkkkOOk0XXXX
// XXXXX0kkOKX0; :OOk,.cl,..,oO0l.'dOOo..oKKKKKKKKOxdl;,;xKKK: cOOOOOOOOOOOOOOd.,xxkOKKOOKXXX
// XXXXKOkxx0XXx..oOc  .':ccccc::;..ll..oKKKKKKKKKKx;;oo,,xX0; ;oc;'',:dOOOOOOd.;kOOOKXOk000K
// XXXX0kxxxOKK0c ,o' .oKKKKOxoox0x;..'dKKKKKKKKKXKOk0KK0O0KKl...  ..  .lOOOOOc'dXXXXXX0kkOkO
// KO00Oxxkkkkkkd,....o0OxxxxxkOKKKKOk0KKKKXKKKKKKKKKKKK0KKKKKkxoclkO,  ;kOOkc.cKXXXXXXX00K0k
// OkkOkxkOOOOOOOd' .;kKo'..:;.,kXKKKKKKKKKKKKKKKKd,'',;:;;xXKKKKx;oO,  cOOx;.:OKXXXXXXXXXXKO
// Okkkkkkkkkkkkxxd:',xXKo.:N0,.kXKKKKKKKKKKKKKKXKOd,.l0Kc.lXKKKKxdk:  :kOd'.,ccxXXXXXXXXXXX0
// kOkkOKKKKKKKkxkkxc:xKKk,.:,.:0KKKKKKKKKKKKKKKKKKXo.,xd'.xXKKK0dc. .ckOd' .  ,xKXXXXXXXXXXK
// OK00KXXXXXXKOkkkxxdxkkkxl::o0KKKKKKKKKXXXKX0OO0KKKd;'.,xKKKKXk'  ,dOOOx:...ckOO0XXXXXXXXXX
// 0XXXXXXXXXXXX0OOOl';k00KKXXKKKKKKK0xdoollol;lk0XKKKK00KKKKKKKK: ,kOOOo;..cxOOOOk0XXXXXXXXX
// KXXXXXXXXXXXK0OOOk;.;kKKKKXKKKKKKKkl::;:::cd0XKKKKKKKKKKKKKKKKl ,kkl,.'lkOOOOOOkOKXXXXXXXX
// XXXXXXXXXXXX0OOOOOkc..:d0XKKKKKKKXXXXXXXXXXXKKKKKKKKKKKKKKKKKXo .;'.'lkOOOOOOOOOOKXXXXXXXX
// XXXXXXXXXXXKOOOOOOOOxl'.'cdOKXXKKKKKKKKKKKKKKKXKKKKKKKKKKKKKOd,   'oOOOOOOOOOOOOk0XXXXXXXX
// XXXXXXXXXK00OOOOOOOOOOOdc,..,coxO0KXKKKKKKKKKKKKKKKXKKKKKX0d,  .  .':lxOOOOOOOOOO0XXXXXXXX
// XXXXXXXXKOOOOOOOOOOOOOOOkl'.   ':xKXKKKKKKKKKKKKKKKKKKKKKKKd' ';. ',...,cdOOOkkkkk0KKKXXXX
// XXXXXXXXOkOOOOOOOOOOOOd:... ...l0KKKKKKKKKKKKKKKKKKKKKKKKx:..,;. 'lllc;'..,dOOkkxxxkkkOO0K
// XXXXXXXKkkOOOOOOOOOOo,..,cc..'..,okKKXKKKKKKKKKKKKKKK0xl,..'::. 'cllllllc. .lkOkkxkOkxxkk0
// XXXXXXX0kkOOOOOOOOOc..,clll' .:,...':lxkOOOO000OOkdl:'..';cc,. ,lllllllc. ...,dxxkkkkkOOOk
// XXXXXXKOxxOOOOOOOOo. .cllll; .:lc:;'.................,;ccc:' .;lllllll;. 'cc' 'okkkOOOOOOk
// XXXXXX0kxxkOOOOOOd. . .:llll' .;cccccc:::;;;;;;;::cccccc;'..'cllllllc, .;cc,.  'xOOOOOOOOO
// XXXXXKOxxkxkOOOOk, 'c' .:llll;. .;ccccccccccccccccccc:'...':lllllllc. .::'..'c;.,kOOOOOOOO
// XXXXX0kxkOkkkkkko' .:c, .:llllc,. .,:ccccccccccccc:,...';cllllllll;. ';'..:x0XO; :OOOOOOOO
// XXXXKOkxkOOOOOOOkc...';. 'llllllc,.  .';cccccccc;....;cllllllllll,..'...ckKKKKXx..oOOOOOOO
// XXXX0kkkkkkkkkxkkoldc.   'lllllllll:,.....,;,'....,cllllllllllll,  ...cOKKKKKKKKc ,kOOOOOO
// XXXKOkOOOOOOOOkkkkxxkl.  ;lllllllllllll:,'.....,:llllllllllllll:.  .;xKKKKKKKKKXk'.lOOOOOO
// XXX0kkOOOOOOOOkc:dOkkkl..:lllllllllllllllllclllllllllllllllllll:. 'dKKKKKKKKKKKKKc ,kOOOOO
// XXKOkOOOOOOOOOd..dXKKKo .collllllllllllllllllllllllllllllllllllc..oXKKKKKKKKKKKKXx..dOOOOO

contract CoolKidsNextGen is ERC721Enum {
  using Strings for uint256;

  uint256 public constant COOL_KIDS_NEXT_GEN_SUPPLY = 5000;
  uint256 public constant MAX_MINT_PER_TX = 10;
  uint256 public coolKidsFree = 1000;
  uint256 public price = 0.01 ether;
  
  address private constant addressOne = 0xb0039C1f0b355CBE011b97bb75827291Ba6D78Cb
  ;
  address private constant addressTwo = 0x642559efb3C1E94A30ABbCbA431f818FbD507820
  ;
  address private constant addressThree = 0x1D3c99D01329b2D98CC3a7Fa5178aB4A31F7c155
  ;

  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("CoolKidsNextGen", "CKNG") {
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

  /** Mint CoolKidsNextGen */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max10perTX"
    );
    require(
      currentSupply + amountPurchase <= COOL_KIDS_NEXT_GEN_SUPPLY,
      "soldout"
    );
    if(currentSupply > coolKidsFree) {
      require(msg.value >= price * amountPurchase, "not enougth eth");
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
    coolKidsFree = _freeSupply;
  }

  /** ADMIN SetPrice*/

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /** ADMIN withdraw*/

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(addressOne, (balance * 30) / 100);
    _withdraw(addressTwo, (balance * 30) / 100);
    _withdraw(addressThree, (balance * 30) / 100);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}
