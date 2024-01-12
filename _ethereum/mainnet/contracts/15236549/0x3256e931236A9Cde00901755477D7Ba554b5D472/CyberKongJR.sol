// SPDX-License-Identifier: MIT
                                                                                                 
pragma solidity >=0.7.0 <0.9.0;

/**
    The Dontract is a simple but highly gas efficient NFT contract that can accept any ERC20 token as
    payment. I made it for small independent artist like myself. Feel free to use it in your project.
    I will be posting plug and play how-to's in my discord so that you can hook it up to your own
    website. Check out donsnft.com and join my discord from there. Happy minting! 
*/

/**************************************************************************************************\
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGGPPPPGGGGGGGGGB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5Y7!~^^^^^^^^^^^^^^^^^^~!77?5G#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7JPB@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^7YB@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BY!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!J5GBBBBBG5YJ!^::^75#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?G&@@@@@@@@@@@@@BY!^^^~JG@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@BY~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~G@@@@@@@@@@@@@@@@@@&J^^^^^?B@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@P?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!G#BGGGGGGGBGGBB#&&@@@Y^^^^^~5@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@B7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^^^^^^^^^^^^^~~!7?Y5~^^^^^^7G@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&5~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::^^^^^^^:^5@@@@@@@@
@@@@@@@@@@@@@@@@@@@Y^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7???JYY55PGGGGBBB#######BBBGGP5YYJ??77!!^^P@@@@@@@
@@@@@@@@@@@@@@@@@@G^^^^^^^^^^^^^^^^^^^^^^^~?J5B#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G!~G@@@@@@
@@@@@@@@@@@@@@@@@&?^^^^^^^^^^^^^^^^^^^^7YB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G^7&@@@@@
@@@@@@@@@@@@@@@@@B^^^^^^^^^^^^^^^^^^~JG@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&?^P@@@@@
@@@@@@@@@@@@@@@@@P^^^^^^^^^^^^^^^^^^7B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G^7#@@@@
@@@@@@@@@@@@@@@@@5^^^^^^^^^^^^^^^^^^^^?G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7^5@@@@
@@@@@@@@@@@@@@@@@G^^^^^^^^^^^^^^^^^^^^^^~JGBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGJ^!P&@@
@@@@@@@@@@@@@@@@@#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^P@@
@@@@@@@@@@@@@@@@@P^^^^^^^^^^^^^^^^^^^^^^^^^?55!^^!5PJ^^^^^^^^^^^^^^^^^^^^!5P?^^^^^^^^^^^^^^^^^^^^P@@
@@@@@@@@@@@@@@@@@G^^^^^^^^^^^^^^^^^^^^^^^~^Y#B?!!J##P!!!^^^^^^^^^^^^~YPP?!B#5!!!^^^^^^^^^^^^^^^^~P@@
@@@@@@@@@@@@@@@@&Y^^^^^^^^^^^^^^^^^^^^^^?#?^^~5@@J^^7#@P^^^^^^^^^^^:!#@@P^^^7&@G^^^^^^^^^^^^^^^?#@@@
@@@@@@@@@@@@@@@#7^^^^^^^^^^^^^^^^^^^^^^!G@GYY~!???PGY??JGG5~^^^^^^?Y5&@@BYY7~??JPG5^^^^^^^^^^!YG@@@@
@@@@@@@@@@@@@@#!^^^^^^^^^^^^^^^^^^^^^^^7&@@@@J~~^7B#Y^^!BBP~^^^~~7B@@@@@@@@P~~^!GBG^^^^^^^^^^!P@@@@@
@@@@@@@@@@@@@#7^^^^^^^^^^^^^^^^^^^^^^^~5@@@@@@&&7:^^^^^^^^^^^:~G&&@@@@@@@@@@&&P^^^^^^^^^^^^!7^^5@@@@
@@@@@@@@@@@@#7^^^^^^^^^^^^~~!~^^^^^^^^~P@@@@@@@@GY555555555555P&@@@@@@@@@@@@@@#555555555555BB!^~B@@@
@@@@@@@@@@@B!^^^^^^^^^^^7P#&&#PJ!^^^^^^Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&Y^^Y@@@
@@@@@@@@@@P~^^^^^^^^^^~5@@G?7JP#&G?^^^^J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~^7#@@
@@@@@@@@#Y^^^^^^^^^^^^Y@#?^75Y!~?B@G7^^^7B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~^?&@@
@@@@@@&Y~^^^^^^^^^^^^^G@G7?&@@@P7^?#@Y^^^~G@@@@@@@@@@@@@@@@@@@@@@@@&#GP#&@@@@@@@@@@&##@@@@@@@5^^Y@@@
@@@@@G!^^^^^^^^^^^^^^^Y@@@@@@@@@&5!!G&?^^^7#@@@@@@@@@@@@@@@@@@@&P?7!^^^^!7?5GBBBGY?~^~?&@@@@&?^~P@@@
@@@#J^^^^^^^^^^^^^^^^^~5@@@@@@@@@&5^^GP^^^^Y@@@@@@@@@@@@@@@@&GJ~^^^^^^^^^^^^^^^^^::^^:^P@@@&J^^Y&@@@
@&5~:^^~!777!~~^^^^^^^^^Y&@@@@@@G~~?5&B!^^^?&@@@@@@@@@@@@@@P~::^^^^^^^^^^^^^^^^^^~!77J5#@@#?^!G@@@@@
@Y^~JPB&&@@@&##GY?777!!~^!P&@@@@G~^Y@@#7^^^P@@@@@@@@@@@@@@B?7?!7?JJY5PGBBBGPP55G#&&@@@@@@G!^J&@@@@@@
@#B&@@@@@@@@@@@@@@@@@&&#Y~^!5B&@@#5P@@&7^^^G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~^J&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#P7~^~!?JYYJ??~^^^5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&Y^^5@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B5Y?7!7?5BB7^^~P@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@#?^~5@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5!^^JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!^7B@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^^!YB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~:7#@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5?~^!JP#&@@@@@@@@@@@@@@@@@@@@@@@@@@&J^^?#@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BJ!^~!?YG#&@@@@@@@@@@@@@@@@@@@@B7^^Y@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PJ7~^^!7J5G#&@@@@@@@@@@@&BJ^^7B@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGY?!~^~~!7?YPGGPPY?!^^?G@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGPY?7!~~~~~~7YP#@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#####&@@@@@@@@@@@@@@@@@@@@@@@@
\**************************************************************************************************/


import "./ERC721.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract CyberKongJR is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;


    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 20;

  bool public paused = true;

  constructor() ERC721("CyberKongJR", "CKJR") {}

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

    function mintpid(uint256 _mintAmount, uint256 _pid) public payable mintCompliance(_mintAmount) {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 costval;
        costval = tokens.costvalue;
        require(!paused, "The contract is paused!");
        require(paytoken.transferFrom(msg.sender, address(this), _mintAmount * costval));

        _mintLoop(msg.sender, _mintAmount);
    }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner() {
    require(payable(msg.sender).send(address(this).balance));
  }

  function getNFTCost(uint256 _pid) public view virtual returns(uint256) {
    TokenInfo storage tokens = AllowedCrypto[_pid];
    uint256 costval;
    costval = tokens.costvalue;
    return costval;
  }

  function getCryptotoken(uint256 _pid) public view virtual returns(IERC20) {
    TokenInfo storage tokens = AllowedCrypto[_pid];
    IERC20 paytoken;
    paytoken = tokens.paytoken;
    return paytoken;
  }
        
  function withdrawpid(uint256 _pid) public payable onlyOwner() {
    TokenInfo storage tokens = AllowedCrypto[_pid];
    IERC20 paytoken;
    paytoken = tokens.paytoken;
    paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}