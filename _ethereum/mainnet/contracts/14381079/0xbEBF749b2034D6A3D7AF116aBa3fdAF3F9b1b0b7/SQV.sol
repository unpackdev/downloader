// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/// @custom:security-contact support@spacequantum.io
contract SpaceQuantumVision is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    uint256 private MAX_QTY_SALES = 100000;
    struct Usage {
        bool created;
        bool used;
        bool exported;
    }
    mapping(uint256 => Usage) public tokensUsage;

    address public SQIContractAddr;

    address private usageEditor;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool public _publicMintActive = false;

    event NewSQVMinted(address from, address sender, uint256 tokenId);

    string baseURI =
        "ipfs://QmUtk2pK4auYaEU6RugM9frQBWL3jiRG1jmu2xtANUUXa1/meta_sqv.json";

    constructor() ERC721("SpaceQuantumVision", "SQV") {
        usageEditor = msg.sender;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function availableSales() public view returns (uint256) {
        uint256 available = 0;
        available = SafeMath.sub(MAX_QTY_SALES, totalSupply());

        return available;
    }

    function setInitialUsage(uint256 _tokenId) private {
        Usage memory initialData = Usage({
            created: true,
            used: false,
            exported: false
        });
        tokensUsage[_tokenId] = initialData;
    }

    function setTokenIsUsed(uint256 _tokenId) external {
        require(msg.sender == address(usageEditor), "Is not token editor");
        tokensUsage[_tokenId].used = true;
    }

    function setTokenIsExported(uint256 _tokenId) external {
        require(msg.sender == address(usageEditor), "Is not token editor");
        tokensUsage[_tokenId].exported = true;
    }

    function safeMint(address to) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI))
                : "";
    }

    function dropMint(address _recipient) external whenNotPaused nonReentrant {
        require(_publicMintActive == true, "Inactive method");

        require(SQIContractAddr != address(0), "SQC address not configured");

        require(
            msg.sender == address(SQIContractAddr),
            "Only SQC contract allowed"
        );

        require(availableSales() > 0, "Not enough sales available");

        uint256 tokenId = safeMint(_recipient);

        setInitialUsage(tokenId);

        emit NewSQVMinted(address(this), _recipient, tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSQIContractAddr(address _addr) external onlyOwner {
        SQIContractAddr = _addr;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function activatePublicMint() external onlyOwner {
        _publicMintActive = true;
    }

    function deactivatePublicMint() external onlyOwner {
        _publicMintActive = false;
    }

    function setUsageEditor(address _editorAddr) external onlyOwner {
        usageEditor = _editorAddr;
    }
}
