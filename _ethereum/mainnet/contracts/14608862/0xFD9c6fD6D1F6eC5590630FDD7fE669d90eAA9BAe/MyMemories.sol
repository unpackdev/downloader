// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract MyMemories is ContextMixin, ERC721A, NativeMetaTransaction, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    string public contractURI;

    uint256 public maxSupply = 10000;

    bool public isMetaDataFrozen = false;

    string public ghostTokenURI;
    string public baseTokenURI;

    address public ukraineWallet;
    uint private ukraineWalletPercentage = 50;

    uint256 public mintMinimumPrice = 0.05 ether;

    uint256 public ukraineWalletBalance = 0 ether;

    uint256 public startTime = 1647457200;
    uint256 public revealTime = 1647802800;

    string private _name = "MY UKRAINIAN MEMORIES";
    string private _symbol = "MUM";

    modifier notFrozenMetaData {
        require(
            !isMetaDataFrozen,
            "metadata frozen"
        );
        _;
    }

    modifier mintHasStarted {
        require(
            block.timestamp >= startTime,
            "It's not time yet"
        );
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    constructor(string memory _baseTokenURI, string memory _ghostTokenURI, address _ukraineWallet) ERC721A(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        ghostTokenURI = _ghostTokenURI;
        ukraineWallet = _ukraineWallet;
        _initializeEIP712(_name);
    }

    function publicMint(uint256 count) external payable mintHasStarted {
        require(msg.value >= (count * mintMinimumPrice), "Wrong amount");
        require(count > 0 && count <= 9, "Wrong amount");

        buyAmount(count);
        ukraineWalletBalance += msg.value * ukraineWalletPercentage / 100;
    }

    function buyAmount(uint256 count) private {
        require(totalSupply() + count <= maxSupply, "Max Public Supply");
        _safeMint(_msgSender(), count);
    }

    function mintMany(uint256 num, address _to) public onlyOwner {
        require(num <= 9, "Max 9 Per TX.");
        require(totalSupply() + num < maxSupply, "Max Supply");
        _safeMint(_to, num);
    }

    function mintTo(address _to) public onlyOwner {
        require(totalSupply() < maxSupply, "Max Supply");
        _safeMint(_to, 1);
    }

    // withdraw function for the contract owner
    function withdraw() external nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance - ukraineWalletBalance);
    }

    // make the 50% donation to the Ukraine address
    function makeDonationToUkraine() external nonReentrant onlyOwner {
        payable(ukraineWallet).transfer(ukraineWalletBalance);
        ukraineWalletBalance = 0 ether;
    }

    function setRevealTime(uint256 time) external onlyOwner {
        revealTime = time;
    }

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setBaseUri(string memory _uri) external onlyOwner notFrozenMetaData {
        baseTokenURI = _uri;
    }

    function setGhostUri(string memory _uri) external onlyOwner notFrozenMetaData {
        ghostTokenURI = _uri;
    }

    function setContractUri(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function updateUkraineWallet(address _ukraineWallet) external onlyOwner {
        ukraineWallet = _ukraineWallet;
    }

    function setMinimumMintPrice(uint256 newMinimumMintPrice) external nonReentrant onlyOwner{
        mintMinimumPrice = newMinimumMintPrice;
    }

    // in case the contract is not fully minted out have the ability to cut the supply
    function shrinkSupply(uint256 newMaxSupply) external nonReentrant onlyOwner {
        require(totalSupply() <= newMaxSupply, "ERR: minted > new!");
        require(newMaxSupply <= maxSupply, "ERR: cant increase max supply");
        maxSupply = newMaxSupply;
    }

    function freezeMetaData() public onlyOwner {
        require(block.timestamp > revealTime, "Freeze after reveal");
        isMetaDataFrozen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (block.timestamp < revealTime) {
            return string(abi.encodePacked(ghostTokenURI));
        }
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
