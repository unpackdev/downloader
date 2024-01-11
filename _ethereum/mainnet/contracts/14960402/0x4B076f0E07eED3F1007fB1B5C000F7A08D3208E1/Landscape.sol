//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Landscape is
ERC721,
IERC2981,
Ownable,
ReentrancyGuard,
PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    address proxyRegistryAddress;

    uint256 public maxSupply = 10319;

    string public tokenBaseUri;
    string public baseExtension = ".json";

    bool public paused = false;
    bool public publicM = true;

    uint256 public publicSaleAmountLimit = 20;

    uint256 public price = 0.01 ether;

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [100];
    address[] private _team = [
    0x1188aa75C38E1790bE3768508743FBE7b50b2153
    ];

    constructor(
        string memory _tokenBaseUri,
        address _proxyRegistryAddress
    )
    ERC721("AILandscape", "AILAND")
    PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
    ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        setTokenBaseUri(_tokenBaseUri);
    }

    function setTokenBaseUri(string memory _tokenBaseUri) public onlyOwner {
        tokenBaseUri = _tokenBaseUri;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts
    {
        require(publicM, "Landscape: PublicSale is OFF");
        require(!paused, "Landscape: Contract is paused");
        require(_amount > 0, "Landscape: zero amount");
        require(_amount <= publicSaleAmountLimit, "Landscape: You can't mint so much tokens");

        uint current = _tokenIds.current();

        require(current + _amount <= maxSupply, "Landscape: Max supply exceeded");
        require(price * _amount <= msg.value, "Landscape: Not enough ethers sent");


        for (uint i = 0; i < _amount; i++) {
            mintInternal(msg.sender);
        }
    }

    function reward(address rewardAddress, uint256 _amount) external onlyOwner
    {
        uint current = _tokenIds.current();
        require(_amount > 0, "Landscape: zero amount");
        require(_amount + current <= maxSupply, "Landscape: too much");

        for (uint i = 0; i < _amount; i++) {
            mintInternal(rewardAddress);
        }
    }

    function mintInternal(address recipientAddress) internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(recipientAddress, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = tokenBaseUri;

        return bytes(currentBaseURI).length > 0 ?
        string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                baseExtension
            )
        )
        : "";
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Landscape: nothing there");
        return (receiver, (salePrice * 5) / 100);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
