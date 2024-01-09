// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "MerkleProof.sol";
import "ERC721Enum.sol";

//   _____            _   _  ___     _        _____ _       _     
//  / ____|          | | | |/ (_)   | |      / ____| |     | |    
// | |     ___   ___ | | | ' / _  __| |___  | |    | |_   _| |__  
// | |    / _ \ / _ \| | |  < | |/ _` / __| | |    | | | | | '_ \ 
// | |___| (_) | (_) | | | . \| | (_| \__ \ | |____| | |_| | |_) |
//  \_____\___/ \___/|_| |_|\_\_|\__,_|___/  \_____|_|\__,_|_.__/ 

// MMMMMMMMMMMMMMMMMMMMMMMMMWNNXXKK0000OOOOOOOO0000KKXXNNWWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWN000000OOOOOOOOOkkkOOOOOOOOOOOOOO00KXNWWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOo;....,:cdxOOOkl,'..',,;coxkOOOOOOOOOOO0KXNWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMNOo;'........ ..':ldc. ...... ..';lxOOOOOOOOOOO00XNWMMMMMMMMMMMMMM
// MMMMMMMMMMMWKd:'..................'.  ............;okOOOOOOOOOOO0KXWMMMMMMMMMMMM
// MMMMMMMMMMW0l. .....................  ............ .'lkOOOOOOOOOOOO0XWMMMMMMMMMM
// MMMMMMMMWX0Oko;. ................................... .'clldxkOOOOOOOO0XWMMMMMMMM
// MMMMMMMNKOOOOOOd;. .........................................';lxOOOOOOOKNWMMMMMM
// MMMMMNOdollllllll;. ......................................... ..:dOOOOOO0XWMMMMM
// MMMMKc............   ........................................... .:xOOOOO0KWMMMM
// MMM0:............................................................. .okOOOOOKNMMM
// MMNOc.............................................................. .:kOOOOOKNMM
// MWKOOx:.............................................................  :kOOOOOKWM
// WX0OOOOd;. ...........   ........................ ................... .ckOOOO0XW
// N0OOOOOOOo,............  ..'lo'.............;oxOc..................... .dOOOOO0N
// X0OOOOOOOOx:. ..... .:,  'lOKO; ...... ..;oOKKX0; .................... .oOOOOO0X
// KOOOOOOOd:'....... 'xx, .o0KKKc..... .;x00kdkKXO,  .'................. .lOOOOOOK
// 0OOOOko,......... 'xKKkdc;dKKKd.... .dK0Oo;ckKKKxldOx'................ 'xOOOOOO0
// OOOOd,   ....... .oKKKKK0OOKKKO;  .;kKKK0kkOOkOKKKKKo................ .lOOOOOOOO
// OOOOo,,:loooll:. ;OKx:,',cxKKKKOocd0KKKKKOl'...,d0X0:  .':;.........  'okOOOOOOO
// OOOOOOOOOOOOOOk,.oKd..:o;..dKKKKKXKKKKKK0c .dOc..dKKo',clkx. ........ ...,cdkOOO
// 0OOOOOOOOOOOOOd.'kKo..o0d. lKKKKKKKKKKKK0o..cd:..dKKK00xld:............... .,ok0
// 0OOOOOOOOOOOOOd.'kK0o'....lOKKK0OkkkO0KKK0d:,'':xKKKKKKxl'................   .o0
// KOOOOOOOOOOOOOx'.xKKK0kkkOKXK0l......:kKKKKKK00KKKKKKKO,  ..........  ..,:clodkK
// X0OOOOOOOOOOOOO:.:0KKKKKKKKKKd.   .''.:0KKKKKKKKKKKKKK0; ............ .;xOOOOO0X
// WKOOOOOOOOOOOOOk;.;xKKKKKKKKO;   .,:;..xXKKKKKKKKKKKKKKc  ....   ....   ,xOOOOKW
// MN0OOOOOOOOOOOOOkl,';oOKKKKK0o:::::cccd0KKKKKKKKKKKXKKKo.  .',;:cllllcc:lkOOO0NM
// MWX0OOOOOOOOOOOOOOkd:'';ldO0KKK0K00000kkkkkxxdddooollc;.  ..;xOOOOOOOOOOOOOO0XWM
// MMWX0OOOOOOOOOOOOOOOOx;...,;::;;;,''''..'','''''''''',;;;::'.':okOOOOOOOOOO0XWMM
// MMMWX0OOOOOOOOOOOOOOko,'clllllllc,.. ..';coooooooooooooooooolc:''cxOOOOOOO0XWMMM
// MMMMWN0OOOOOOOOOOOko,':looooooooo;.'...';looooooooooooooooooodkOo'.cxOOOOKNWMMMM
// MMMMMMNK0OOOOOOOOx;.:OOdooooooooo;......;coooooooooooooooooooodOXO:.'oO0KNMMMMMM
// MMMMMMMWXK0OOOOOo'.lK0doooooooooo:......,cooooooooooooooooooooodOX0o''dXWMMMMMMM
// MMMMMMMMMWX0OOOo..oXKxoooooooooooc... ..':ooooooooooooooooooooood0X0xxKMMMMMMMMM
// MMMMMMMMMMMWX0x'.lKXkooooooooooooc... ...;ooodxkxdoooolloooooooooxXWWMMMMMMMMMMM
// MMMMMMMMMMMMMWOcl0NOl,'coooooooool'.. ...,oodONWKxoooo;.:oooooodkKNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWNWXkc..coooooooool'.. .. 'lodOXN0xoooo:..codxk0XWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWNOllddooooooooo,.. .. .loodkOxdooool,.lOKXWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWWNK0Okxddooo;.. ....:ooooooddxkO00KNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0Okxc'......:dddxkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMM

contract CoolKidsClub is ERC721Enum {
  using Strings for uint256;

  uint256 public COOL_KIDS_SUPPLY = 4010;
  uint256 public constant PRICE = 0.06 ether;
  uint256 public constant PRE_PRICE = 0.05 ether;
  uint256 public constant MAX_MINT_PER_TX = 5;
  
  address private constant addressOne = 0xb0039C1f0b355CBE011b97bb75827291Ba6D78Cb
  ;
  address private constant addressTwo = 0x642559efb3C1E94A30ABbCbA431f818FbD507820
  ;
  address private constant addressThree = 0x1D3c99D01329b2D98CC3a7Fa5178aB4A31F7c155
  ;

  bool public pauseMint = true;
  bool public pausePreMint = true;
  string public baseURI;
  bytes32 private root;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("CoolKidsClub", "CKC") {
    owner = msg.sender;
  }

  modifier mintOpen() {
    require(!pauseMint, "mint paused");
    _;
  }

  modifier preMintOpen() {
    require(!pausePreMint, "premint paused");
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

  /** EXTERNAL */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max5perTX"
    );
    require(
      currentSupply + amountPurchase <= COOL_KIDS_SUPPLY,
      "soldout"
    );
    require(msg.value >= PRICE * amountPurchase, "not enougth eth");
    for (uint8 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }

  function preMint(
    uint16 amountPurchase,
    bytes32[] calldata proof,
    uint256 _number
  ) external payable preMintOpen {
    uint16 eligibilitySender = isEligible(proof, _number);
    uint256 currentSupply = totalSupply();
    uint256 buyerTokenCount = balanceOf(_msgSender());
    if (eligibilitySender == 0) revert("notWL");
    require(
      buyerTokenCount + amountPurchase <= 4, "Max4Presale"
    );
    require(
      currentSupply + amountPurchase <= COOL_KIDS_SUPPLY,
      "soldout"
    );
    require(msg.value >= PRE_PRICE * amountPurchase, "not enougth eth");
    for (uint8 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }

  function mintUnsold(uint16 amountMint) external onlyOwner {
    uint256 currentSupply = totalSupply();
    require(
      currentSupply + amountMint <= COOL_KIDS_SUPPLY,
      "soldout"
    );
    for (uint8 i; i < amountMint; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }

  /** READ */   

  function isEligible(bytes32[] calldata proof, uint256 _number)
    public
    view
    returns (uint16 eligibility)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_number, msg.sender));
    if (MerkleProof.verify(proof, root, leaf)) return 1;
    return 0;
  }
  
  /** RENDER */

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

  /** ADMIN */

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    pauseMint = _setPauseMint;
  }

  function setPausePreMint(bool _setPausePreMint) external onlyOwner {
    pausePreMint = _setPausePreMint;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setRoot(
    bytes32 _root
  ) external onlyOwner {
    root = _root;
  }

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
