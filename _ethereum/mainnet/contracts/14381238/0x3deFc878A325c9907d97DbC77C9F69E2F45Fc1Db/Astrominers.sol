//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "ERC721A.sol";

contract Astrominers is ERC721A, Ownable {
    using Strings for uint256;

    string private baseTokenURI;
    string private metaData;
    string private gameMetaData;
    string private notRevealedUri;
    bytes32 private whitelistRoot;

    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxByWallet = 3;

    uint256 public step = 1;
    bool public revealed = false;

    // 1 = closed
    // 2 = Whitelist
    // 3 = Opensale

    address payable private dev = payable(0x834905facfee88aF8253F9bB17F041fad90FCc1E);
    address payable private invest = payable(0xa4dEAF9a903575A4f2022210bc18790127D080fA);
    address payable private mediaBuyer = payable(0x246d4D9d5e33e1b6ec42D415A2Cf926DC5C48103);

    constructor() ERC721A("Astrominers", "ASTROMINERS") {}

    function mint(uint256 amount) public payable {
        require(step == 3, "Mint is closed");
        require(totalSupply() + amount <= maxSupply, "Sold out !");
        uint256 walletBalance = _numberMinted(msg.sender);
        require(
            walletBalance + amount <= maxByWallet,
            "You have mint the maximum of nft"
        );
        require(msg.value >= cost * amount, "Not enough ether sended");
        _safeMint(msg.sender, amount);
    }

    function mintWl(uint256 amount, bytes32[] calldata proof) public payable {
        require(step == 2, "WL Mint is closed");
        require(isWhitelisted(msg.sender, proof), "You are not in the Whitelist");
        require(totalSupply() + amount <= maxSupply, "Sold out !");

        uint256 walletBalance = _numberMinted(msg.sender);
        require(
            walletBalance + amount <= maxByWallet,
            "You have mint the maximum of nft"
        );
        require(msg.value >= cost * amount, "Not enough ether sended");
        _safeMint(msg.sender, amount);
    }

    function gift(uint256 amount, address to) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Sold out");
        _safeMint(to, amount);
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        require(newSupply <= 8888, "higher than 8888 NFT");
        maxSupply = newSupply;
    }

    function isWhitelisted(address account, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof, whitelistRoot);
    }

    function setWhitelistRoot(bytes32 newWhitelistroot) public onlyOwner {
        whitelistRoot = newWhitelistroot;
    }

    function switchStep(uint256 newStep) public onlyOwner {
        step = newStep;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setMaxByWallet(uint256 newMaxByWallet) public onlyOwner {
        maxByWallet = newMaxByWallet;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function setMetaData(string memory newMetaData) public onlyOwner {
        metaData = newMetaData;
    }

    function _metaData() internal view virtual returns (string memory) {
        return metaData;
    }

    function setGameMetaData(string memory newGameMetaData) public onlyOwner {
        gameMetaData = newGameMetaData;
    }

    function _gameMetaData() internal view virtual returns (string memory) {
        return gameMetaData;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseUri();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function metaDataURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _metaData();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function gameMetaDataURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _gameMetaData();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() external onlyOwner {
        uint partDev = address(this).balance / 1000 * 25;
        uint partInvest = address(this).balance / 1000 * 449;
        uint partMediaBuyer = address(this).balance / 100 * 5;
        dev.transfer(partDev);
        invest.transfer(partInvest);
        mediaBuyer.transfer(partMediaBuyer);
        payable(owner()).transfer(address(this).balance);
    }
}