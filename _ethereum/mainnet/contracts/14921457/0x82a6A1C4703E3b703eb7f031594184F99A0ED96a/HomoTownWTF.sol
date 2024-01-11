// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract HomoTownWTF is ERC721A, Ownable {
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri = "ipfs://Qmeh9aoZ5gjb4Us5VamaiLqNzB3rqxnunpyi71516CdBfz/";
    string public contractMetadataUri = "ipfs://Qmahh77H464KGpJLSknf93wEwgz7qTPmAHJRdFT8xTziwG/";

    uint256 public freeMints = 1000;
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 10_000;
    uint256 public maxMintAmountPerTx = 30;

    bool public paused = false;
    bool public revealed = false;
    bool public uriLocked = false;

    constructor() ERC721A("homotown.wtf", "HOMO") {}

    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        require(!paused, "The contract is paused");

        if (_totalMinted() >= freeMints) {
            require(msg.value >= cost * quantity, "Insufficient funds");
        }

        _mint(msg.sender, quantity);
    }

    function contractURI() external view returns (string memory) {
        return contractMetadataUri;
    }

    /// URI format: `<baseURI>tokens/<token ID><uriSuffix>`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, "tokens/", Strings.toString(tokenId), uriSuffix)
                )
                : "";
    }

    function setRevealed(bool _state) external onlyOwner {
        require(!uriLocked, "URIs locked");
        revealed = _state;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setFreeMints(uint256 _freeMints) external onlyOwner {
        freeMints = _freeMints;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        require(!uriLocked, "URIs locked");
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setContractMetadataUri(string memory _contractMetadataUri) external onlyOwner {
        require(!uriLocked, "URIs locked");
        contractMetadataUri = _contractMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function lockedUris() external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriLocked = true;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
}
