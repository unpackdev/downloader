// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Goburin is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    address public proxyRegistryAddress;

    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet;

    uint256 public constant RESERVES = 111;

    bool public paused = true;
    bool public revealed = false;
    bool public reservesCollected = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountPerWallet,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            _numberMinted(msg.sender) + _mintAmount <= maxMintAmountPerWallet,
            "Wallet limit reached!"
        );
        _;
    }

    function mint(uint256 _mintAmount)
        public
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function collectReserves() external onlyOwner {
        require(!reservesCollected, "Reserves already taken.");
        _safeMint(_msgSender(), RESERVES);
        reservesCollected = true;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _nextTokenId()
        ) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        public
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
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

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to withdraw balance.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
