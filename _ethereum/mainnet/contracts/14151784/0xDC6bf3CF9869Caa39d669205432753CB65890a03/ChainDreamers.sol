// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./BytesLib.sol";
import "./IDreamersRenderer.sol";
import "./ICandyShop.sol";
import "./IChainRunners.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ChainDreamers is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Linked contracts
    address public renderingContractAddress;
    address public candyShopAddress;
    address public chainRunnersAddress;
    IDreamersRenderer renderer;
    ICandyShop candyShop;
    IChainRunners chainRunners;

    uint8[10_000] public dreamersCandies;
    uint8 private constant candyMask = 252; // "11111100" binary string, last 2 bits kept for candyId
    /// @dev Copied from \@naomsa's contract
    /// @notice OpenSea proxy registry.
    address public opensea;
    /// @notice LooksRare marketplace transfer manager.
    address public looksrare;
    /// @notice Check if marketplaces pre-approve is enabled.
    bool public marketplacesApproved = true;

    mapping(address => bool) proxyToApproved;

    /// @notice Set opensea to `opensea_`.
    function setOpensea(address opensea_) external onlyOwner {
        opensea = opensea_;
    }

    /// @notice Set looksrare to `looksrare_`.
    function setLooksrare(address looksrare_) external onlyOwner {
        looksrare = looksrare_;
    }

    /// @notice Toggle pre-approve feature state for sender.
    function toggleMarketplacesApproved() external onlyOwner {
        marketplacesApproved = !marketplacesApproved;
    }

    /// @notice Approve the communication and interaction with cross-collection interactions.
    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    /// @dev Modified for opensea and looksrare pre-approve so users can make truly gas less sales.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (!marketplacesApproved)
            return super.isApprovedForAll(owner, operator);

        return
            operator == address(ProxyRegistry(opensea).proxies(owner)) ||
            operator == looksrare ||
            proxyToApproved[operator] ||
            super.isApprovedForAll(owner, operator);
    }

    // Constants
    uint256 public maxDreamersMintPublicSale;
    uint256 public constant MINT_PUBLIC_PRICE = 0.05 ether;
    uint256 public constant MAX_MINT_FOUNDERS = 50;
    bool public foundersMinted = true;

    // State variables
    uint256 public publicSaleStartTimestamp;

    function setPublicSaleTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp > publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = IDreamersRenderer(renderingContractAddress);
    }

    function setCandyShopAddress(address _candyShopContractAddress)
        public
        onlyOwner
    {
        candyShopAddress = _candyShopContractAddress;
        candyShop = ICandyShop(candyShopAddress);
    }

    function setMaxDreamersMintPublicSale(uint256 _maxDreamersMintPublicSale)
        public
        onlyOwner
    {
        maxDreamersMintPublicSale = _maxDreamersMintPublicSale;
    }

    function setChainRunnersContractAddress(
        address _chainRunnersContractAddress
    ) public onlyOwner {
        chainRunnersAddress = _chainRunnersContractAddress;
        chainRunners = IChainRunners(_chainRunnersContractAddress);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _rendererAddress,
        address _chainRunnersAddress,
        address _opensea,
        address _looksrare,
        uint256 _maxDreamersMintPublicSale
    ) ERC721(name_, symbol_) {
        setRenderingContractAddress(_rendererAddress);
        setChainRunnersContractAddress(_chainRunnersAddress);
        opensea = _opensea;
        looksrare = _looksrare;
        setMaxDreamersMintPublicSale(_maxDreamersMintPublicSale);
    }

    function setOgs(
        address[] memory _ogs,
        uint256[] memory _tokenIds,
        uint8[] memory _candies
    ) external onlyOwner {
        for (uint256 i = 0; i < _ogs.length; i++) {
            _safeMint(_ogs[i], _tokenIds[i]);
            dreamersCandies[_tokenIds[i]] = _candies[i];
        }
    }

    /// @dev This mint function wraps the safeMintBatch to:
    ///      1) check that the minter owns the runner 2) use the candies 3) burn the candies
    /// @param tokenIds a bytes interpreted as an array of uint16
    /// @param candyIds the same indexes as above but as a uint8 array
    /// @param candyAmounts should be an array of 1
    function mintBatchRunnersAccess(
        bytes calldata tokenIds,
        uint256[] calldata candyIds,
        uint256[] calldata candyAmounts
    ) public nonReentrant returns (bool) {
        require(
            tokenIds.length == candyIds.length * 2,
            "Each runner needs one and only one candy"
        );

        bytes32 candies = keccak256(
            abi.encodePacked(
                tokenIds,
                msg.sender,
                candyIds,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < candyIds.length; i++) {
            uint16 tokenId = BytesLib.toUint16(tokenIds, i * 2);
            // ownerOf uses a simple mapping in OZ's ERC721 so should be cheap
            require(
                chainRunners.ownerOf(tokenId) == _msgSender(),
                "You cannot give candies to a runner that you do not own"
            );
            require(
                candyAmounts[i] == 1,
                "Your runner needs one and only one candy, who knows what could happen otherwise"
            );
            dreamersCandies[tokenId] =
                (uint8(candies[i % 32]) & candyMask) +
                (uint8(candyIds[i]) % 4);

            _safeMint(_msgSender(), tokenId);
            if (i % 32 == 31) {
                candies = keccak256(abi.encodePacked(candies));
            }
        }

        candyShop.burnBatch(_msgSender(), candyIds, candyAmounts);
        return true;
    }

    function mintBatchPublicSale(bytes calldata tokenIds)
        public
        payable
        nonReentrant
        whenPublicSaleActive
        returns (bool)
    {
        require(
            (tokenIds.length / 2) * MINT_PUBLIC_PRICE == msg.value,
            "You have to pay the bail bond"
        );
        require(
            ERC721.balanceOf(_msgSender()) + tokenIds.length / 2 <=
                maxDreamersMintPublicSale,
            "Your home is to small to welcome so many dreamers"
        );

        bytes32 candies = keccak256(
            abi.encodePacked(
                tokenIds,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < tokenIds.length; i += 2) {
            uint16 tokenId = BytesLib.toUint16(tokenIds, i);
            dreamersCandies[tokenId] = uint8(candies[i / 2]);
            _safeMint(_msgSender(), tokenId);
        }

        return true;
    }

    function mintBatchFounders(bytes calldata tokenIds)
        public
        nonReentrant
        onlyOwner
        whenPublicSaleActive
        returns (bool)
    {
        require(!foundersMinted, "Don't be too greedy");
        require(
            tokenIds.length <= MAX_MINT_FOUNDERS * 2,
            "Even if you are a founder, you don't deserve that many Dreamers"
        );

        bytes32 candies = keccak256(
            abi.encodePacked(
                tokenIds,
                msg.sender,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < tokenIds.length / 2; i++) {
            uint16 tokenId = BytesLib.toUint16(tokenIds, i * 2);
            dreamersCandies[tokenId] = uint8(candies[i % 32]);
            _safeMint(_msgSender(), tokenId);
            if (i % 32 == 31) {
                candies = keccak256(abi.encodePacked(candies));
            }
        }
        foundersMinted = true;
        return true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return "";
        }

        return renderer.tokenURI(_tokenId, dreamersCandies[_tokenId]);
    }

    function getDreamersCandies() public view returns (uint8[10_000] memory) {
        return dreamersCandies;
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
