// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract SuperBountyInc is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }

    ContractMintState public state = ContractMintState.PAUSED;

    string public uriPrefix = "";
    string public hiddenMetadataUri = "ipfs://Qmasib9ZVGBFPpg8NfNtMewyLGXNBCMyub2uGRE3nq73r5";

    uint256 public allowlistCost = 0.01 ether;
    uint256 public publicCost = 0.02 ether;
    uint256 public maxSupply = 4000;
    uint256 public maxMintAmountPerTx = 4;

    bytes32 public whitelistMerkleRoot = 0xb451498d18874dfe37f9b15fcf66f460007751dc1ab0e495d235001830316d88;

    constructor() ERC721A("SuperBountyInc.", "SUPER") {}

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MODIFIERS
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }

    // MERKLE TREE
    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function _leaf(address account, uint256 allowance)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allowance));
    }

    // MINTING FUNCTIONS
    function mint(uint256 amount) public payable mintCompliance(amount) {
        require(amount <= maxMintAmountPerTx, "Invalid mint amount");
        require(state == ContractMintState.PUBLIC, "Public mint is disabled");
        require(msg.value >= publicCost * amount, "Insufficient funds");

        _safeMint(msg.sender, amount);
    }

    function mintAllowList(
        uint256 amount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable mintCompliance(amount) {
        require(
            state == ContractMintState.ALLOWLIST,
            "Allowlist mint is disabled"
        );
        require(msg.value >= allowlistCost * amount, "Insufficient funds");
        require(
            numberMinted(msg.sender) + amount <= allowance,
            "Can't mint that many"
        );
        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid proof");

        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver)
        public
        onlyOwner
    {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

    // GETTERS
    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
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

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : hiddenMetadataUri;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;
        for (
            uint256 tokenIdx = _startTokenId();
            tokenIdx <= totalSupply();
            tokenIdx++
        ) {
            if (ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }

    // SETTERS
    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
    }

    function setCosts(uint256 _allowlistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        allowlistCost = _allowlistCost;
        publicCost = _publicCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
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

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // WITHDRAW
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;

        (success, ) = payable(0xBB06828F9dB6eb3C359938c33E763E17C4d8a817).call{
            value: (28125 * contractBalance) / 100000
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0xcAfbc52f8b3D2BDE9a2a2C37f0ABa2c719D4CFB4).call{
            value: (28125 * contractBalance) / 100000
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0xaf6B8B69fcD83E4Fa7DdE77ed9c9af7E8e177CC2).call{
            value: (31250 * contractBalance) / 100000
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0x44230C74E406d5690333ba81b198441bCF02CEc8).call{
            value: (6250 * contractBalance) / 100000
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0xFA9A358b821f4b4A1B5ac2E0c594bB3f860AFbd8).call{
            value: (6250 * contractBalance) / 100000
        }("");
        require(success, "Transfer failed");
    }
}
