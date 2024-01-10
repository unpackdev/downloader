//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GadjahSociety is ERC721A, Ownable {
    using Strings for uint256;

    string public notRevealedURI;
    string public baseURI = "";
    string public baseExtension = ".json";
    uint256 public cost = 0.06 ether;
    uint256 public presaleCost = 0.04 ether;
    uint256 public maxSupply = 4828;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public presaleMintLimit = 5;
    uint256 public nftPerAddressLimit = 5;
    bytes32 public merkleRoot =
        0x43781a8b5146419880cdf177f8f43e70523666abc838b2434587d1d0219fac60;
    bool public paused = false;
    bool public revealed = false;
    mapping(address => uint256) public addressMintPresaleCount;
    mapping(address => NftSet) userNftIds;

    struct Period {
        uint32 presalesStartTime; // Start time for the current rewardsToken schedule
        uint32 presalesEndTime; // End time for the current rewardsToken schedule
    }

    // To store user's nft ids, it is more convenient to know if nft id of user exists
    struct NftSet {
        // user's nft id array
        uint256[] ids;
        // nft id -> bool, if nft id exist
        mapping(uint256 => bool) isIn;
        // user's nft timesPurchased
        uint256[] timesPurchased;
    }

    Period public period;

    constructor() ERC721A("Gadjah Society Testnet", "GDJHT", 5) {
        setNotRevealedURI(
            "ipfs://QmWj1cuT4mqwPMC5P5CYk51nzWuDEUyA5huEeWA9m4dtfg/"
        );
        setPeriods(1645020000, 1645106400);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            (_mintAmount > 0) && (_mintAmount <= maxMintAmountPerTx),
            "Invalid mint amount! Max mint amount per transaction exceeded"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier saleStarted() {
        require(isOnPublicSales(), "Sale has not started yet");
        _;
    }

    modifier notPaused() {
        require(!paused, "the contract is paused");
        _;
    }

    modifier PresaleStarted() {
        require(isOnPresales(), "Presale has not started yet");
        _;
    }

    // Public function //

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        notPaused
        saleStarted
    {
        uint256 ownerTokenCount = balanceOf(msg.sender);
        require(
            ownerTokenCount + _mintAmount <= nftPerAddressLimit,
            "Max NFT per Wallet exceeded"
        );
        require(msg.value >= cost * _mintAmount, "Insufficient funds");

        for (uint256 i = 0; i < _mintAmount; i++) {
            setUserNftIds(_msgSender(), totalSupply(), block.timestamp);
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintPresale(uint256 _mintAmount, bytes32[] calldata merkleProof)
        external
        payable
        mintCompliance(_mintAmount)
        notPaused
        PresaleStarted
    {
        uint256 ownerMintCount = addressMintPresaleCount[msg.sender];
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not eligible for the presale"
        );
        require(
            ownerMintCount + _mintAmount <= presaleMintLimit,
            "Presale limit for this wallet reached"
        );
        require(msg.value >= presaleCost * _mintAmount, "ETH amount is low");
        for (uint256 i = 0; i < _mintAmount; i++) {
            addressMintPresaleCount[msg.sender]++;
            setUserNftIds(_msgSender(), totalSupply(), block.timestamp);
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * Set user's nft id.
     *
     * Note: when nft id donot exist, the nft id will be added to ids array, and the idIn flag will be setted true;
     * otherwise do nothing.
     *
     * @param user The address of user.
     * @param nftId The nft id of user.
     */
    function setUserNftIds(
        address user,
        uint256 nftId,
        uint256 _time
    ) internal {
        NftSet storage nftSet = userNftIds[user];
        uint256[] storage ids = nftSet.ids;
        uint256[] storage times = nftSet.timesPurchased;
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        if (!isIn[nftId]) {
            ids.push(nftId);
            times.push(_time);
            isIn[nftId] = true;
        }
    }

    /**
     * Remove nft id of user.
     *
     * Note: when user's nft id amount=0, remove it from nft ids array, and set flag=false
     */
    function removeUserNftId(uint256 nftId) internal {
        NftSet storage nftSet = userNftIds[msg.sender];
        uint256[] storage ids = nftSet.ids;
        uint256[] storage times = nftSet.timesPurchased;
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        require(ids.length > 0, "remove user nft ids, ids length must > 0");
        // find nftId index
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == nftId) {
                ids[i] = ids[ids.length - 1];
                times[i] = times[times.length - 1];
                isIn[nftId] = false;
                ids.pop();
                times.pop();
            }
        }
    }

    /**
     * Get user's nft ids array.
     * @param user The address of user.
     */
    function getUserNftIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return userNftIds[user].ids;
    }

    function getUserNftTimes(address user)
        public
        view
        returns (uint256[] memory)
    {
        return userNftIds[user].timesPurchased;
    }

    /// @dev Set a rewards schedule
    function setPeriods(uint32 start, uint32 end) public onlyOwner {
        require(start <= end, "Incorrect input");
        // A new rewards program can be set if one is not running
        require(
            uint32(block.timestamp) < period.presalesStartTime ||
                uint32(block.timestamp) > period.presalesEndTime,
            "Ongoing Presale"
        );

        period.presalesStartTime = start;
        period.presalesEndTime = end;
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

        // Check if nft is not already revealed
        if (!revealed) {
            // If not yet, return not revealed uri
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getCurrentCost() public view returns (uint256) {
        if (isOnPresales()) {
            return presaleCost;
        } else {
            return cost;
        }
    }

    function isOnPresales() public view returns (bool) {
        return
            uint32(block.timestamp) >= period.presalesStartTime &&
            uint32(block.timestamp) <= period.presalesEndTime;
    }

    // Public sale is started when presales ends
    function isOnPublicSales() public view returns (bool) {
        return uint32(block.timestamp) >= period.presalesEndTime;
    }

    // Only owner //

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        // In wei not ether
        cost = _cost;
    }

    function setPresaleCost(uint256 _presaleCost) public onlyOwner {
        presaleCost = _presaleCost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPresaleMintLimit(uint256 _presaleMintLimit) public onlyOwner {
        presaleMintLimit = _presaleMintLimit;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() public onlyOwner {
        // Put remain balance to owner address
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // Internal //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
