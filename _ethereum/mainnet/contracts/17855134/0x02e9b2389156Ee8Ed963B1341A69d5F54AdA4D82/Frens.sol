// SPDX-License-Identifier: MIT
/*

7,777 cc0 frENS, shilling nonsense, yelling
at Nick. eth, and praying for SIWE.

Twitter: https://twitter.com/frENSNFT_
Website: https://frens.studio
Discord: https://discord.gg/mXjrqK9b

================Easter Eggs================

Winner for each riddle will get a 0.25 eth prize.
To claim your prize, DM us on Twitter (frENSNFT_)
with the hash transaction and answer.

Riddle 1:
I'm a breeze in summer, refreshing and fine,
Not hot, not warm, but pleasantly right.
In emotions, I might make you frown,
In a city, you'll find me in the heart of the town.

Who am I?

Riddle 2:
I'm not this, I'm not that, a category I'm not.
When one is chosen, I'm what they've got.
On paper's stage, I take my form,
A history of choices, norms to reform.

Who am I?

*/
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./IDelegationRegistryExcerpt.sol";

contract Frens is DefaultOperatorFilterer, ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    address public snapshotContract;
    address private constant _DELEGATION_REGISTRY = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    string internal uri;

    string internal uriSuffix = ".json";

    string internal hiddenMetadataUri;

    uint256 public cost;

    uint256 public maxSupply;

    uint256 public maxMintAmountPerTx;

    bool public paused = true;

    bool public revealed = false;

    bool public presale = false;

    bytes32 internal merkleRoot;

    address public feeReceiver;

    address public riddle1Winner;

    address public riddle2Winner;

    mapping(address => bool) public whitelistClaimed;

    mapping(address => uint) public walletMints;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTrx
    ) ERC721(_name, _symbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTrx;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount)
    {
        require(!paused, "Mint have not started yet");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        require(walletMints[msg.sender] + _mintAmount <= maxMintAmountPerTx, "Maximum mints per wallet limit exceeded");
        walletMints[msg.sender] = walletMints[msg.sender] + _mintAmount;
        _mintLoop(msg.sender, _mintAmount);
    }

    function whitelistMint(address vault, uint256 _mintAmount, bytes32[] calldata _merkleProof)
    public
    payable
    mintCompliance(_mintAmount)
    {
        require(presale, "Presale is not active.");

        address claimer = msg.sender;

        if (vault != address(0) && vault != msg.sender) {
            require(IDelegationRegistry(_DELEGATION_REGISTRY).checkDelegateForContract(msg.sender, vault, snapshotContract), 'Not delegated on contract');
            claimer = vault;
        }

        require(!whitelistClaimed[claimer], "Address has already claimed.");
        require(_mintAmount <= 4, "Max 4 per WL wallet.");
        if (_mintAmount > 1) {
            require(msg.value >= (cost * (_mintAmount - 1)), "Insufficient funds!");
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer))));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        whitelistClaimed[claimer] = true;
        walletMints[claimer] = walletMints[claimer] + _mintAmount;
        _mintLoop(claimer, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
    public
    mintCompliance(_mintAmount)
    onlyOwner
    {
        _mintLoop(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                _tokenId.toString(),
                uriSuffix
            )
        )
        : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
    public
    onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
    public
    onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPresale(bool _bool) public onlyOwner {
        require(snapshotContract != address(0), 'Snapshot contract not set');
        require(merkleRoot != bytes32(0), 'MerkleRoot not set');
        presale = _bool;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function withdraw() public onlyOwner {
        require(feeReceiver != address(0), 'Fee receiver unset');
        (bool os, ) = payable(feeReceiver).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function setWithdrawReceiver(address _receiver) public onlyOwner {
        feeReceiver = _receiver;
    }

    function setSnapShotContract(address _contract) public onlyOwner {
        snapshotContract = _contract;
    }

    function getMintedAmount(address _address) public view returns (uint256) {
        return walletMints[_address];
    }

    function isWl(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_address))));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) return true; else return false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function answerRiddle1(string memory word) public {
        bytes32 answer = 0x600c9e601db6b78478816ba89472d10c317ad5c5de0c730d5445d564063d0928;
        bytes32 answer2 = 0x1a2b422a98e5997505ec11e80526a028849794d1ce7b18f7b3b86467bf527132;
        require(!paused, 'It is too early for an answer');
        require(riddle1Winner == address(0), 'Riddle has been already answered');
        require(sha256(abi.encodePacked(word)) == answer || sha256(abi.encodePacked(word)) == answer2, 'Wrong answer');
        riddle1Winner = msg.sender;
    }

    function answerRiddle2(string memory word) public {
        bytes32 answer = 0x36b9a725939ace7a71e1241a3bb02c92ddb0c27aa31d111262544d35e6979c73;
        bytes32 answer2 = 0xac284abad8e59f9958b1bafb227bee6ab4d1233ec9c3fab565920744e6b49b2a;
        require(!paused, 'It is too early for an answer');
        require(riddle2Winner == address(0), 'Riddle has been already answered');
        require(sha256(abi.encodePacked(word)) == answer || sha256(abi.encodePacked(word)) == answer2, 'Wrong answer');
        riddle2Winner = msg.sender;
    }

    receive() external payable {}

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
