// SPDX-License-Identifier: MIT
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BG5YJ?7!!!!!!7?YPG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GJ7~:::................:^!?YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P?!^:::::::::::::::::::::::::...:^!JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@P7^::::::^:::::::::::::::::^::::::::::.:~JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@P!:::::^:^^^::::::::^:^:::^:^^^::::::::::::::?#@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@#7::::::^^^^^^:::::::^^^^^^^^:^^^:^^^^:^^::^^^^:^5@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@B~^^^^^^^^^^^^^^^^:^^^~^^^~~^^:^^^^^^^^^^^^^^^^~^::Y@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#~^~^^^^^^^^^^^^^^^^^^^~^!777!~^^^~^^^^^^^^^^^^^~~^^:Y@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@?^~~^^^^^^^^~~^~^^^^^^^~^~!!!~~~^^^^^^^^^^^^^^^^!~^^:~#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@B^~^~^^^^^^^~~^^~^^^^^^^~~~~~^~~^^^^^^^^^^^^~^^^^!!~^^:J@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@P^^^~~7?!~^^~~^^~~^^~~~~!~~^~~~~~^^~^^^^~~^^^^^~~!!~^^^!B@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&?~~~~~~~~~~~7!~!!!!!!!!7!!!~!!!~!!!!!~~~~!!!~~~~!7!~7~^~5&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@G7!~^~~~!!!!!!~!!~~~~~~~~~!~!~!~~~~~~~~~~~!!77!7777~!?^^!5G@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#?~~!?777!!~~~~~~~~~~^^^^^~~~~~^^^^^^^~^~~~~~~~~~!!!77^^7PG@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#?~~!JJ?7!~~^^^~^~~^^^^^^~!!~!~~~~^^^^^^^^^^~~~~~~7?Y7^^YPP&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&&GJ777YJ??77?77??777777777YG?~77^7Y77??77!777777!!7??YY77P55&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@B5YPGPYY5PBB##BBGG#BBGGGBBBBBGYYJYPGGGBB###BBBBGGP5Y5P5JPPP5P@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#YYBG5JG###&&&##&#B##&&&@##BGPPG5JJP&&&&&&&&&&#&&#&#BGPPG5YP#@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&B##GG55YG#&&&&&####BB####&#BPJ?5YJJJ5######B#######&&#BGGG5GGB@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@GPB#G5YJ5PB&&&###BBBBBBB##BBP777?JYJ?JPBBBBBBGBBB###B#B#GGBYGGP@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@#P555555YPGGB&BB#GPYPGGBBBPGPJ?7777?777JPGBBPP5JJPB#BB##GPGGYYGYB@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@J~!Y5G7?PPBB#BBBGGGGBBGP57?J?7!~~^~~!!?5PGGPPPPGBBBBBGY5555J7YG@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@B??YP5^!PPGGGBBGGGGGG5Y?~~!!~~!?J?~~^~^~!?YPPGGGGGGGP5YYJYPY5G@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#&#?PG77JYY5Y55PP55J7!~~~!~^7YGB#&G?!!!~^~~!??YYP555Y55J~?5GG&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#!Y##GJ?YYYYYYJ?!7??777!!J#&#BGB&BJ!!7?777???YJYJJ??JJ?5G?P@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&JJ#BBP55777777?YG#&&B57?B##BY5B##B?~Y##GBPY?J7??!J?Y5G#P~Y&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&77GPGPBBPGBBBB##5YPP5Y!7Y55J7J55PY?~!YYGG?JGGGBG5PPPGBB?~5&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@G5PBBB#BGG##B#BGP55Y!~~~~~J7!!!7!~~~!!?JY5PB&B&&###BGBPJJP@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#BGBBBGBB###5GGYYJ7~~~~!!7!!!77!!!!!7YJJ5GB#&###BBBGGGPG@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@G?BGB###&#GYPGYYJ??!~~~!!!~!~~!~~!!!JYJYPG###BBGPJB@##&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@B!YPP#B#BBPPPBYYJ???777????7?7!!77777J5YYB##B#GP?^#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&??G55P&##BBBBGYYY5PGGGBGBPGGGGGP555YYPPGB#BBGPG7!&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@5!PPYYPGGGB#&#GBGPPP5YJJJJJ?JJJ5GGGBBB#BGP5YG&B!!&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@G!JBYYYY5YJPPY5J!~~^^~~!~!!~!~^^~7!?5PG5YYYP#B5!?@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@#77PGPGGBGYYY~~~~~~~77!!!!~~~!~!!~~~7YYYPPP#BPJ~B@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@P7YBGPPBG55PJ?????!!~!!~!~~~!????777?5GPPG#GG?J@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&5JGBGPGG55PP555Y???J?7?JJ??JYJJYP5PPPGPPBBGG5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@###BGPBBPGGP5555JJ?!!7?JYY55YJJJYYJY5PGGG5GBGP5#@&&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@B##B#B##BGPP55Y5YJ?777?Y55555JJJJ??J5GGGPPBBGG####B#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#BB##B#####BBP5YYYYJ777?P5PG5P555YY55PPGGGB###&&##BBB#&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&BBB########&&#BBBGGP55YPGGGGGBPPPPPGGGBB##&&######BBBB#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#B#BB########&&&&#&######BBBB#######&&##&&&#######BBBBBBB#@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&BB##B##&######&&###&&&&#####&####&&##&&&&###&&####BBBBBBBGB&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&BB####B########&&&&&&&#################&&###&&&###B###BBBBBBBB&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#BBB#####B##&#####&&&&&###B#########&#######&&&&####B###BBBBBBBBBB#&@@@@@@@@@@@@@@
@@@@@@@@@@@@@&&#BBBBBB###############&&&&&&&&&&&&&&##&##&####&&&&#########BBBBBBBBBBBB#&&@@@@@@@@@@@
*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract EdgeRunners is ERC721A, Ownable, ReentrancyGuard {

 
  using Strings for uint;
 string public hiddenMetadataUri;


  string  public  baseTokenURI = "ipfs://QmXGtwbtDCRTvUdc2TG5GR6hD7r9TULttSpmD9qrRhMoMf/";
  uint256  public  maxSupply = 1111;
  uint256 public  MAX_MINTS_PER_TX = 5;
  uint256 public  PUBLIC_SALE_PRICE = 0.006 ether;
  uint256 public  NUM_FREE_MINTS = 250;
  uint256 public  MAX_FREE_PER_WALLET = 1;
  uint256 public freeNFTAlreadyMinted = 0;
  bool public isPublicSaleActive = false;

   constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


  function mint(uint256 numberOfTokens)
      external
      payable
  {
    require(isPublicSaleActive, "Public sale is not open");
    require(totalSupply() + numberOfTokens < maxSupply + 1, "No more");

    if(freeNFTAlreadyMinted + numberOfTokens > NUM_FREE_MINTS){
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
    } else {
        if (balanceOf(msg.sender) + numberOfTokens > MAX_FREE_PER_WALLET) {
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
        require(
            numberOfTokens <= MAX_MINTS_PER_TX,
            "Max mints per transaction exceeded"
        );
        } else {
            require(
                numberOfTokens <= MAX_FREE_PER_WALLET,
                "Max mints per transaction exceeded"
            );
            freeNFTAlreadyMinted += numberOfTokens;
        }
    }
    _safeMint(msg.sender, numberOfTokens);
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }

  function treasuryMint(uint quantity)
    public
    onlyOwner
  {
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, quantity);
  }

function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }

  function tokenURI(uint _tokenId)
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
    return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return baseTokenURI;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
  {
      isPublicSaleActive = _isPublicSaleActive;
  }
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setNumFreeMints(uint256 _numfreemints)
      external
      onlyOwner
  {
      NUM_FREE_MINTS = _numfreemints;
  }

  function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }

  function setMaxLimitPerTransaction(uint256 _limit)
      external
      onlyOwner
  {
      MAX_MINTS_PER_TX = _limit;
  }

  function setFreeLimitPerWallet(uint256 _limit)
      external
      onlyOwner
  {
      MAX_FREE_PER_WALLET = _limit;
  }

  function setMaxSupply(uint256 _limit)
      external
      onlyOwner
  {
      maxSupply = _limit;
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "Reserves already taken");

    _mint(msg.sender, 50);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

}


