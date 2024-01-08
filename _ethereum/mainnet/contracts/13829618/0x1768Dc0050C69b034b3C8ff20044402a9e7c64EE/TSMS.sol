// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721.sol";

contract TheSleeplessMineSociety is Ownable, ERC721Enumerable {
    mapping(address => bool) public isMintPassHolder;

    uint256 constant MAXSUPPLY = 4000;
    uint256 constant PRICE_REGULAR = 0.08 ether;
    uint256 constant MAX_MINT_PER_TX = 5;
    uint256 private constant OLDLIMIT = 942;

    uint256 public price_mintpass = 0.08 ether;
    uint256 public saleStage = 1;
    uint256 public oldClaimed;

    address public immutable deployer;
    string private baseURI;

    IERC721 private immutable oldNFT;

    constructor() ERC721("The Sleepless Mine Society by Sleepless Workshop", "TSMS") {
        _setBaseURI("https://nft.thesleeplessminesociety.com/api/");
        deployer = msg.sender;
        oldNFT = IERC721(0x54591254be285789398719384A75527c68e3060b);

    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function existingSupply() public view returns (uint256) {
        return OLDLIMIT + totalSupply() - oldClaimed;
    }

    function buyExisting(uint256[] calldata oldIDs) external {
        require(saleStage%2 == 0, "Existing buy not active");
        for(uint256 i = 0; i < oldIDs.length; i++) {
            require(oldIDs[i] != 0 && oldIDs[i] <= OLDLIMIT, "Invalid ID");
            require(oldNFT.ownerOf(oldIDs[i]) == msg.sender, "You're not owner of NFT");
            _safeMint(msg.sender, oldIDs[i]);
        }
        oldClaimed += oldIDs.length;
    }

    function sendExisting(uint256[] calldata oldIDs) external onlyOwner {
        for(uint256 i = 0; i < oldIDs.length; i++) {
            require(oldIDs[i] != 0 && oldIDs[i] <= OLDLIMIT, "Invalid ID");
            _safeMint(oldNFT.ownerOf(oldIDs[i]), oldIDs[i]);
        }
        oldClaimed += oldIDs.length;
    }

    function buyWithMintPass() external payable {
        uint256 supply = existingSupply();
        require(saleStage%3 == 0, "Mint pass sale not active");
        require(msg.value == price_mintpass, "Incorrect ETH amount");
        require(supply < MAXSUPPLY, "Not enough tokens left");
        require(isMintPassHolder[msg.sender], "Only available to mint pass holders");

        isMintPassHolder[msg.sender] = false;
        _safeMint(msg.sender, supply + 1);
    }

    function buy(uint256 _count) external payable {
        uint256 supply = existingSupply();
        require(saleStage%5 == 0, "Public sale not active");
        require(_count > 0, "Mint at least one TSMS");
        require(_count <= MAX_MINT_PER_TX, "Max 5 mints allowed");
        require(msg.value == PRICE_REGULAR * _count, "Incorrect ETH amount");
        require(supply + _count <= MAXSUPPLY, "Not enough tokens left");

        for(uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, supply + 1 + i);
        }
    }

    function awardMintPass(address[] memory _wallets) external onlyOwner() {
        for(uint256 i = 0; i < _wallets.length; i++)
            isMintPassHolder[_wallets[i]] = true;
    }

    function setSaleStage(uint256 _stage) external onlyOwner() {
        saleStage = _stage;
    }

    function setMintPassPrice(uint256 _newPrice) external onlyOwner() {
        price_mintpass = _newPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _setBaseURI(newBaseURI);
    }

    function distribute() external {
        require(msg.sender == deployer || msg.sender == owner(), "Go away!");
        payable(deployer).transfer((address(this).balance * 10) / 125);
        payable(owner()).transfer(address(this).balance);
    }

    function _setBaseURI(string memory newBaseURI) internal {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
