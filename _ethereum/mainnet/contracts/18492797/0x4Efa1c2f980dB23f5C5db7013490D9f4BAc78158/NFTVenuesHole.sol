// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721BurnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract NFTVenuesHole is DefaultOperatorFiltererUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable {

    // Whitelist state
    struct WhiteList {
        // The amount to pay
        uint256 mintValue;
        // The root of the merkle tree
        bytes32 rootHash;
        // The amount of tokens an address can mint
        bool hasCap;
        mapping(address => uint256) capTracker;
    }
    // whitelist id => whitelist
    mapping (uint256 => WhiteList) public whiteLists;
    uint256 public openWhiteListId;

    bool public isMintOpen;
    uint256 public openMintValue;



    // Token
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    uint256 public maxSupply;
    address public feeReceiver;


    string public _provenanceHash;
    string public _baseURL;


    function initialize() initializer public {
        __Ownable_init();
        __ERC721_init("NFTVenues Hole", "NVH");
        __DefaultOperatorFilterer_init();
        __ERC721Burnable_init();
        maxSupply = 6666;
        openMintValue = 250000000000000000;
        openWhiteListId = 0;
        isMintOpen = false;
    }

    function _baseMint(uint256 count, address recipient, uint256 mintValue) private {
        require(_tokenIds.current() + count <= maxSupply, "Can not mint more than max supply.");
        require(msg.value >= count * mintValue, "Insufficient payment");

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }

        bool success = false;
        (success,) = feeReceiver.call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function airdrop(address receiver, uint256 amount) external onlyOwner {
        _baseMint(amount, receiver, 0);
    }

    function batchAirdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length == amounts.length);
        for(uint i = 0; i < receivers.length; i++) {
            _baseMint(amounts[i], receivers[i], 0);
        }
    }

    function mint(uint256 amount) external payable {
        require(isMintOpen, "Mint is not active.");
        require(amount > 0, "You have to mint 1 or more tokens.");
        _baseMint(amount, msg.sender, openMintValue);
    }

    function whiteListMint(uint256 amount, bytes32[] calldata proof) external payable {
        WhiteList storage whiteList = whiteLists[openWhiteListId];
        require(whiteList.rootHash != bytes32(0), "Whitelist phase is not active.");
        require(amount > 0, "You have to mint 1 or more tokens.");
        if(whiteList.hasCap) {
            require(
                amount <= whiteList.capTracker[msg.sender],
                "You are exceeded the amount of tokens you can mint for this white list"
            );
            whiteList.capTracker[msg.sender] -= amount;
        }
        require(_verify(_leaf(msg.sender), proof, whiteList.rootHash), "Address not in white list.");
        _baseMint(amount, msg.sender, whiteList.mintValue);
    }

    // Merkle utils
    function _leaf(address recipient)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(recipient));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 rootHash)
    internal pure returns (bool)
    {
        return MerkleProofUpgradeable.verify(proof, rootHash, leaf);
    }

    // Setters
    function addWhiteList(uint256 whiteListId, uint256 mintValue, bytes32 rootHash) public onlyOwner {
        require(whiteListId != 0, "whiteListId must be greater than 0");
        WhiteList storage whiteList = whiteLists[whiteListId];
        whiteList.mintValue = mintValue;
        whiteList.rootHash = rootHash;
        whiteList.hasCap = false;
    }

    function addWhiteListCapTracker(uint256 whiteListId, address[] calldata addresses, uint256[] calldata caps) public onlyOwner {
        require(whiteListId != 0, "whiteListId must be greater than 0");
        require(addresses.length == caps.length, "Caps length should be the same as addresses length");
        WhiteList storage whiteList = whiteLists[whiteListId];
        whiteList.hasCap = true;
        for(uint i; i < addresses.length; i++) {
            whiteList.capTracker[addresses[i]] = caps[i];
        }
    }

    function flipMintState() public onlyOwner {
        isMintOpen = !isMintOpen;
    }

    function startWhitelist(uint8 whiteListId) public onlyOwner {
        openWhiteListId = whiteListId;
    }

    function startMinting() public onlyOwner {
        openWhiteListId = 0;
        isMintOpen = true;
    }

    function setOpenMintValue(uint256 newMintValue) public onlyOwner {
        openMintValue = newMintValue;
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        feeReceiver = newFeeReceiver;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;
    }

    function setBaseURL(string memory newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    // Getters
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function whiteListCapTracker(uint8 whiteListId, address wallet) public view returns (uint256) {
        return whiteLists[whiteListId].capTracker[wallet];
    }

    function getWhiteList(uint8 whiteListId) public view returns (uint256, bytes32, bool) {
        WhiteList storage whiteList = whiteLists[whiteListId];
        return (whiteList.mintValue, whiteList.rootHash, whiteList.hasCap);
    }

    function getOpenWhiteList() public view returns (uint256, uint256, bytes32, bool) {
        WhiteList storage whiteList = whiteLists[openWhiteListId];
        return (openWhiteListId, whiteList.mintValue, whiteList.rootHash, whiteList.hasCap);
    }

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

