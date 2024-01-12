//SPDX-License-Identifier: Unlicense

//  .S_sSSs      sSSs  sdSS_SSSSSSbs
// .SS~YS%%b    d%%SP  YSSS~S%SSSSSP
// S%S   `S%b  d%S'         S%S
// S%S    S%S  S%S          S%S
// S%S    S&S  S&S          S&S
// S&S    S&S  S&S_Ss       S&S
// S&S    S&S  S&S~SP       S&S
// S&S    S&S  S&S          S&S
// S*S    S*S  S*b          S*S
// S*S    S*S  S*S          S*S
// S*S    S*S  S*S          S*S
// S*S    SSS  S*S          S*S
// SP          SP           SP
// Y           Y            Y

//  .S_sSSs     .S       S.    sdSSSSSSSbs   sdSSSSSSSbs  S.        sSSs
// .SS~YS%%b   .SS       SS.   YSSSSSSSS%S   YSSSSSSSS%S  SS.      d%%SP
// S%S   `S%b  S%S       S%S          S%S           S%S   S%S     d%S'
// S%S    S%S  S%S       S%S         S&S           S&S    S%S     S%S
// S%S    d*S  S&S       S&S        S&S           S&S     S&S     S&S
// S&S   .S*S  S&S       S&S        S&S           S&S     S&S     S&S_Ss
// S&S_sdSSS   S&S       S&S       S&S           S&S      S&S     S&S~SP
// S&S~YSSY    S&S       S&S      S*S           S*S       S&S     S&S
// S*S         S*b       d*S     S*S           S*S        S*b     S*b
// S*S         S*S.     .S*S   .s*S          .s*S         S*S.    S*S.
// S*S          SSSbs_sdSSS    sY*SSSSSSSP   sY*SSSSSSSP   SSSbs   SSSbs
// S*S           YSSP~YSSY    sY*SSSSSSSSP  sY*SSSSSSSSP    YSSP    YSSP
// SP
// Y

// author: Kuma father
//

pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract NftPuzzle is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeibus77bjgeocp3eqq64z643uhaejsnc4xwjjsxfxk5fqcwz3dvuxq.ipfs.nftstorage.link/metadata";
    uint256 public MAX_PUZZLES = 5555;
    uint256 public MAX_PUZZLES_PER_TX = 10;
    uint256 public MAX_PUZZLES_PER_WALLET = 10;
    uint256 public KUMA_HOLDERS_PRICE = 0.003 ether;
    uint256 public PUBLIC_PRICE = 0.005 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    bool public kumaHoldersInitialize = true;
    bool public publicInitialize = false;
    bool public revealed = true;
    address public KUMA_CONTRACT_ADDRESS = 0x1569f5D2114dafbD35D7C756f58510703B04d35d;

    mapping(address => uint256) public qtyFreeMinted;
    mapping(uint256 => uint256) kumasXPuzzles;

    ERC721A public kumaContract;

    constructor() ERC721A("NFT Puzzle", "NFTPuzzle") {
        for (uint256 i = 0; i < MAX_PUZZLES_PER_WALLET; i++) {
            if (i <= 2) {
                kumasXPuzzles[i] = 1;
            } else if (i > 2 && i <= 4) {
                kumasXPuzzles[i] = 2;
            } else if (i > 4 && i <= 6) {
                kumasXPuzzles[i] = 3;
            } else if (i > 6 && i <= 8) {
                kumasXPuzzles[i] = 4;
            } else if (i > 8 && i <= 10) {
                kumasXPuzzles[i] = 5;
            }
        }
    }

    function makePuzzleByKuma(uint256 puzzles) external payable
    {
        kumaContract = ERC721A(KUMA_CONTRACT_ADDRESS);

        require(kumaHoldersInitialize, "Error not ready");
        require(puzzles > 0, "Need to be more than 0");
        require(puzzles <= MAX_PUZZLES_PER_TX, "Max puzzles per transaction exceeded");

        require(totalSupply() + puzzles <= MAX_PUZZLES, "The mint end");

        uint256 tokensOfSender = balanceOf(msg.sender);

        require(tokensOfSender + puzzles <= MAX_PUZZLES_PER_WALLET, "More than limit");

        uint256 numberOfKumas = kumaContract.balanceOf(msg.sender);

        require(numberOfKumas > 0, "No has a kuma");

        uint256 availableFreeKumas = kumasXPuzzles[numberOfKumas];

        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= availableFreeKumas;

        bool canMintAFree = !alreadyMintedAFree;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free");
        }

        uint256 qtyFreeMint = 0;

        if (canMintAFree) {
            uint256 total = KUMA_HOLDERS_PRICE * puzzles;
            uint256 totalWithMsgValue = msg.value;

            uint256 difference = total >= totalWithMsgValue ? total - totalWithMsgValue : totalWithMsgValue - total;

            if (difference > 0) {
                qtyFreeMint = difference / KUMA_HOLDERS_PRICE;
            }

            require(qtyFreeMint + qtyFreeMinted[msg.sender] <= availableFreeKumas, "Free overflow");
        }

        require(msg.value >= (KUMA_HOLDERS_PRICE * (puzzles - qtyFreeMint)), "Error");

        if (canMintAFree) {
            qtyFreeMinted[msg.sender] += qtyFreeMint;
        }

        _safeMint(msg.sender, puzzles);
    }

    function makePuzzle(uint256 puzzles) external payable
    {
        require(publicInitialize, "Error not ready");
        require(puzzles > 0, "Need to be more than 0");
        require(puzzles <= MAX_PUZZLES_PER_TX, "Max puzzles per transaction exceeded");

        require(totalSupply() + puzzles <= MAX_PUZZLES, "The mint end");

        uint256 tokensOfSender = balanceOf(msg.sender);

        require(tokensOfSender + puzzles <= MAX_PUZZLES_PER_WALLET, "More than limit");

        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= MAX_FREE_PER_WALLET;

        bool canMintAFree = !alreadyMintedAFree;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free");
        }

        bool isTryingToMintAOneFreeMint = canMintAFree
            && puzzles == 1
            && msg.value == 0;

        if (canMintAFree && !isTryingToMintAOneFreeMint) {
            require(msg.value >= (PUBLIC_PRICE * (puzzles - MAX_FREE_PER_WALLET)), "Error");
        }

        bool itsAPaidMint = !isTryingToMintAOneFreeMint && alreadyMintedAFree;
        if (itsAPaidMint) {
            require(msg.value >= (PUBLIC_PRICE * puzzles) , "Incorrect ETH value sent");
        }

        if (canMintAFree) {
            qtyFreeMinted[msg.sender] += 1;
        }

        _safeMint(msg.sender, puzzles);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return string(abi.encodePacked(baseTokenURI, "/hidden.json"));
        }

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }

    function setKumaHoldersInitialize(bool _kumaHoldersInitialize) external onlyOwner
    {
        kumaHoldersInitialize = _kumaHoldersInitialize;
    }

    function setPublicInitialize(bool _publicInitialize) external onlyOwner
    {
        publicInitialize = _publicInitialize;
    }

    function setPublicPrice(uint256 _price) external onlyOwner
    {
        PUBLIC_PRICE = _price;
    }

    function setKumaHoldersPrice(uint256 _price) external onlyOwner
    {
        KUMA_HOLDERS_PRICE = _price;
    }

    function setMaxKumasPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_PUZZLES_PER_WALLET = _limit;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PUZZLES_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }

    function setKumasXPuzzles(uint256 qtyKuma, uint256 qtyPuzzle) external onlyOwner {
        kumasXPuzzles[qtyKuma] = qtyPuzzle;
    }

    function setKumaContract(address _kumaAddress) external onlyOwner {
        KUMA_CONTRACT_ADDRESS = _kumaAddress;
    }
}