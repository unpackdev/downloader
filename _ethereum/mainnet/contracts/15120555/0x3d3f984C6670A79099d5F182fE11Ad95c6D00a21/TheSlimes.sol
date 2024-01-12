// ▄▄▄█████▓ ██░ ██ ▓█████      ██████  ██▓     ██▓ ███▄ ▄███▓▓█████   ██████
// ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▒██    ▒ ▓██▒    ▓██▒▓██▒▀█▀ ██▒▓█   ▀ ▒██    ▒
// ▒ ▓██░ ▒░▒██▀▀██░▒███      ░ ▓██▄   ▒██░    ▒██▒▓██    ▓██░▒███   ░ ▓██▄
// ░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄      ▒   ██▒▒██░    ░██░▒██    ▒██ ▒▓█  ▄   ▒   ██▒
//   ▒██▒ ░ ░▓█▒░██▓░▒████▒   ▒██████▒▒░██████▒░██░▒██▒   ░██▒░▒████▒▒██████▒▒
//   ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░   ▒ ▒▓▒ ▒ ░░ ▒░▓  ░░▓  ░ ▒░   ░  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░
//     ░     ▒ ░▒░ ░ ░ ░  ░   ░ ░▒  ░ ░░ ░ ▒  ░ ▒ ░░  ░      ░ ░ ░  ░░ ░▒  ░ ░
//   ░       ░  ░░ ░   ░      ░  ░  ░    ░ ░    ▒ ░░      ░      ░   ░  ░  ░
//           ░  ░  ░   ░  ░         ░      ░  ░ ░         ░      ░  ░      ░

// รรรรђђzzzz รlเ๓єร คгє Ŧгєє ๓เภt รรรรђђzzzz
// รรรรђђzzzz tђคภкร Ŧ๏г ςς๏! รรรรђђzzzz
// รรรรђђzzzz Ŧгєє ๓เภt เร tђє קгєรєภt! รรรรђђzzzz
// รรรรђђzzzz tђคภкร คzยкเ Ŧ๏г 721ค รรรรђђzzzz

pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract TheSlimes is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeiajrqi7e3b4yk7kgrd5xxf3zhj2c3lakwl6gb6a2aqlqmuxssut7a.ipfs.nftstorage.link/metadata/";
    uint256 public TOTAL_SLIMES = 5555;
    uint256 public MAX_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;
    uint256 public PRICE = 0.003 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public slimesgogo = 2;
    string public clothlink;
    bool public initialize = true;

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("The Slimes", "TSME") {}

    function mintSlimes(uint256 slimes) external payable
    {
        require(initialize, "Error not ready");
        require(slimes > 0, "Need to be more than 0");
        require(slimes <= MAX_PER_TX, "Max mints per transaction exceeded");

        require(totalSupply() + slimes <= TOTAL_SLIMES, "The mint end");

        uint256 tokensOfSender = balanceOf(msg.sender);

        require(tokensOfSender + slimes <= MAX_PER_WALLET, "More than limit");

        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= MAX_FREE_PER_WALLET;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free");
        }

        bool isTryingToMintAOneFreeMint = !alreadyMintedAFree
            && slimes == 1
            && msg.value == 0;

        if (!alreadyMintedAFree && !isTryingToMintAOneFreeMint) {
            require(msg.value >= (PRICE * (slimes - MAX_FREE_PER_WALLET)), "Error");
        }

        bool itsAPaidMint = !isTryingToMintAOneFreeMint && alreadyMintedAFree;
        if (itsAPaidMint) {
            require(msg.value >= (PRICE * slimes) , "Incorrect ETH value sent");
        }

        if (!alreadyMintedAFree) {
            qtyFreeMinted[msg.sender] += 1;
        }

        _safeMint(msg.sender, slimes);
    }

    function spreadslime(uint256 _gogo) external onlyOwner {
        slimesgogo = _gogo;
    }

    function makeslimescloth(string memory cloth) external onlyOwner {
        clothlink = cloth;
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

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }
}