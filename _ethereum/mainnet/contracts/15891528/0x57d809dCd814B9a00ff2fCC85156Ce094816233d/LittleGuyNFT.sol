// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract LittleGuyNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private price = 50000000000000000;

    event NewLGGItem(address sender, uint256 tokenId, string name);

    string private baseUri = "https://littleguygang.mypinata.cloud/ipfs/QmTSUzJjSXhtmLmFhTriZ2NPcAAepjDrStZnKmUL9ng9ob/";

    uint private startDate = 1668794400;

    bool private allowListAvailable = false;

    uint256 private createdOwnerNfts = 0;

    mapping(address => bool) private allowList;

    constructor() ERC721("LittleGuyGang", "LGG") {
    }

    function createOwnerNfts(uint256 amount) public onlyOwner{
        require(createdOwnerNfts + amount <= 150, "Can only create 150 nfts for owner");
        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();

            _safeMint(msg.sender, newItemId);

            emit NewLGGItem(msg.sender, newItemId, "Little guy gang");

            _tokenIds.increment();
        }
        createdOwnerNfts += amount;
    }

    function GenerateNFT(uint256 amount) public payable {
        require(startDate < block.timestamp, "Minting has not yet started");
        _mintLGG(amount);
    }

    function _mintLGG(uint256 amount) internal {
        require(amount <= 5 && amount > 0, "Maximum amount of nfts minted in one transaction is 5");
        require(msg.value == price * amount, "Incorrect amount of eth sent.");
        require(_tokenIds.current() + amount - 1 < 10000, "Cant mint over 10000 nfts total");
        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();

            if (newItemId >= 10000) {
                revert("This NFT is sold out.");
            }

            _safeMint(msg.sender, newItemId);

            emit NewLGGItem(msg.sender, newItemId, "Little guy gang");

            _tokenIds.increment();
        }
    }

    function allowListMint(uint256 amount) public payable isAllowListed(msg.sender) {
        require(allowListAvailable, "Allow list minting is not currently available");
        _mintLGG(amount);

        allowList[msg.sender] = false;
    }

    function setPrice(uint _price) public onlyOwner {
        require(_price > 0, "price must be greater than 0");
        price = _price;
    }

    function totalContent() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setStartDate(uint _date) public onlyOwner {
        require(_date > block.timestamp, "date must be in the future");
        startDate = _date;
    }

    function setAllowListAvailable(bool allow) public onlyOwner {
        allowListAvailable = allow;
    }

    function addAllowListedAddresses(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
        }
    }

    modifier isAllowListed(address _address) {
        require(allowList[_address], "You need to be an allow listed address to access this");
        _;
    }

}