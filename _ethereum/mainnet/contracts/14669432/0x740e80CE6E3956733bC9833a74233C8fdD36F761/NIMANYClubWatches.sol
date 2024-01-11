// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@*,,,,,,,,,,,,,,,,,,,,,,..,,,,.@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@,,,,*,,,,,,,,,,,,,,,,,,,..,,,,.@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,..@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,*,,,,,,,.,,.,,.@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,....@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,......@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,.,,,...........@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@/     ,,,,,,,,,,,,,,,,,,,,,,,,.........,,     *@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@(..... ,,,,,,,,,,,,,,,,,,,,,,,,,,...,,,,,/......&@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@#//////.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*/,,,,,,,@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@%*//**/(//**,,,,,,,.....................,**//#######@@@@@@@@@@@@@@@@@
//@@@@@@@@@@#(##((##,,,,,,,,,,,,,,,,,,,**,,*,,,,,........./#######@@@@@@@@@@@@@@@@
//@@@@@@@@@%#####,,,*,,,,.,,,####*##(%%#%%%%&%%%%%,**,........#####@@@@@@@@@@@@@@@
//@@@@@@@@/###,,****,,,*%(#%#%%##%#########%%%%&&&&&&&%,*,.......###.@@@@@@@@@@@@@
//@@@@@@@(#/,****,,,#(##%//####################%%%%&&&&@&%&/*......(#*@@@@@@@@@@@@
//@@@@@@#(*****.,((#/#####*%*#####%*######%%######&%#&&&&&@&&#*......((@@@@@@@@@@@
//@@@@@#*****.,(/#%########%#.######&/*&*%*######*#/#%%%&&&&&@%&*......(@@@@@@@@@@
//@@@@(****,,//(%*###########./(#((((((((((((###*%####%%%%&&&&&&((*.....(@@@@@@@@@
//@@@*****.,(*/*,############(#,(#%*,(%,%,%,(,*#,#######%%%%%&%%&(&*.....*@@@@@@@@
//@@/****.*//#,###,##,#####(((#,%,%*,,,,,,,/*,#,((######%,%&#&&&%&&&/......@@@@@@@
//@@****,*//((########**###*#((((###((,#(//((((((((###%&/*((#&&&&&@&&*.....@@@@@@@
//@/****,,.(###########((((#%*#*#########(((((###&(((#/(%%%%%%%%%&&&&#,. ...@@@@@@
//@//**,*//############((((((((#((//#######%&/*##/(########%%&%%%%&&&&*.  ..#%#@@@
//@//**.,/.##%(##%&*##((((((((((###(/((#(////(############%/&%%&%&&&&%*.  ..###,.*
//@//**.,,,##%&/#%(##((((((((((##%&*/((#/**/(((((((((#####%&#&%(&&%&&(*.  ..%%% *,
//@//**,,/*##########((((((((((((###%#####(#(((((((((######%%%&%%%%&&&*.  ..###*@@
//@///*,,*,/#####(((((((((((((((((#######((((((((((((######%%%%%%%&&%#,.  ..@@@@@@
//@@////,,(/#/########(/(((((((((########(((((((((((###%.#%%%%%%%%&&&*.  ..@@@@@@@
//@@/////.,,/#,###,##*##((((((#####%%%#####((((((((#####%.%&(%%%(&&&*......@@@@@@@
//@@@///((.,//(*,######((((((#####%%%######((((((#######%%%%%&((&&&*......@@@@@@@@
//@@@@///(/,,*/.%*#######((##//#####%######(((##*#####%%%%%%%%&##(*.....,@@@@@@@@@
//@@@@@#//((/.,/*(%########%#/#(#################*#*#%%%%%%&&&&&*......(@@@@@@@@@@
//@@@@@@#///((/.,/((######,%*#######&(##&*########&%(%%%%&&&/&*,.....,(@@@@@@@@@@@
//@@@@@@@##//////,,,(*/##**#########&/##&/#####%%%%%%(&&#&#*,.......#(@@@@@@@@@@@@
//@@@@@@@@###(//////,,,*(#*#########%###%%#%%#%%&&&%&&//**.......(##(@@@@@@@@@@@@@
//@@@@@@@@@#####///////*,,,,*(.(#/*#(%%%%%#%/#(#%%/**,........,####/@@@@@@@@@@@@@@
//@@@@@@@@@@########/////****,,,,,,********,**,.,..........#######/@@@@@@@@@@@@@@@
//@@@@@@@@@@@(#######@///*******,,,,,,,,,,,,,.........,/(@(((((((/@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@(((((((#,,,,,,,,,,***,,,,,,,,,,,.,,,,,,,,/(#///////@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*((//////@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@((((((,,,,,,,,,,,,,,,,,,,,,,,,,,.,.,.,,,,//((//@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@/#(*,,,,,,,,,,,,,,,,,,,,,,,,,.......,./*/@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@*,,,,,,,,,,,,.,,,,,,,,,,.,.........@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@*,***,,,,,,,*,,,..,,,,,,,,,,.....,.@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@,*//,,,,**,,,,,,,.,*,...,,,.,,.,,.@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*,*/*,.,,,,,,,,,,*,,,,,,,,..,,,,.@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@&,,*//*,,,,,,,,,,,,,,,,,,,,.***,.@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@*,,*//**,,,,,,,,,,,,,,,,..***,.@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@*,,,//*******,,,.,,,*,.,***,.@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol"; 

contract NIMANYClubWatches is ERC721, Ownable {
  constructor() ERC721("NIMANYClubWatches", "NNY") {}

  string private uri = "https://assets.bossdrops.io/immortals/";

  string private claimedUri;

  // the initial sale will be 1810 tokens, an unknown amount more will be created via the burning mechanism.
  uint public constant MAX_TOKENS_FOR_SALE = 1810;

  // mapping to keep track of id's that have claimed a gold watch nft
  mapping(uint256 => bool) public claimedGold;

  // Only 10 nfts can be purchased per transaction.
  uint public constant maxNumPurchase = 3;

  // is the metadata frozen?
  bool public frozen = false;

  // address of the wallet that will sign transactions for the burning mechanism
  address public constant signerAddress = 0x7d1c1c1Fb80897fa9e08703faedBF8A6A25582f8;

  // X amount of NFTs will be distributed to NIMANY during the mint
  address public constant NIMANYAddress = 0xd41cB7D50B9288137cBFd9CD52613cdC8692c371;

  /**
  * The state of the sale:
  * 0 = closed
  * 1 = presale
  * 2 = public sale
  */
  uint public saleState = 0;

  // Early mint price is 0.1 ETH.
  uint256 public priceWei = 0.1 ether;

  uint256 public pricePublicWei = 0.125 ether;

  uint public numMinted = 0;

  using Strings for uint256;

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_ownerOf[tokenId] != address(0), "NOT_MINTED");

    if (claimedGold[tokenId]) {
      return string(abi.encodePacked(claimedUri, tokenId.toString()));
    } else {
      return string(abi.encodePacked(uri, tokenId.toString()));
    }
  }

  using ECDSA for bytes32;

  function checkPayment(uint256 numToMint) internal {
    uint256 amountRequired = priceWei * numToMint;
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function checkPaymentPublic(uint256 numToMint) internal {
    uint256 amountRequired = pricePublicWei * numToMint;
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function claimGold(uint tokenId, bytes memory signature) public {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        tokenId,
        "claiming physical"
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    claimedGold[tokenId] = true;
  }

  function mint(uint num, bytes memory signature) public payable {
    require(saleState > 0, "Sale is not open");

    uint newTotal = num + numMinted;
    require(newTotal <= MAX_TOKENS_FOR_SALE, "Minting would exceed max supply.");

    if (saleState == 1) {

      checkPayment(num);

      bytes32 inputHash = keccak256(
        abi.encodePacked(
          msg.sender,
          num
        )
      );


      bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
      address recoveredAddress = ethSignedMessageHash.recover(signature);
      require(recoveredAddress == signerAddress, 'Bad signature for eaarly access');
    } else if (saleState == 2 && num > maxNumPurchase) {
      revert("Trying to purchase too many NFTs in one transaction");
    } else {
      checkPaymentPublic(num);
    }

    _mintTo(msg.sender, num);
  }

  function _mintTo(address to, uint num) internal {
    uint newTotal = num + numMinted;
    while(numMinted < newTotal) {
      _mint(to, numMinted);
      numMinted++;
    }
  }

  function burnAndExchange(uint256 tokenId1, uint256 tokenId2, uint256 tokenId3, uint256 tokenId4, bytes memory signature, uint exchType)
    public
  {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        tokenId1,
        tokenId2,
        tokenId3,
        tokenId4,
        exchType
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    if (exchType == 0) {
      _burn(tokenId1);
      _burn(tokenId2);
      _mintTo(msg.sender, 1);
    } else if (exchType == 1) {
      _burn(tokenId1);
      _burn(tokenId2);
      _burn(tokenId3);
      _burn(tokenId4);
      _mintTo(msg.sender, 1);
    } else if (exchType == 2) {
      _burn(tokenId1);
      _burn(tokenId2);
      _burn(tokenId3);
      _mintTo(msg.sender, 1);
    } else {
      _burn(tokenId1);
      _burn(tokenId2);
      _mintTo(msg.sender, 1);
    }
  }
  
  function totalMinted() public view virtual returns (uint) {
    return numMinted;
  }

  /** OWNER FUNCTIONS */
  function ownerMint(uint num) public onlyOwner {
    _mintTo(msg.sender, num);
  }

  function airdrop(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
       _mintTo(addresses[i], 1);
    }
  }

  function nimanyMint(uint num) public onlyOwner {
    _mintTo(NIMANYAddress, num);
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setSaleState(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 2, "Invalid state");
    saleState = newState;
  }

  function setBaseURI(string memory baseURI, uint uriType) public onlyOwner {
    if (frozen) {
      revert("Metadata is frozen");
    }
    if (uriType == 0) {
      uri = baseURI;
    } else {
      claimedUri = baseURI;
    }
  }

  function freezeMetadata() public onlyOwner {
    frozen = true;
  }

  function setMintPrice(uint newPriceWei) public onlyOwner {
    priceWei = newPriceWei;
  }
}
