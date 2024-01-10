// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./PullPayment.sol";
import "./Ownable.sol";

contract FootHeroesClub is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    bool public isAirdropActive;

    struct Sale {
        uint state;
        uint maxTokensPerAddress;
    }
    // Constants
    uint256 public constant TOTAL_SUPPLY = 8888;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MINT_PRICE_WHITELIST = 0.088 ether;


    Sale public sale;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public tokensMintedByAddress;
    mapping(address => uint8) public airdropAllowance;

    Counters.Counter private currentTokenId;


    string public baseTokenURI;


    constructor() ERC721("FootHeroesClub", "Footies"){}


    function totalSupply() public view returns (uint) {
        return currentTokenId.current();
    }

    function mintTo(address recipient, uint mintAmount) public payable
    {
        require(sale.state != 0, "Sale is not active");
        uint256 price = MINT_PRICE;
        if (sale.state == 1) {
            require(isWhitelisted[recipient], "Only whitelisted users allowed during presale");
            price = MINT_PRICE_WHITELIST;
        }
        uint256 tokenId = currentTokenId.current();

        require(mintAmount > 0, "You must mint at least 1 NFT");
        require(tokensMintedByAddress[recipient] + mintAmount <= sale.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
        require(tokenId + mintAmount <= TOTAL_SUPPLY, "Max supply reached");
        require(msg.value >= price * mintAmount, "Transaction value did not equal the mint price");

        for (uint i = 0; i < mintAmount; i++) {
            currentTokenId.increment();
            _safeMint(recipient, currentTokenId.current());
        }
        tokensMintedByAddress[recipient] += mintAmount;
    }

    function claimAirdrop() public {
        require(isAirdropActive, "Airdrop is inactive");
        uint allowance = airdropAllowance[msg.sender];
        uint256 tokenId = currentTokenId.current();

        require(allowance > 0, "You have no airdrops to claim");
        require(tokenId + allowance <= TOTAL_SUPPLY, "Max supply exceeded");
        for (uint i = 0; i < allowance; i++) {
            currentTokenId.increment();
            _safeMint(msg.sender, currentTokenId.current());
        }
        airdropAllowance[msg.sender] = 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSaleDetails(
        uint state,
        uint maxTokensPerAddress
    ) public onlyOwner {
        sale.state = state;
        sale.maxTokensPerAddress = maxTokensPerAddress;
    }

    function setAirdropActive(bool state) public onlyOwner {
        isAirdropActive = state;
    }

    function setAirdropAllowance(address[] calldata users, uint8[] calldata allowances) public onlyOwner {
        require(users.length == allowances.length, "Length mismatch");
        for (uint i = 0; i < users.length; i++) {
            airdropAllowance[users[i]] = allowances[i];
        }
    }

    function whitelist(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            isWhitelisted[users[i]] = true;
        }
    }

    function unWhitelist(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            isWhitelisted[users[i]] = false;
        }
    }

    function withdraw() public payable onlyOwner virtual {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success, "Withdrawal of funds failed");
    }
}
