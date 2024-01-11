//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

///@title BigBrainKids NFT Contract

contract BigBrainKids is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MINT_PRICE = 0.07 ether;
    uint256 public constant AMOUNT_FOR_TEAM = 100;

    uint256 public batch1MaxSupply;
    uint256 public batch2MaxSupply;
    uint256 public publicMaxMintAmount = 4;
    bytes32 public merkleRootB1;
    bytes32 public merkleRootB2;
    bool public publicActive = false;
    bool public batch1Active = false;
    bool public batch2Active = false;

    Counters.Counter private supply;
    Counters.Counter private batch1Supply;
    Counters.Counter private batch2Supply;
    string private _baseTokenURI;

    mapping(address => bool) public whitelistClaimed;

    modifier callerIsUser() {
        require(tx.origin == msg.sender);
        _;
    }

    constructor(string memory _unrevealedURI) ERC721("BigBrainKids", "BBK") {
        _baseTokenURI = _unrevealedURI;
        _mintLoop(msg.sender, AMOUNT_FOR_TEAM);
    }

    //External functions
    function batch1Mint(bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        require(batch1Active, "whitelist mint is not active!");
        require(
            batch1Supply.current() + 1 <= batch1MaxSupply,
            "whitelist mint capacity reached"
        );
        checkRequirements(msg.sender, proof, merkleRootB1);
        whitelistClaimed[msg.sender] = true;
        batch1Supply.increment();
        _mint(msg.sender);
    }

    function batch2Mint(bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        require(batch2Active, "reserve list mint is not active!");
        require(
            batch2Supply.current() + 1 <= batch2MaxSupply,
            "reserve list mint capacity reached"
        );
        checkRequirements(msg.sender, proof, merkleRootB2);
        whitelistClaimed[msg.sender] = true;
        batch2Supply.increment();
        _mint(msg.sender);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(publicActive, "Public mint is not active!");
        require(
            quantity <= publicMaxMintAmount,
            "quantity exceeds allowed mint quantity!"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mintAmount exceeds totalSupply!"
        );
        require(msg.value == MINT_PRICE * quantity, "ETH amount invalid!");
        _mintLoop(msg.sender, quantity);
    }

    function devMint(address to, uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint exceeds MAX_SUPPLY"
        );
        _mintLoop(to, quantity);
    }

    function setBatch1MaxSupply(uint256 quantity) external onlyOwner {
        uint256 remaining = MAX_SUPPLY - AMOUNT_FOR_TEAM;
        require(quantity <= remaining, "allowed quantity exceeded");
        uint256 batch2MaxSupply_ = remaining - quantity;
        batch1MaxSupply = quantity;
        batch2MaxSupply = batch2MaxSupply_;
    }

    function setBatch1Active(bool b) external onlyOwner {
        batch1Active = b;
    }

    function setBatch2Active(bool b) external onlyOwner {
        batch2Active = b;
    }

    function setSaleActive(bool b) external onlyOwner {
        batch1Active = b;
        batch2Active = b;
    }

    function setPublicActive(bool b) external onlyOwner {
        publicActive = b;
    }

    function setPublicMaxMintAmount(uint256 amount) external onlyOwner {
        publicMaxMintAmount = amount;
    }

    function setMerkleRootB1(bytes32 _merkleRootB1) external onlyOwner {
        merkleRootB1 = _merkleRootB1;
    }

    function setMerkleRootB2(bytes32 _merkleRootB2) external onlyOwner {
        merkleRootB2 = _merkleRootB2;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(0xE66DFC56Da47145aa46DB81Da2274c75278260BB)
            .call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    //Public functions
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function getBatch1Supply() public view returns (uint256) {
        return batch1Supply.current();
    }

    function getBatch2Supply() public view returns (uint256) {
        return batch2Supply.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function walletOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    //Internal functions
    function checkRequirements(
        address account,
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) internal {
        require(!whitelistClaimed[account], "Already minted!");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(account))
            ),
            "address not whitelisted for this batch!"
        );
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "mint amount exceeds max supply!"
        );
        require(msg.value == MINT_PRICE, "ETH amount invalid!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _mintLoop(address to, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            supply.increment();
            _safeMint(to, supply.current());
        }
    }

    function _mint(address to) internal {
        supply.increment();
        _safeMint(to, supply.current());
    }
}
