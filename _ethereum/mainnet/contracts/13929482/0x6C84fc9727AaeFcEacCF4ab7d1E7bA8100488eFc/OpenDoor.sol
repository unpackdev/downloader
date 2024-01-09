//SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./Base64.sol";
import "./PackDoor.sol";

contract OpenDoor is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    uint256 public maxDoors;
    uint256 public maxGiftedDoors;
    uint256 public numGiftedDoors;

    uint256 public constant PUBLIC_SALE_PRICE = 0.05 ether;
    bool public isPublicSaleActive = false;


    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier canMintDoors(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxDoors,
            "Not enough doors remaining to mint"
        );
        _;
    }

     modifier canGiftDoors(uint256 num) {
        require(
            numGiftedDoors + num <= maxGiftedDoors,
            "Not enough witches remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxDoors,
            "Not enough witches remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(
        uint256 _maxDoors,
        uint256 _maxGiftedDoors
    ) ERC721("Meta User Dungeon - cycle 0", "CYCLEZERO") {
        maxDoors = _maxDoors;
        maxGiftedDoors = _maxGiftedDoors;
    }
    event doorMinted(address sender, uint256 tokenId);

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintDoors(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            
    string memory json = PackDoor.buildDoor(tokenCounter.current());
    
    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );
    console.log(finalTokenUri);
            _safeMint(msg.sender, nextTokenId());
            _setTokenURI(tokenCounter.current(), finalTokenUri);
        }
    }
    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftDoors(numToReserve)
    {
        numGiftedDoors += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            string memory json = PackDoor.buildDoor(tokenCounter.current());
        string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );
            _safeMint(msg.sender, nextTokenId());
            _setTokenURI(tokenCounter.current(), finalTokenUri);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }
}