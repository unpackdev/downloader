// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract CryptoPomelClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;
    bool private shareHoldersSelected = false;

    address[] private _whitelistMinters;
    mapping(address => bool) isMinted;
    mapping(address => bool) isShareHolder;
    uint256 private ShareHolderCount = 0;

    struct shareHolderStruct {
        address walletAddress;
        uint256 revenue;
    }

    mapping(uint256 => shareHolderStruct) private shareHolders;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        mintForGiveaways(503, 0x723d6df4831bbC649a7724cc7BB7B883136138e9);
    }

    function selectShareHolders() public onlyOwner {
        require(
            shareHoldersSelected == false,
            "Share holders already selected"
        );
        uint256 maxShareHolders = 20;
        uint256 whitelistMintCount = getWhitelistCount();
        uint256 counter = 0;
        uint256[] memory selectedShareHolders = new uint256[](maxShareHolders);
        address[] memory shareHolderAddress = new address[](maxShareHolders);
        address[] memory whitelistMinters_ = _whitelistMinters;

        for (uint256 i = 0; i < whitelistMintCount; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (whitelistMintCount - i));
            address temp = whitelistMinters_[n];
            whitelistMinters_[n] = whitelistMinters_[i];
            whitelistMinters_[i] = temp;
        }

        do {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((uint256(keccak256(abi.encodePacked(counter)))) /
                                (block.timestamp)) +
                            block.number
                    )
                )
            );
            selectedShareHolders[counter] =
                seed -
                ((seed / whitelistMintCount) * whitelistMintCount);
            shareHolderAddress[counter] = whitelistMinters_[counter];
            addShareHolder(whitelistMinters_[counter], 0);
            isShareHolder[whitelistMinters_[counter]] = true;
            counter++;
        } while (counter < maxShareHolders);

        shareHoldersSelected = true;
    }

    function addShareHolder(address _wallet, uint256 _revenue) private {
        shareHolders[ShareHolderCount] = shareHolderStruct(_wallet, _revenue);
        ShareHolderCount++;
    }

    function getShareHolders() public view returns (address[] memory) {
        address[] memory walletAddress = new address[](ShareHolderCount);
        uint256[] memory revenue = new uint256[](ShareHolderCount);
        for (uint256 i = 0; i < ShareHolderCount; i++) {
            shareHolderStruct storage shareHolder = shareHolders[i];
            walletAddress[i] = shareHolder.walletAddress;
            revenue[i] = shareHolder.revenue;
        }
        return (walletAddress);
    }

    function getShareRevenue() public view returns (uint256[] memory) {
        require(
            isShareHolder[_msgSender()] == true,
            "This address is not a share holder"
        );
        uint256[] memory revenue = new uint256[](1);
        for (uint256 i = 0; i < ShareHolderCount; i++) {
            shareHolderStruct storage shareHolder = shareHolders[i];
            if (shareHolder.walletAddress == _msgSender()) {
                revenue[0] = shareHolder.revenue;
            }
        }
        return (revenue);
    }

    function getWhiteListMinters() public view returns (address[] memory) {
        return _whitelistMinters;
    }

    function getWhitelistCount() public view returns (uint256) {
        return _whitelistMinters.length;
    }

    function setWhiteListMinter(address account) private {
        if (isMinted[account] == false) {
            _whitelistMinters.push(account);
            isMinted[account] = true;
        }
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
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        setWhiteListMinter(_msgSender());
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
        if (whitelistMintEnabled == false) {
            for (uint256 i = 0; i < ShareHolderCount; i++) {
                shareHolders[i].revenue =
                    (((shareHolders[i].revenue + cost * _mintAmount) / 100) *
                        6) /
                    20;
                (bool os, ) = payable(shareHolders[i].walletAddress).call{
                    value: (((cost * _mintAmount) / 100) * 6) / 20
                }("");
                require(os);
            }
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function mintForGiveaways(uint256 _mintAmount, address _receiver)
        private
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
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
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

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
        uint256 amount = address(this).balance / 3;
        (bool os, ) = payable(0x9648d056cEA385D1670356697F298F8A684b5E24).call{
            value: amount
        }("");
        require(os);
        (bool os_, ) = payable(0x22Bd3EEa76392d413f9e2f9a0ecbC0C84d925830).call{
            value: amount
        }("");
        require(os_);
        (bool os__, ) = payable(0x5dcB20Cca1A4805344090cc446C35E2E4F17b932)
            .call{value: amount}("");
        require(os__);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
