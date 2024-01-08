// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
abstract contract BadKidsAlley {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address owner) external view virtual returns (uint256 balance);
}
contract SpookyKidsAlley is ERC721Enumerable, Ownable {
    BadKidsAlley private BKA;
    uint256 public MAX_SKA_ADOPTION = 50;
    uint256 public constant MAX_SUPPLY = 8888;
    bool public spookIsOn = false;
    string private baseURI = "https://spookykids.nftdata.art/meta/";
    event SpookySpirit(bool status);
    event SpookyMint(address adopter, uint256 amount);
    constructor(address BKAAddress)ERC721("SpookyKidsAlley", "SKA")
    {
        BKA = BadKidsAlley(BKAAddress);
    }
    function singleSKA(uint256 bkaId) public {
        require(spookIsOn, "SPOOKY_OFF");
        require(bkaId < MAX_SUPPLY, "INVALID_TOKEN_ID");
        require(!_exists(bkaId), "ALREADY_GENERATED");
        require(BKA.ownerOf(bkaId) == msg.sender, "MISSING_ASSOCIATED_BKA");
        _safeMint(msg.sender, bkaId);
        emit SpookyMint(msg.sender, 1);
    }
    function multiSKA(uint256[] calldata BKAIds) public {
        uint256 numBKA = BKAIds.length;
        uint256 balance = BKA.balanceOf(msg.sender);
        require(spookIsOn, "SPOOKY_OFF");
        require(numBKA <= MAX_SKA_ADOPTION, "MAX_TRANSACTION_SIZE");
        require(totalSupply() + numBKA < MAX_SUPPLY, "SOLD_OUT");
        require(balance > 0, "NO_BKA_OWNED");
        require(balance >= numBKA, "INVALID_TOKEN_IDS");
        for (uint256 i = 0; i < numBKA; i++) {
            uint256 bkaId = BKAIds[i];
            require(bkaId < MAX_SUPPLY, "INVALID_TOKEN_ID");
            require(
                BKA.ownerOf(bkaId) == msg.sender,
                "MISSING_ASSOCIATED_BKA"
            );
            require(!_exists(bkaId), "ALREADY_GENERATED");
            _safeMint(msg.sender, bkaId);
        }
        emit SpookyMint(msg.sender, numBKA);
    }
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
    function isGenerated(uint256 tokenId) external view returns (bool) {
        require(tokenId < MAX_SUPPLY, "INVALID_TOKEN_ID");
        return _exists(tokenId);
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    function setDependentContract(address BKAAddress) public onlyOwner {
        BKA = BadKidsAlley(BKAAddress);
    }
    function spookySwitch() public onlyOwner {
        spookIsOn = !spookIsOn;
        emit SpookySpirit(spookIsOn);
    }
    function setMaxPerTransaction(uint256 amount) public onlyOwner {
        MAX_SKA_ADOPTION = amount;
    }
}