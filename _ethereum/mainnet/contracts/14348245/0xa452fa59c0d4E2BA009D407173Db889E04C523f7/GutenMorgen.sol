// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract GutenMorgen is ERC721, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public hiddenMetadataUri = "ipfs://QmZugvh3gxTTBrXEAEnMt3jWCYUD74R14kiutP1VQGXBj8/hidden.json";
    bool public useHiddenMetadataUri = true;

    uint256 public constant maxSupply = 6666;

    uint256 public cost = 0.4 ether;
    uint256 public whitelistCost = 0.1 ether;

    uint256 public maxMintAmountPerWallet = 5;

    bool public paused = false;
    bool public whitelistMintEnabled = true;
    bool public revealed = false;

    address public creator;

    address public donateAddress = 0xa1b1bbB8070Df2450810b8eB2425D543cfCeF79b;
    uint256 public constant donateShare = 50;

    constructor() ERC721("GutenMorgen", "MORGEN") {
        creator = owner();
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerWallet, "Invalid mint amount!");
        require(balanceOf(_msgSender()) + _mintAmount <= maxMintAmountPerWallet, "Mint amount count limit!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _cost) {
        require(msg.value >= _cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount, whitelistCost) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

        whitelistClaimed[msg.sender] += _mintAmount;

        _mintWithdraw();

        _mintLoop(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount, cost) {
        require(!paused, "The contract is paused!");

        _mintWithdraw();

        _mintLoop(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _mintLoop(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false && useHiddenMetadataUri == true) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUseHiddenMetadataUri(bool _state) public onlyOwner {
        useHiddenMetadataUri = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelistCost = _cost;
    }

    function setCreator(address _address) public onlyOwner {
        creator = _address;
    }

    function setDonateAddress(address _address) public onlyOwner {
        donateAddress = _address;
    }

    function withoutDonate() public onlyOwner {
        donateAddress = address(0);
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(creator).transfer(address(this).balance);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _mintWithdraw() internal {
        uint256 balance = msg.value;

        if (address(0) != donateAddress) {
            uint256 amountForDonate = balance * donateShare / 100;
            uint256 amountForCreator = balance - amountForDonate;

            (bool creatorSuccess,) = payable(creator).call{value : amountForCreator}("");
            require(creatorSuccess, "Failed to withdraw payment for creator");

            (bool partnerSuccess,) = payable(donateAddress).call{value : amountForDonate}("");
            require(partnerSuccess, "Failed to withdraw payment for donate");
        } else {
            (bool success,) = payable(creator).call{value : balance}("");
            require(success, "Failed to withdraw payment");
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefixAndReveal(string memory _uriPrefix) public onlyOwner {
        setUriPrefix(_uriPrefix);
        setRevealed(true);
    }
}
