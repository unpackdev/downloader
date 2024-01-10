// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";

contract CosmicPoem is Ownable, ERC721A, ERC721ABurnable {
    enum ContractStatus {
        Paused,
        Public,
        AllowList
    }

    enum PoemType {
        Regular,
        Intuitive,
        Puzzle
    }

    struct SpecialPoem {
        // The address of the claimer.
        // Or Puzzle Key if not claimed yet.
        address addr;
        PoemType poemType;
        uint64 claimedTimestamp;
        bool claimed;
    }

    ContractStatus public contractStatus = ContractStatus.Paused;
    uint256 public immutable maxPerAddressDuringMint = 2;
    uint256 public immutable amountForDevs = 9;
    uint256 public immutable collectionSize = 333;
    uint256 public immutable amountForIntuitives = 33;
    uint256 public immutable amountForPuzzles = 3;
    uint256 public salePrice = 0.083 ether;

    bool public isIntuitivePoemsSet = false;
    bool public isPuzzlePoemsSet = false;

    string private _baseTokenURI;

    mapping(address => uint256) public allowlist;
    mapping(uint256 => SpecialPoem) private specialPoems;

    constructor() ERC721A("Cosmic Poem", "CP") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier callerIsTokenOwner(uint256 tokenId) {
        require(ownershipOf(tokenId).addr == msg.sender, "Not owner of token");
        _;
    }

    modifier tokenInBounds(uint256 tokenId) {
        require(tokenId < collectionSize, "Token is out of bounds");
        _;
    }

    modifier allPoemsMinted() {
        require(
            totalMinted() == collectionSize,
            "Not all poems are minted yet"
        );
        _;
    }

    function setContractStatus(ContractStatus status) external onlyOwner {
        contractStatus = status;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        salePrice = price;
    }

    function seedAllowList(address[] memory addresses, uint256 numSlot)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlot;
        }
    }

    function allowListMint(uint256 quantity) external payable callerIsUser {
        require(
            contractStatus == ContractStatus.AllowList,
            "allowlist sale has not begun yet"
        );
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(quantity <= allowlist[msg.sender], "can not mint this many");
        require(
            totalMinted() + quantity <= collectionSize,
            "reached max supply"
        );
        require(msg.value >= salePrice * quantity, "need to send more ETH.");
        allowlist[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(
            contractStatus == ContractStatus.Public,
            "public sale has not begun yet"
        );
        require(
            totalMinted() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        require(msg.value >= salePrice * quantity, "need to send more ETH.");
        _safeMint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalMinted() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function numberClaimed(address owner) public view returns (uint256) {
        return _numberClaimed(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function seedIntuitivePoems(uint256[] memory poems)
        external
        onlyOwner
        allPoemsMinted
    {
        require(poems.length == amountForIntuitives, "Not enough poems to set");
        require(!isIntuitivePoemsSet, "Intuive Poems have already been set");
        for (uint256 i = 0; i < poems.length; i++) {
            setSpecialPoem(poems[i], PoemType.Intuitive, address(0));
        }
        isIntuitivePoemsSet = true;
    }

    function seedPuzzlePoems(uint256[] memory poems, address[] memory addresses)
        external
        onlyOwner
        allPoemsMinted
    {
        require(
            poems.length == addresses.length,
            "Poems do not match addresses length"
        );
        require(poems.length == amountForPuzzles, "Not enough poems to set");
        require(!isPuzzlePoemsSet, "Puzzles have already been set");
        for (uint256 i = 0; i < poems.length; i++) {
            setSpecialPoem(poems[i], PoemType.Puzzle, addresses[i]);
        }
        isPuzzlePoemsSet = true;
    }

    function setSpecialPoem(
        uint256 tokenId,
        PoemType poemType,
        address addr
    ) private tokenInBounds(tokenId) {
        SpecialPoem storage poem = specialPoems[tokenId];
        require(poem.poemType == PoemType.Regular, "Poem is already set");
        poem.addr = addr;
        poem.poemType = poemType;
    }

    function claimIntuitivePoem(uint256 tokenId)
        external
        allPoemsMinted
        callerIsTokenOwner(tokenId)
    {
        SpecialPoem storage poem = specialPoems[tokenId];
        require(
            poem.poemType == PoemType.Intuitive,
            "Poem is not correct type"
        );
        require(!poem.claimed, "Poem has already been claimed");

        setSpecialPoemClaimed(poem);
    }

    function claimPuzzlePoem(uint256 tokenId, bytes32 _solution)
        external
        allPoemsMinted
        callerIsTokenOwner(tokenId)
    {
        SpecialPoem storage poem = specialPoems[tokenId];
        require(poem.poemType == PoemType.Puzzle, "Poem is not correct type");
        require(!poem.claimed, "Poem has already been claimed");
        require(
            address(uint160(uint256(keccak256(abi.encodePacked(_solution))))) ==
                poem.addr,
            "Incorrect answer"
        );

        setSpecialPoemClaimed(poem);
    }

    function setSpecialPoemClaimed(SpecialPoem storage poem) private {
        poem.addr = msg.sender;
        poem.claimed = true;
        poem.claimedTimestamp = uint64(block.timestamp);
        _addNumberClaimed(msg.sender, 1);
    }

    function getSpecialPoem(uint256 tokenId)
        external
        view
        allPoemsMinted
        tokenInBounds(tokenId)
        returns (SpecialPoem memory poem)
    {
        poem = specialPoems[tokenId];
        require(poem.poemType != PoemType.Regular, "Poem is not special");
        return poem;
    }

    function listIntuitivePoems() external view returns (uint256[] memory) {
        require(isIntuitivePoemsSet, "Intuitive Poems have not been set yet");
        uint256[] memory result = new uint256[](amountForIntuitives);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalMinted(); i++) {
            SpecialPoem memory poem = specialPoems[i];
            if (poem.poemType == PoemType.Intuitive) {
                result[counter] = i;
                counter++;
            }
            if (counter == amountForIntuitives) break;
        }
        return result;
    }

    function listPuzzlePoems() external view returns (uint256[] memory) {
        require(isPuzzlePoemsSet, "Puzzles have not been set yet");
        uint256[] memory result = new uint256[](amountForPuzzles);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalMinted(); i++) {
            SpecialPoem memory poem = specialPoems[i];
            if (poem.poemType == PoemType.Puzzle) {
                result[counter] = i;
                counter++;
            }
            if (counter == amountForPuzzles) break;
        }
        return result;
    }
}
