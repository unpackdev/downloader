// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721AWithRoyalties.sol";
import "./CantBeEvil.sol";

/*
. . . .. . . . . . .. . . . . . . . . . . . . . . .. . . . . . . . . . . . .. .. . . . .. . .. . . .. .. . . . . . .  
 .:ttt;t;tt;ttt;ttt;t;tt;t;t;ttt;ttt;ttt;tt;tt;ttt;t;tt;ttt;ttt;ttttttttttt;t;t;;tt;ttt;t;tt;t;tt;t;t;t;tttt%ttttttt.  .
. 8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8 8  8     ..   
. 88             88             88                      8           88 8   8  .          88                       8.S   
. 8@     . .  .   .     .  . .  .   .    . . . . . .    .  .  .  .        . .. . . .  .  .   . . . .  .       .  .      
. @X888 .  8. . .   .. . . 8.  . .   . .  .   .  .8 .. . .  .  .  . . . . . .   .   .  .. . .  . .8 . .. . . . .  ..8   
. 8X     . . . . ..   .   .  .  . ..  . .  . . .  .   .   . .. ..  . .. .. .. . . .. . . . . .  . .  .  .  .  . .   @   
. 8@8     . . .    . .  . . . .. .  .  . .  .   .  . .  .  .  .  . .   .  .. ..... . .  . .   . .8 .  .  .  . .  . 8X . 
. S 88  .    . . .  . .  . . ..   .  . .  .  . . . .  .  .  . .. .. . . .  . . 8  . ... .  . . . .  . 8   .8 .8 . .88   
. 88 88  . .  . . .    .  . .  . . .  . .  . 8   . ..  . . . .  .8 . .  . .   . .  . 8.  .  .   . .8SX 8   .  .  .  ;   
. 8@@ 8   . . .    . . . . . .  .   .    .8X 88  .  .8.8.  .  .  .  . . .  ... . .  .  .  .  . .    8 8 8 .8.  .    8;. 
. SS 8   .  .  . . .  .   .   . . .  . .    8 8   .. .  . .  . . . .  .  ..   .  ..  .  .  .  . .   8 8    . .  .     . 
. 8@@     .  .  .   .  . . . .   . .  . .        .  . .  . .  . . . .  .   .  . .8 . . . . . .  .. 8     .    . . . .   
. 8X @8  . .  8    . .  . . . . .   . .         . .    .  .8.  .   . .  . . .888 8 .  8     .8.   .     . . . .  .      
. SX@ 8     .8 8 8  . .   .    .  . .  .       .  . . . .    .  . .   .8 . 8 @ 8 ....  8  .   . . .  . .   .  . .   ; . 
. 8SX 8  . .   8   .   . . . .  . .  .  . . . . . .  .   . . . . . . . .    8 8  . .       . . . . .  .  .  .  . ..     
. 8XX@    .8 8 8    . 8 8 8 . . .  .  . .  .  . .  .. . . . .8.   . .   .    8    .      . . . .  . .  .  .  .  .   : . 
. 8S 8     .      .  8 8      .  . . .   .  . .  ..  . . .. . . .   ... . .      . .     .  .   .  . . . . .  .  .      
. 8@@    .  .  . . .   8   . . . .  . . . .  . .  .. .. .8. . . ... .  . .          ....  .  . . .  .   .  . . .  8.8 . 
. 8X 8    . ..  .         . .   . .   .    . .  .  .   . .  . .  . . .    .   . . .. .. .8 .  .  . . .  . .   . . . .   
. 8@@      .:.:  . .       .  .    . . . . .  . . . . .  . . . .  . . . .  . .  .  8  .  .  .  . .  . .  .  .   .   8;. 
. SSX  8 .  . .  8  . . . . .  . .  .   .   .  . .  .  .  . .  . .   . . .8 . .  .8 8  . 8   . .  .  . 8    . .  . 88. .
. 8SX8 8  .  8X@8    .  .  . . .  .  . . . . .    . . . . .  ..   ..  .  .. .  .    888X 8   .  . . . 8 8    . .    . . 
. 8X 8     .   8    . .  . .. . .  . 8    .   . .  . . . . . .  .   . . . .  . .     8 88 8   .  .      8  .. . .   8;  
. SX@ 8  .   8 8    .  .  . . 8   8X 8   .  . . . .  . . . . . . . . . .   . . . .          .  .  . .       .   .     . 
. 8SX8    .        . .  .  8XX      8 8   8    .   . . . . . .  .  .  . .. .  . .  .   8     .  .  .      .  . . .  :   
. 8X 8     .       .  .  .   888  8 8    8 88   .. .  . .......  .8 .  .  . .  . . . .     .  .  .  . . .  .. .         
. SX@    .  .   . . . ..   8 8    8 8  .   8  .  . ......  .   .  .  .  . .  . .  . .  . .  .  .  .  .  . .  . . .  ; . 
. 8SX  8  .  . .   .    .   8       .  .      . . .   . ..  . .8. . . .  . . .  .  . .  . .  . . . .  .  .  .   .       
. 8XX8     . .  . . . .  . 8 8  . .  ....  . . . .  . .   ..  .  . . . .    . .  .    . .  . .  .   .  .  .8 .8. .  : . 
. SS 8  8.  . .  .   . .  . . .  .  .  . . 8 8  . . . . ..  .  .  .. .  .. .   . . . . . .  . .  . . .  .  .  . .       
. 8@@    8.    .  . .   .  .   . .8.  .  8 8   . .  .. .   . .  .. . . .  . . .  .  .   . . .  .8.  . .  . . . . .  ;   
. 8SX      . . ..  . . . .  . 8@8   . .  8 88  .. .8 8  . 8    .  . . . .  . . . . . ..    .   . . .   . . .    . .   . 
. SSX8   .  . . .. . .  . .  8  8 . .     8    ...8 8   .  88   .  . .   .  . .  .     . .  ..    .  . . .  . .    .: . 
. 8X 88  8.  .   . . ..  . .  8 8 . . .       .  8 8 8      8  ...  . ..  .  ...  . . . . .  . ..  . .  . . . . ..      
. SX@ 8    . . .  . . . . .  8   . .  .      .  .   8  .      ... .  .  . . .   . . . .  . .  .  . .8 . 8.   . .  8 @  .
. 8X 8 8 .   .. 88 . . .  . .   . . .  .  . . .  .   .. ...  . . . .. . .  . . . . ..... .  . .. .  .  8    .   . . : . 
. 8@@ 8   . . 8X 8  . . .. . . . . . .  .  . .:;%88@%@S@@@8S@@%.;8S8 .. . .   . .   .  .  . . . . . .  8  8   .  .8   . 
. SSX 8    . 8 8     .  .   ..: .   . .  .  8888S8S;XXt88:XXXXS;XX%888%    . . . . .... . . .  .  .    88 8 . . .       
. 8SX8    .   8 8   . . . . ...  ..    .  .8 8888St%ttXX;@t%8@@8X;:%;S%%%8.. . .  :%8   . .8 . . . . .8 8  . .   .  t . 
. 8X 8     .     8 .  .  . .   .  8   . .. 88%Xt:tS%8t8S88@@%88@8XX88@ ::88 8  .. t8%;   . .  .   .         . . .       
. SX@    . .        .  . .  . . .8 8    . 8888%@t8t@@SS%SS8S8X8SXtXS8;S.:8tSt 8   :8% . .   .   .  . .  . .S   8  8 @   
. 8SX  8    .   . .  .  . . . 8.8 8    . SSt%%@X@%8X@88X@8@@8@S8XSSt: . ...S;X:8:8@%%888 .. . . . .  . .  @ 88  .      .
. 8XX8 8   . . . . . . . .  . .       . 88 :88t;;t%@t88%%X X888tX@88tt. %   t8X 8@8t8 8   . . . .  .  .   8 8 8  . .% . 
. SS 88 8. .  . .   .   . .  .      .. t@%@t:.;.8%.X8 X %X;88 8..@ 8;888X  :8St : t888    . .  . .  .  . 8 8    .       
. 8X@ 8    .8.   ..  .. ..8. . .. .  . 8X%t@ : S;t888 @ @8%tt@:8@.;tX:X8.t@%;;%.;%X8 8   .   . . ..  ..    8   .  . 8   
. 8X 8 8  .8  . .  .  .88 8;8.:... .:X@8@tXtXS %%8X8888X:;;%@%%@8X.S%t%. 8t@8@8.;;88 88   .. .  .  ..  .        .   :   
. SX@ 8    . 8   . 8888@88888.S8:8;  t8@tS:..:;SX%88SS88X%@tSt888888: .:S@;t8%X@:@X 8 8   .   .  . . .  . .  . . . 8@ . 
. 8SX@    .   8 .@88;::  .   :;;X8888X: @888X%@X  8   ;.X   ;;S8%XS88S.. 8S. ;@88S8:8   . . .  .8    . . .  . .    88. .
. 8X 8          ;8. .....    .:;:.:%8S@S%@X8888;   8@888888S   S  X 8 .%XS. 88X@tSS.@  8.  . .8S     . .  .  .  .88 :.  
. 8X@    .    .88@ ....::::;:::.::t@;;;;;:...   .::t8S   8X8@@8 88XX.X;      :ttX ::X8 .. . .8 8  8 .  . .8.  .8 @ 88.  
. @XX  8  .  :@8%. .....::::SS;;:;;::::;:..... ...:::.;@tS%8X8:8 888 ;:@:t%%X 8:t@8X88X .. .8 8      . .   8. 8 8 8 8t. 
..8X 8 8   .. 8Xt:......:....:;;;;;tt;::.... .. ..:t8t8X%X%.:88;S@S8;X.Xttt%@8@;tt: 88.88:8X:t@.%8  . .. . . . 8 8 88.. 
. 8@@    .8 .8t@S:........  .::;8tS8:tttXS;St88X88t:.:;8888SXttt::tt;@X8888X%;%X@888S%8X88X8S;88@X888%%  .  .     8 :   
. SSX    8.  .8%S:.. ...   .:::;;@:@  S..S8XX88X;8S88S;t8888@Xt. XS888888S8 ;tX;;888@Xt;:.;t;;;t;tX@8@X8  .  .        . 
. 8SX8  8  . . 8X:..... ..;t;:.::..:t:88 @ t8t X8.%%  8  8:: t@.;@88@@88X;:...;X@ %8SX;:::;;;tttXXXXX%88   .  .     %   
. 8X 88  .  .  ;8t;X8;:..;t;:..... S. ;%8...::..    %X t8:888:@ %XX.@8S@.S:8; ;:%;88%.....:;t;t%;t@8@S@88   .  . .      
. SX@ 8   .  . tX8%88t:.:;;:...... 8.St@ ..:::::::. .; t%S@@88 S;t% 8X 8888@8X  8888;.....::::;;ttXX@8@ 8 8  .. .   S . 
. 8SX 8   . .. .8%@88@;:tt;........:8t8 .:...:.:.... %S;  : 88@;:.X   S :88XtS t X8X:tt:......::;%@888@ 8  . . .  .     
. 8XX8 8  .   .  8%8%tt;;t:........;@%@t..::::::... . tXt.SX  ; ..; % 88@8:% t ;SX:t8t..X ......;88@8: 8    . . .   : . 
. SS 8 8   . .  8 8XS8@88%;:.......t;@8..:;:;%88tXS;8;tX88 S  :;:.;8 8;XX@St.;t ;8%888;;S.8.....t@%@@8 8  .  .   .    . 
. 8X@   8.  .     :;888;8XX;tt:...:ttt8@8:SSX888S:: :;::X@S%@S8;@.: XS@.8tS8S:8t%8@t@ Xt ;X ; .tS@888 8    .  88        
. 8XX     .  . . .  88;;;%X:@@. ...;:;; :88X%S:::%@;XX:::@8t;XX%t.Xt8  SS@t% @.t;tt;;S% ;:@.8@.X8X88 8   .  . @     8t. 
. 8SX88    . . . t88Xtt;X8XSX.:....:::;tt8SSSSSSS@8X;;tt;XXX%8@8  t8888@8%:X @.:8;X::XS@%S.X@8X@88@t@  .  .   8     .   
. @X 8   . ... ;8@S%tt;tXXS::::;t:...::;;t8StS;tt%;;:tt;t88t%t%%;::;S8@S;8tt@X;% :8X8t:X.  8 88%X 8 8   . .    8    t . 
..8@@ 8   . .: 8@St%;8S..:.;S;:;8:....:;8t;;%;tt%%t;;;;::X8%:;%:8X;8@%@SXS@@8t:@ %;  @;X:XX.@ X@.:8 8   . . .    .  8;  
. 8X 8     . :8SX;%%@@;::..X8%%%tt;....::;;%t;;;%;:;;::. t@:.%SS;::  .t:. Stt X8 888888@8 :;@ 8 %tXS8  8 .   .  . .    .
. SX@ 8 . . :8tS8X;::::....t8%8;;%t:......::t@8@t%t;;;:..;8: %St%S:.::. 8 8@  X 8 8 tS8.. :tX;8888@S88. . ..  .  .  : . 
. 8SX 8  .  8@@8X.::......::S888:;;;;:.......;8@X;t@:;..:;@8tt%StS8S;8  SXt:  XX@S8 8@X @:::.::;SX%; :8     .  .. .     
. 8XX@   . %8tXX..........:;t8888.::::::.:..:;::::@ttt::.;8SXSX@@S@XX@8S8tX%8X XS @ %@8.@t::..:;;%S@8%:8   . .  .   :   
. SS 8   . @:@t:.........:@tS8@88X.....:;;:ttttXSX:;Xt;:.%@XXSSSXS%SS%: %%8SS XX8@SX@X;.8% :...t%%t%8t8X@8 8  . . .    .
. 8@@     8S Xt;:.... .. :XS@X8@88;:...;;::tXt%%888;;;:.:88:8S@@@SX88t@8X@%8..tXX @8@:8%@% ...:%X;t%S8888%.%8   .   :   
. 8SX     88:8;:..... ...;8S%@@t88X;:.....:::%@tSXXS;;:.t8@..X  .t%%S%t8@t%X;X8 SXS@X@X888t:..::;;8t;;t88t8X 8   .  8t .
. SSX8    88;%t::..  ....:%S@tX%.S8X@;;:....:::%tXS:S:::;;.tS;.. ;t%XSSt8@X;t@.  % 888;%%8S ....:.:t;;;t:SXS:8 .      . 
. 8S 88  8 8:.%.... .....;X:8t8::;SX@;;;:...:t8X%tt;:;X:::;@@XX%%SS@S@%8@:t;8S. @ X %X88:;.   ....:tSt%St;;S8 8 . . %   
. 8@@ 88 8 8t8t:.. ......;t888@@tS8XSS%;;:...:;@X8X:::::..:.tX8;.tSXS8XXt;;:@S 8% S 8t@8S;8:.......:;XSXtt;%88          
. S 8@ 8   8.:;:.........8t. ...X8@SSSX@@;;;;tttt@tXt;88X@8XS@%t%X8%S%tt;..:8; 8@ XX.88S;8X8.......:t%t@@%;:%.  8 . 8   
. .8 8 8  .@:::.........:8:. ..:;88XtXS@@8.%t;%S:SSt%S@;:8;.::t@S;;88@;:....8; @@S 8@S. 8S8@::.....S8@;%88;.;888    .  .
. @ 8 8 . 88@88t:.......:S;:..t@8888@S@X@S.;:;;;;::;t:S@88;;SXXSt;t8t:.... ;8S% @ %:8. X8888;8;.:88SX@X%88S.:@8     8t  
. X8 %888;8.88S@..........;@@t;t88tX8@S8@;t;;;tt%8X::@8%;.8;@S:;@XXt;:..  .:8S @.@tt%X 88X8S:@@::t@@SSS%@@t:.%8  8    . 
. S t8@@X 8 8%88... .tt::::.:8@:8  S;t%88888X;:XtS8@::8S%@@8tt88@X%t%;.    .t  tX%tS;@S %@X;:.;XS:t@.t@X@Xt:8X   8  t . 
. X8 88%8  X;8@@8;tX8S;:::.....88%S:;tt;;t%88@;t88XX88888888tX8SSStSX%:.   .8S8 @8 .X8 tS 8:@:t%%@%8t%%%%tt@8@    .     
. 8888t8@S :8 t%;@t88@:...::....:XXStt%%8X88@ttXS88@XS@X%%t88:8::;t;t%%X;:S8@@888.;S%%:t;8S;8t X   :;@X88@;8@88;t8  ; . 
. X 88;8.@:XtS  8S@88S%...::::..:..X8%Xt8S.   : 88@ :S@888X;888;::;tXt8X888X8@8X8;SX;;@@@..8X;ttS@S;%tS%X8@@8SS@SS8 .   
. @  88tX.;@8 SS.S8888X::..;t;::::;;t@XXt@ :8  . ..:8888@: @S@X@8@@@S   %@XSS%t8St:SSX:  .%8X.;:.:@:S%X:;.X8Xt;88Stt8.. 
.  8%;8S t;;.8t%888@8S :.;@8t;:..:;;:. X:@@% %8 88SX  88.:::;;SXXXXX88XS@%StX 8;8 S@8t::%8St8tS8:.. ;%:@%tt8S%Xtttt88:. 
. 8888t. ;::8;.@88888:.::S%t88;..:X:.. :8@8@:@X:t   Xt:8 S8ttt;;%X8S%8@X8t88 @: %::%X8888@:;:XX8 :..   @S%%;8t@@@..t8:. 
. 8t%:8@8.:@: %8888888.:t8%%@;8: ;@:.....:@8888XX88SX8SS@888X@@X@888 8S ;%; X:8;%88S@8@:.@@tStS@:8:.   ;88 %;SS%@:tX8;. 
. X8t:tt.t.SX .X88888;:8SX8S8@88X8@:........:X88X88@8888@@XX@88X;     : ;;    t8@@.8t@t%: :S@@@;t% X...;@@8t8%@8t88XX . 
.  ;;:::t 8XX8 S8888S:;%S8S@;88@SS8X  .  .......:%88X88@.S8tX@888. % ;SS%;  ;8t;t;;t%XtS@ 8;;@X@tX.X:..;;8@:88@8.XX%8.. 
. @.::.X X8X%  S@X;;;t888:@ 8@X%@8t8.  .;X;;:. .::..;;X8;t888S.      XS@8@@8;%%X: @88t%%8t8%88@XSX@t8;;;t;S;:8SXX8X@S . 
.  :;S@:  8S88;t;:;t%%8XX@X.X@;:  t:@..8S88:;::....::...SSX88Xt@88S.8St.8%;:8@@X % t:@@t;8X;%;8@%:X:8SX8@8888X@8%S8@% . 
. 8@8@888888S88@X88@88% 8 @8@X88tt888@88t888888X8888X8888@SX88@8888XSX8t888S.8X 8.t8.88 8888@@S88@8XS@88::S:@ 8@@@X8@ . 
   :;.t%SX;  :t:;:;:; S8%X:  S@S...:   .;%SSt;t   .:    ::; .:   .t:t; :;: . :   t: .     ;;; :%; :.:%%;X8S@XXt::::; .  
   .   .         .      ..      . .       . .                         .   .               .             . .. .  .      .
*/

contract VinceFraserxSeed is Ownable, ERC721AWithRoyalties, Pausable, CantBeEvil(LicenseVersion.CBE_PR_HS) {
  string public _baseTokenURI;

  uint256 public _price;
  uint256 public _maxSupply;
  uint256 public _maxPerAddress;
  uint256 public _publicSaleTime;
  uint256 public _maxTxPerAddress;
  mapping(address => uint256) private _purchases;

  event Purchase(address indexed addr, uint256 indexed atPrice, uint256 indexed count);

  constructor(
    // name, symbol, baseURI, price, maxSupply, maxPerAddress, publicSaleTime, maxTxPerAddress, royaltyRecipient, royaltyAmount
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 price,
    uint256 maxSupply,
    uint256 maxPerAddress,
    uint256 publicSaleTime,
    uint256 maxTxPerAddress,
   // price - 0, maxSupply - 1, maxPerAddress - 2, publicSaleTime - 3, _maxTxPerAddress - 4
    address royaltyRecipient,
    uint256 royaltyAmount
  ) ERC721AWithRoyalties(name, symbol, maxSupply, royaltyRecipient, royaltyAmount) {
    _baseTokenURI = baseTokenURI;
    _price = price;
    _maxSupply = maxSupply;
    _maxPerAddress = maxPerAddress;
    _publicSaleTime = publicSaleTime;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setSaleInformation(
    uint256 publicSaleTime,
    uint256 maxPerAddress,
    uint256 price,
    uint256 maxTxPerAddress
  ) external onlyOwner {
    _publicSaleTime = publicSaleTime;
    _maxPerAddress = maxPerAddress;
    _price = price;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);
    _safeMint(to, count);
  }

  function purchase(uint256 count) external payable whenNotPaused {
    require(msg.value == count * _price);
    ensurePublicMintConditions(msg.sender, count, _maxPerAddress);
    require(isPublicSaleActive(), "BASE_COLLECTION/CANNOT_MINT");

    _purchases[msg.sender] += count;
    _safeMint(msg.sender, count);
    uint256 totalPrice = count * _price;
    emit Purchase(msg.sender, totalPrice, count);
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }

  function ensurePublicMintConditions(address to, uint256 count, uint256 maxPerAddress) internal view {
    ensureMintConditions(count);
    require((_maxTxPerAddress == 0) || (count <= _maxTxPerAddress), "BASE_COLLECTION/EXCEEDS_MAX_PER_TRANSACTION");
    uint256 totalMintFromAddress = _purchases[to] + count;
    require ((maxPerAddress == 0) || (totalMintFromAddress <= maxPerAddress), "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");

  }

  function isPublicSaleActive() public view returns (bool) {
    return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
  }

  function isPreSaleActive() public pure returns (bool) {
    return false;
  }

  function MAX_TOTAL_MINT() public view returns (uint256) {
    return _maxSupply;
  }

  function PRICE() public view returns (uint256) {
    return _price;
  }

  function MAX_TOTAL_MINT_PER_ADDRESS() public view returns (uint256) {
    return _maxPerAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721AWithRoyalties) returns (bool) {
    return
        super.supportsInterface(interfaceId);
  }
}