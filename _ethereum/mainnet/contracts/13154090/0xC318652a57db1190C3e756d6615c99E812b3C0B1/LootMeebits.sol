// contracts/LootMeebits.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";

contract LootMeebits is ERC721, Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint16;

    address public meebitsAddress = 0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7;
    ERC721 meebitsContract = ERC721(meebitsAddress);

    //initial prices may be updated
    uint256 public privatePrice = 20000000000000000; //0.02 ETH
    uint256 public publicPrice = 30000000000000000; //0.03 ETH
    bool public saleIsActive = true;
    bool public privateSale = false;

    uint public constant TOKEN_LIMIT = 20000;
    uint public numTokens = 0;
    //// Random index assignment
    uint internal nonce = 0;
    uint[TOKEN_LIMIT] internal indices;

    // Base URI
    string private _baseURI;

    mapping(uint256 => uint256) public meebitsLoot; // mid --> lid

    modifier validNFToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid token.");
        _;
    }

    constructor () public ERC721("Loot (for Meebits)", "Loot4Meebits") {
        _baseURI = "https://ipfs.io//ipfs/QmVsY7rZsCrVdkG9s5ZVqeFYpfz1tWKWYXNz1u2Kp7k6vk/";
    }

    // The deployer can mint without paying
    //    function devMint(uint quantity) public onlyOwner {
    //        for (uint i = 0; i < quantity; i++) {
    //            mintTo(msg.sender, 0);
    //        }
    //    }

    // Private sale minting (reserved for Meebits owners)
    function mintWithMeebits(uint256 mid) external payable {
        require(privateSale, "Private sale minting is over");
        require(saleIsActive, "Sale must be active to mint");
        require(privatePrice <= msg.value, "Ether value sent is not correct");
        require(meebitsContract.ownerOf(mid) == msg.sender, "Not the owner of this meebit.");
        require(!_exists(mid), "Already Minted!");
        require(meebitsLoot[mid] == 0, "Already Minted!");
        mintTo(msg.sender, mid);
    }

    // Public sale minting
    function mint(uint256 quantity) external payable {
        require(quantity > 0, "quantity is zero");
        require(quantity <= (TOKEN_LIMIT.sub(numTokens)), "quantity is so big");
        require(!privateSale, "Public sale minting not started");
        require(saleIsActive, "Sale must be active to mint");
        require(publicPrice.mul(quantity) <= msg.value, "Ether value sent is not correct");
        for (uint i = 0; i < quantity; i++) {
            mintTo(msg.sender, 0);
        }
    }

    // Random mint
    function mintTo(address _to, uint256 mid) internal returns (uint) {
        require(_to != address(0), "Cannot mint to 0x0.");
        require(numTokens < TOKEN_LIMIT, "Token limit reached.");
        uint id = randomIndex();
        numTokens = numTokens + 1;
        _safeMint(msg.sender, id);
        if (mid > 0) {
            meebitsLoot[mid] = id;
        } else {
            meebitsLoot[id] = id;
        }
        return id;
    }

    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    function withdraw() external onlyOwner {
        payable(owner()).send(address(this).balance);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPrivateSale() external onlyOwner {
        privateSale = !privateSale;
    }

    function setPrivatePrice(uint256 newPrice) external onlyOwner {
        privatePrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURI = uri;
    }

    function baseURI() override public view returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        string memory temp = string(abi.encodePacked(_baseURI, toString(_tokenId), ".json"));
        return temp;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

}