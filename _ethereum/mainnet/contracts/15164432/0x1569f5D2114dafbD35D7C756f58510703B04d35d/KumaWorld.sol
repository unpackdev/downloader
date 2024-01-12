//SPDX-License-Identifier: Unlicense

// ██╗  ██╗██╗   ██╗███╗   ███╗ █████╗     ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗
// ██║ ██╔╝██║   ██║████╗ ████║██╔══██╗    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗
// █████╔╝ ██║   ██║██╔████╔██║███████║    ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║
// ██╔═██╗ ██║   ██║██║╚██╔╝██║██╔══██║    ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║
// ██║  ██╗╚██████╔╝██║ ╚═╝ ██║██║  ██║    ╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝
// ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝     ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝
//
// author: Kuma father
//

pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract KumaWorld is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeihxo4xld5vcr7kixuftiili4wwqhjcwq4b3l6ncvycj4vmo5tnhz4.ipfs.nftstorage.link/metadata";
    uint256 public MAX_KUMAS = 5555;
    uint256 public MAX_FREE_KUMAS_SUPPLY = 3333;
    uint256 public MAX_KUMAS_PER_TX = 10;
    uint256 public MAX_KUMAS_PER_WALLET = 10;
    uint256 public PRICE = 0.00666 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    bool public initialize = true;
    bool public revealed = false;

    event NewAdoptedKumas(address sender, uint256 kumas);
    event NewBurnKumas(address sender, uint256 kumas);

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("Kuma World", "KUMA") {}

    function adoptKumas(uint256 kumas) external payable
    {
        require(initialize, "Error not ready");
        require(kumas > 0, "Need to be more than 0");
        require(kumas <= MAX_KUMAS_PER_TX, "Max monsters per transaction exceeded");

        require(totalSupply() + kumas <= MAX_KUMAS, "The mint end");

        uint256 tokensOfSender = balanceOf(msg.sender);

        require(tokensOfSender + kumas <= MAX_KUMAS_PER_WALLET, "More than limit");


        bool isThereStillFreeKumas = totalSupply() < MAX_FREE_KUMAS_SUPPLY;
        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= MAX_FREE_PER_WALLET;

        bool canMintAFree = !alreadyMintedAFree && isThereStillFreeKumas;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free");
        }

        bool isTryingToMintAOneFreeMint = canMintAFree
            && kumas == 1
            && msg.value == 0;

        if (canMintAFree && !isTryingToMintAOneFreeMint) {
            require(msg.value >= (PRICE * (kumas - MAX_FREE_PER_WALLET)), "Error");
        }

        bool itsAPaidMint = !isTryingToMintAOneFreeMint && (alreadyMintedAFree || !isThereStillFreeKumas);
        if (itsAPaidMint) {
            require(msg.value >= (PRICE * kumas) , "Incorrect ETH value sent");
        }

        if (canMintAFree) {
            qtyFreeMinted[msg.sender] += 1;
        }

        _safeMint(msg.sender, kumas);

        emit NewAdoptedKumas(msg.sender, kumas);
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

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxKumasPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_KUMAS_PER_WALLET = _limit;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_KUMAS_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }

    function burnKumas(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            uint256 tokenid = tokenids[i];
            _burn(tokenid);
        }

        emit NewBurnKumas(msg.sender, len);
    }
}