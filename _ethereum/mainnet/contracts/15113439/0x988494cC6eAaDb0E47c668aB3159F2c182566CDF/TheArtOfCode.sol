//SPDX-License-Identifier: Unlicense
//  _________  ___   ___   ______
// /________/\/__/\ /__/\ /_____/\
// \__.::.__\/\::\ \\  \ \\::::_\/_
//    \::\ \   \::\/_\ .\ \\:\/___/\
//     \::\ \   \:: ___::\ \\::___\/_
//      \::\ \   \: \ \\::\ \\:\____/\
//       \__\/    \__\/ \::\/ \_____\/
//  ________   ______   _________
// /_______/\ /_____/\ /________/\
// \::: _  \ \\:::_ \ \\__.::.__\/
//  \::(_)  \ \\:(_) ) )_ \::\ \
//   \:: __  \ \\: __ `\ \ \::\ \
//    \:.\ \  \ \\ \ `\ \ \ \::\ \
//  ___\__\/\__\/_\_\/ \_\/  \__\/
// /_____/\ /_____/\
// \:::_ \ \\::::_\/_
//  \:\ \ \ \\:\/___/\
//   \:\ \ \ \\:::._\/
//    \:\_\ \ \\:\ \
//  ___\_____\/_\_\/  ______   ______
// /_____/\ /_____/\ /_____/\ /_____/\
// \:::__\/ \:::_ \ \\:::_ \ \\::::_\/_
//  \:\ \  __\:\ \ \ \\:\ \ \ \\:\/___/\
//   \:\ \/_/\\:\ \ \ \\:\ \ \ \\::___\/_
//    \:\_\ \ \\:\_\ \ \\:\/.:| |\:\____/\
//     \_____\/ \_____\/ \____/_/ \_____\/


pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract TheArtOfCode is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeibglli2zdqh7vuqs6yaukraakvu462ar2vuc4iamtzeiiek5chfaq.ipfs.nftstorage.link/metadata";
    uint256 public CODES_SUPPLY = 1000;
    uint256 public MAX_FREE_CODES_SUPPLY = 1000;
    uint256 public MAX_CODES_PER_TX = 5;
    uint256 public MAX_CODES_PER_WALLET = 5;
    uint256 public CODE_PRICE = 0.0099 ether;
    uint256 public MAX_FREE_CODES_PER_WALLET = 1;
    bool public itsAlive = false;
    bool public isCodeCompiled = false;

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("TheArtOfCode", "TAOC") {}

    function writeCode(uint256 numberOfTokens) external payable
    {
        require(itsAlive, "The code is not alive");
        require(numberOfTokens > 0, "Unchaught error");
        require(numberOfTokens <= MAX_CODES_PER_TX, "Max mints per transaction exceeded");

        bool isNotTryingMintMoreThanTotalSupply = totalSupply() + numberOfTokens <= CODES_SUPPLY;
        require(isNotTryingMintMoreThanTotalSupply, "Stack overflow");

        uint256 codesOfSender = balanceOf(msg.sender);

        bool notOverflowTheMaxCodePerWallet = codesOfSender + numberOfTokens <= MAX_CODES_PER_WALLET;
        require(notOverflowTheMaxCodePerWallet, "Don't go over the code limit, dev");

        bool isThereStillFreeCode = totalSupply() <= MAX_FREE_CODES_SUPPLY;
        bool alreadyMintedAFree = qtyFreeMinted[msg.sender] >= MAX_FREE_CODES_PER_WALLET;

        if (alreadyMintedAFree) {
            require(msg.value > 0, "You already minted a free code");
        }

        bool canMintAFree = !alreadyMintedAFree && isThereStillFreeCode;

        bool isTryingToMintAOneFreeMint = canMintAFree
            && numberOfTokens == 1
            && msg.value == 0;

        if (canMintAFree && !isTryingToMintAOneFreeMint) {
            require(msg.value >= (CODE_PRICE * (numberOfTokens - MAX_FREE_CODES_PER_WALLET)), "Don't try hack the contract, dev");
        }

        bool itsAPaidMint = !isTryingToMintAOneFreeMint && (alreadyMintedAFree || !isThereStillFreeCode);
        if (itsAPaidMint) {
            require(msg.value >= (CODE_PRICE * numberOfTokens) , "Incorrect ETH value sent");
        }

        if (canMintAFree) {
            qtyFreeMinted[msg.sender] += 1;
        }

        _safeMint(msg.sender, numberOfTokens);
    }

    function compile(bool _isCodeCompiled) public onlyOwner
    {
        isCodeCompiled = _isCodeCompiled;
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

        if (!isCodeCompiled) {
            return string(abi.encodePacked(baseTokenURI, "/hidden/hidden.json"));
        }

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function setItsAlive(bool _itsAlive) external onlyOwner
    {
        itsAlive = _itsAlive;
    }

    function setCodePrice(uint256 _price) external onlyOwner
    {
        CODE_PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_CODES_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_CODES_PER_WALLET = _limit;
    }

    function setMaxFreeCodesSupply(uint256 _limit) external onlyOwner
    {
        MAX_FREE_CODES_SUPPLY = _limit;
    }
}