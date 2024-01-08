// SPDX-License-Identifier: MIT
/// @title: Skunks
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract NiceSkunks is ERC721Enumerable, Pausable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 public MAX_SUPPLY = 11111;
    uint16 _maxPurchaseCount = 10;
    uint16 _remainingPresaleClaims = 2806;
    uint256 _mintPrice = 0.1 ether;
    uint256 _saleStart;
    uint256 _presaleStart;
    string _baseURIValue;
    bytes32 _merkleRoot;
    mapping(address => bool) _presaleMintClaimed;

    constructor(
        uint256 saleStart_,
        string memory baseURIValue_,
        address[] memory payees,
        uint256[] memory paymentShares,
        bytes32 presaleMerkleRoot
    ) ERC721("Nice Skunks", "SKUNK") PaymentSplitter(payees, paymentShares) {
        _baseURIValue = baseURIValue_;
        _saleStart = saleStart_;
        _presaleStart = _saleStart - 24 * 60 * 60;
        _merkleRoot = presaleMerkleRoot;

        for (uint256 i = 0; i < payees.length; i++) {
            _mintTokens(1, payees[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSaleStart(uint256 saleStart_) public onlyOwner {
        _saleStart = saleStart_;
    }

    function setPresaleStart(uint256 presaleStart_) public onlyOwner {
        _presaleStart = presaleStart_;
    }

    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint256) {
        return _presaleStart;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return _presaleStart <= block.timestamp;
    }

    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint8 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }

    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY.sub(totalSupply());
    }

    function remainingPresaleSupply() public view returns (uint256) {
        return MAX_SUPPLY.sub(totalSupply()).sub(_remainingPresaleClaims);
    }

    function remainingPresaleClaims() public view returns (uint16) {
        return _remainingPresaleClaims;
    }

    function senderHasClaimedPresale() public view returns (bool) {
        return _presaleMintClaimed[msg.sender];
    }

    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        _merkleRoot = root;
    }

    modifier mintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier merkleProofMatchesSender(bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, _merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        _;
    }

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 10 tokens at a time"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    function _mintTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function mintTokens(uint256 numberOfTokens)
        external
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(saleHasStarted(), "Sale has not started yet");

        _mintTokens(numberOfTokens, msg.sender);
    }

    function claimPresale(bytes32[] calldata merkleProof)
        external
        mintCountMeetsSupply(1)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(1)
        merkleProofMatchesSender(merkleProof)
    {
        require(presaleHasStarted(), "Presale has not started yet");
        require(!saleHasStarted(), "Free claim period has ended");
        require(
            !_presaleMintClaimed[msg.sender],
            "You have already claimed your presale token"
        );

        _presaleMintClaimed[msg.sender] = true;
        _remainingPresaleClaims -= 1;

        _mintTokens(1, msg.sender);
    }

    function buyPresale(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        mintCountMeetsSupply(numberOfTokens)
        whenNotPaused
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        merkleProofMatchesSender(merkleProof)
        validatePurchasePrice(numberOfTokens)
    {
        require(presaleHasStarted(), "Presale has not started yet");
        require(
            totalSupply().add(_remainingPresaleClaims).add(numberOfTokens) <=
                MAX_SUPPLY,
            "No more presale purchases available. Please wait until primary sale starts"
        );

        _mintTokens(numberOfTokens, msg.sender);
    }
}
