// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./IBlitoadzRenderer.sol";
import "./IBlitmap.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

error PublicSaleOpen();
error PublicSaleNotOpen();
error BlitoadzExists();
error ToadzIndexOutOfBounds();
error BlitmapIndexOutOfBounds();
error NothingToWithdraw();
error WithdrawalFailed();
error ToadzAndBlitmapLengthMismatch();
error IncorrectPrice();
error AllocationExceeded();
error BlitoadzDoesNotExist();

contract Blitoadz is ERC721A, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MINT_PUBLIC_PRICE = 0.056 ether;
    uint8 public constant TOADZ_COUNT = 56;
    uint8 public constant BLITMAP_COUNT = 100;
    uint16 public constant BLITOADZ_COUNT = 5_600;
    IBlitmap public blitmap;

    // Blitoadz states variables
    bool[BLITOADZ_COUNT] public blitoadzExist;
    uint8[] public toadzIds;
    uint8[] public blitmapIds;
    uint8[] public palettes;

    // Blitoadz funds split
    uint256 public blitmapCreatorShares;
    mapping(address => Founder) public founders;
    mapping(address => uint16) creatorAvailableAmount;
    uint256 receivedAmount;

    struct Founder {
        uint128 withdrawnAmount;
        uint16 shares;
        uint8 remainingAllocation;
    }

    // Events
    event PublicSaleOpened(uint256 timestamp);
    event RendererChanged(address newRenderer);
    event BlitmapCreatorWithdrawn(address account, uint256 amount);
    event FounderWithdrawn(address account, uint256 amount);

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Schedule ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    uint256 public publicSaleStartTimestamp;

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp > publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    modifier whenPublicSaleOpen() {
        if (!isPublicSaleOpen()) revert PublicSaleNotOpen();
        _;
    }

    modifier whenPublicSaleClosed() {
        if (isPublicSaleOpen()) revert PublicSaleNotOpen();
        _;
    }

    function openPublicSale() external onlyOwner whenPublicSaleClosed {
        publicSaleStartTimestamp = block.timestamp;
        emit PublicSaleOpened(publicSaleStartTimestamp);
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Token ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    address public renderingContractAddress;
    IBlitoadzRenderer renderer;

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = IBlitoadzRenderer(renderingContractAddress);
        emit RendererChanged(renderingContractAddress);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _rendererAddress,
        address[] memory _founders,
        Founder[] memory _foundersData,
        uint256 _blitmapCreatorShares,
        address _blitmap
    ) ERC721A(name_, symbol_) {
        setRenderingContractAddress(_rendererAddress);

        for (uint256 i = 0; i < _founders.length; i++) {
            founders[_founders[i]] = _foundersData[i];
        }

        blitmapCreatorShares = _blitmapCreatorShares;
        blitmap = IBlitmap(_blitmap);
    }

    /// @notice Free mint for addresses with an allocation. Lengths should match; at a given index the combination
    ///         toadzId, blitmapId and paletteOrder will be used to define the given blitoadz
    /// @param _toadzIds the list of toadzIds to use, 0 based indexes. On etherscan, this could be e.g. 12,53,1
    /// @param _blitmapIds the list of blitmapIds to use, 0 based indexes. On etherscan, this could be e.g. 99,23,87
    /// @param _paletteOrders the order of the mapping for the blitmap color palette. This uint8 is parsed as 4 uint2
    ///        and there are consequently only 24 relevant values, any permutation of 0, 1,  2, 3
    /// @param isBlitoadzPayable should this blitoadz be counted for founders and creator claims
    function _mint(
        address to,
        uint256[] calldata _toadzIds,
        uint256[] calldata _blitmapIds,
        uint256[] calldata _paletteOrders,
        bool isBlitoadzPayable
    ) internal {
        for (uint256 i = 0; i < _toadzIds.length; i++) {
            uint256 toadzId = _toadzIds[i];
            uint256 blitmapId = _blitmapIds[i];
            if (blitoadzExist[toadzId * BLITMAP_COUNT + blitmapId])
                revert BlitoadzExists();
            if (toadzId > TOADZ_COUNT - 1) revert ToadzIndexOutOfBounds();
            if (blitmapId > BLITMAP_COUNT - 1) revert BlitmapIndexOutOfBounds();
            toadzIds.push(uint8(toadzId % type(uint8).max));
            blitmapIds.push(uint8(blitmapId % type(uint8).max));
            palettes.push(uint8(_paletteOrders[i] % type(uint8).max));
            blitoadzExist[toadzId * BLITMAP_COUNT + blitmapId] = true;
            if (isBlitoadzPayable)
                creatorAvailableAmount[blitmap.tokenCreatorOf(blitmapId)]++;
        }

        _safeMint(to, _toadzIds.length);
    }

    /// @notice Free mint for addresses with an allocation. Lengths should match; at a given index the combination
    ///         toadzId, blitmapId and paletteOrder will be used to define the given blitoadz
    /// @param _toadzIds the list of toadzIds to use, 0 based indexes. On etherscan, this could be e.g. 12,53,1
    /// @param _blitmapIds the list of blitmapIds to use, 0 based indexes. On etherscan, this could be e.g. 99,23,87
    /// @param _paletteOrders the order of the mapping for the blitmap color palette. This uint8 is parsed as 4 uint2
    ///        and there are consequently only 24 relevant values, any permutation of 0, 1,  2, 3
    function mintPublicSale(
        uint256[] calldata _toadzIds,
        uint256[] calldata _blitmapIds,
        uint256[] calldata _paletteOrders
    ) external payable whenPublicSaleOpen nonReentrant {
        if (_toadzIds.length != _blitmapIds.length)
            revert ToadzAndBlitmapLengthMismatch();
        if (msg.value != MINT_PUBLIC_PRICE * _toadzIds.length)
            revert IncorrectPrice();

        _mint(_msgSender(), _toadzIds, _blitmapIds, _paletteOrders, true);
        receivedAmount += MINT_PUBLIC_PRICE * _toadzIds.length;
    }

    /// @notice Free mint for addresses with an allocation. Lengths should match; at a given index the combination
    ///         toadzId, blitmapId and paletteOrder will be used to define the given blitoadz
    /// @param _toadzIds the list of toadzIds to use, 0 based indexes. On etherscan, this could be e.g. 12,53,1
    /// @param _blitmapIds the list of blitmapIds to use, 0 based indexes. On etherscan, this could be e.g. 99,23,87
    /// @param _paletteOrders the order of the mapping for the blitmap color palette. This uint8 is parsed as 4 uint2
    ///        and there are consequently only 24 relevant values, any permutation of 0, 1,  2, 3
    function mintAllocation(
        uint256[] calldata _toadzIds,
        uint256[] calldata _blitmapIds,
        uint256[] calldata _paletteOrders
    ) external nonReentrant {
        if (_toadzIds.length != _blitmapIds.length)
            revert ToadzAndBlitmapLengthMismatch();
        if (founders[_msgSender()].remainingAllocation < _toadzIds.length)
            revert AllocationExceeded();
        founders[_msgSender()].remainingAllocation -= uint8(
            _toadzIds.length % type(uint8).max
        );
        _mint(_msgSender(), _toadzIds, _blitmapIds, _paletteOrders, false);
    }

    /// @notice Withdraw available funds for blitmap creator
    function withdrawBlitmapCreator() external nonReentrant returns (bool) {
        if (creatorAvailableAmount[_msgSender()] == 0)
            revert NothingToWithdraw();
        uint256 value = (MINT_PUBLIC_PRICE *
            creatorAvailableAmount[_msgSender()] *
            blitmapCreatorShares) / BLITOADZ_COUNT;
        (bool success, ) = _msgSender().call{value: value}("");
        if (!success) revert WithdrawalFailed();
        emit BlitmapCreatorWithdrawn(_msgSender(), value);
        creatorAvailableAmount[_msgSender()] = 0;
        return success;
    }

    /// @notice Withdraw available funds for blitoadz and toadz creators
    function withdrawFounder() external nonReentrant returns (bool) {
        uint256 value = (receivedAmount * founders[_msgSender()].shares) /
            BLITOADZ_COUNT -
            founders[_msgSender()].withdrawnAmount;
        if (value == 0) revert NothingToWithdraw();
        founders[_msgSender()].withdrawnAmount += uint128(
            value % type(uint128).max
        );
        (bool success, ) = _msgSender().call{value: value}("");
        if (!success) revert WithdrawalFailed();

        emit FounderWithdrawn(_msgSender(), value);
        return success;
    }

    /// @notice Retrieve a tokenURI from the combination toadzId, blitmapId
    function tokenURI(uint8 toadzId, uint8 blitmapId)
        external
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < toadzIds.length; i++) {
            if (toadzIds[i] == toadzId && blitmapIds[i] == blitmapId) {
                return tokenURI(i);
            }
        }
        revert BlitoadzDoesNotExist();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        if (renderingContractAddress == address(0)) {
            return "";
        }

        return
            renderer.tokenURI(
                toadzIds[_tokenId],
                blitmapIds[_tokenId],
                palettes[_tokenId]
            );
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    receive() external payable {}
}
