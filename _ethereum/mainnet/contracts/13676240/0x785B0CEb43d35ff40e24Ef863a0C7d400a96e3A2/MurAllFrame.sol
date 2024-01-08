// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./ERC165Checker.sol";
import "./IERC721Receiver.sol";
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IFrameTraitManager.sol";
import "./IERC2981.sol";
import "./IRoyaltyGovernor.sol";
import "./VRFConsumerBase.sol";
import "./MintManager.sol";
import "./TraitSeedManager.sol";

/**
 * MurAll Frame contract
 */
contract MurAllFrame is AccessControl, ReentrancyGuard, IERC2981, IERC721Receiver, ERC1155Receiver, ERC721 {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant TRAIT_MOD_ROLE = keccak256("TRAIT_MOD_ROLE");

    using Strings for uint256;
    using ERC165Checker for address;
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    uint64 public immutable MAX_SUPPLY = 4444;

    IFrameTraitManager public frameTraitManager;
    MintManager public mintManager;
    IRoyaltyGovernor public royaltyGovernorContract;
    TraitSeedManager public traitSeedManager;
    string public contractURI;

    mapping(uint256 => uint256) private customFrameTraits;

    struct FrameContents {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        bool bound;
    }

    mapping(uint256 => FrameContents) public frameContents;

    event RandomnessRequested(bytes32 requestId);
    event TraitSeedSet(uint256 seed);

    /** @dev Checks if token exists
     * @param _tokenId The token id to check if exists
     */
    modifier onlyExistingTokens(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid Token ID");
        _;
    }

    /** @dev Checks if sender address has admin role
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Does not have admin role");
        _;
    }
    
    /** @dev Checks if sender address has admin role
     */
    modifier onlyTraitMod() {
        require(hasRole(TRAIT_MOD_ROLE, msg.sender), "Does not have trait mod role");
        _;
    }

    event FrameContentsUpdated(
        uint256 indexed id,
        address indexed contentsContract,
        uint256 contentsId,
        uint256 amount,
        bool bound
    );
    event FrameContentsRemoved(uint256 indexed id);
    event RoyaltyGovernorContractChanged(address indexed royaltyGovernor);
    event FrameTraitManagerChanged(address indexed frameTraitManager);
    event FrameMinted(uint256 indexed id, address indexed owner);

    constructor(
        address[] memory admins,
        MintManager _mintManager,
        TraitSeedManager _traitSeedManager
    ) public ERC721("Frames by MurAll", "FRAMES") {
        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }

        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(TRAIT_MOD_ROLE, admins[i]);
        }
        // traitSeedManager = new TraitSeedManager(admins, _vrfCoordinator, _linkTokenAddr, _keyHash, _fee, 435, 252);
        traitSeedManager = _traitSeedManager;

        // mintManager = new MintManager(this, admins, 436, 1004, 0.144 ether, 0.244 ether);
        mintManager = _mintManager;
        _registerInterface(IERC721Receiver(0).onERC721Received.selector);
    }

    function setCustomTraits(uint256[] memory traitHash, uint256[] memory indexes) public onlyTraitMod {
        require(traitHash.length == indexes.length, "Trait hash and indexes length mismatch");

        for (uint256 i = 0; i < traitHash.length; ++i) {
            require(indexes[i] < mintManager.NUM_INITIAL_MINTABLE(), "Cannot change trait hash for index");
            require(customFrameTraits[indexes[i]] == 0, "Cannot change trait hash for index");
            customFrameTraits[indexes[i]] = traitHash[i];
        }
    }

    /**
     * @notice Set the base URI for creating `tokenURI` for each NFT.
     * Only invokable by admin role.
     * @param _tokenUriBase base for the ERC721 tokenURI
     */
    function setTokenUriBase(string calldata _tokenUriBase) external onlyAdmin {
        // Set the base for metadata tokenURI
        _setBaseURI(_tokenUriBase);
    }

    /**
     * @notice Set the contract URI for marketplace data.
     * Only invokable by admin role.
     * @param _contractURI contract uri for this contract
     */
    function setContractUri(string calldata _contractURI) external onlyAdmin {
        // Set the base for metadata tokenURI
        contractURI = _contractURI;
    }

    /**
     * @notice Set the frame trait manager contract.
     * Only invokable by admin role.
     * @param managerAddress the address of the frame trait image storage contract
     */
    function setFrameTraitManager(IFrameTraitManager managerAddress) public onlyAdmin {
        frameTraitManager = IFrameTraitManager(managerAddress);
        emit FrameTraitManagerChanged(address(managerAddress));
    }

    /**
     * @notice Set the Royalty Governer for creating `tokenURI` for each Montage NFT.
     * Only invokable by admin role.
     * @param _royaltyGovAddr the address of the Royalty Governer contract
     */
    function setRoyaltyGovernor(IRoyaltyGovernor _royaltyGovAddr) external onlyAdmin {
        royaltyGovernorContract = _royaltyGovAddr;
        emit RoyaltyGovernorContractChanged(address(_royaltyGovAddr));
    }

    function getTraits(uint256 _tokenId) public view onlyExistingTokens(_tokenId) returns (uint256 traits) {
        if (customFrameTraits[_tokenId] != 0) {
            return customFrameTraits[_tokenId];
        } else {
            uint256 traitSeed = traitSeedManager.getTraitSeed(_tokenId);
            return uint256(keccak256(abi.encode(traitSeed, _tokenId)));
        }
    }

    function setFrameContents(
        uint256 _tokenId,
        address contentContractAddress,
        uint256 contentTokenId,
        uint256 contentAmount,
        bool bindContentToFrame
    ) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "Not token owner"); // this will also fail if the token does not exist
        if (bindContentToFrame) {
            require(!frameContents[_tokenId].bound, "Frame already contains bound content");
            if (contentContractAddress.supportsInterface(_INTERFACE_ID_ERC721)) {
                // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
                IERC721(contentContractAddress).safeTransferFrom(msg.sender, address(this), contentTokenId, "");
            } else if (contentContractAddress.supportsInterface(_INTERFACE_ID_ERC1155)) {
                // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
                IERC1155(contentContractAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    contentTokenId,
                    contentAmount,
                    ""
                );
            } else revert();
        } else {
            if (contentContractAddress.supportsInterface(_INTERFACE_ID_ERC721)) {
                require(IERC721(contentContractAddress).ownerOf(contentTokenId) == msg.sender, "Not token owner");
            } else if (contentContractAddress.supportsInterface(_INTERFACE_ID_ERC1155)) {
                require(
                    IERC1155(contentContractAddress).balanceOf(msg.sender, contentTokenId) >= contentAmount,
                    "Not enough tokens"
                );
            } else {
                revert();
            }
        }
        createFrameContents(_tokenId, contentContractAddress, contentTokenId, contentAmount, bindContentToFrame);
    }

    function removeFrameContents(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "Not token owner"); // this will also fail if the token does not exist
        require(hasContentsInFrame(_tokenId), "Frame does not contain any content"); // Also checks token exists
        FrameContents memory _frameContents = frameContents[_tokenId];
        if (_frameContents.bound) {
            if (_frameContents.contractAddress.supportsInterface(_INTERFACE_ID_ERC721)) {
                // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
                IERC721(_frameContents.contractAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _frameContents.tokenId
                );
            } else {
                // transfer ownership of the token to this contract (will fail if contract is not approved prior to this)
                IERC1155(_frameContents.contractAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _frameContents.tokenId,
                    _frameContents.amount,
                    ""
                );
            }
        }

        delete frameContents[_tokenId];
        emit FrameContentsRemoved(_tokenId);
    }

    function hasContentsInFrame(uint256 _tokenId) public view onlyExistingTokens(_tokenId) returns (bool) {
        return frameContents[_tokenId].contractAddress != address(0);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert();
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        returns (
            address _receiver,
            uint256 _royaltyAmount,
            bytes memory _royaltyPaymentData
        )
    {
        return royaltyGovernorContract.royaltyInfo(_tokenId, _value, _data);
    }

    function createFrameContents(
        uint256 _tokenId,
        address contentContractAddress,
        uint256 contentTokenId,
        uint256 contentAmount,
        bool bindContentToFrame
    ) private onlyExistingTokens(_tokenId) {
        FrameContents memory newFrameContents = FrameContents(
            contentContractAddress,
            contentTokenId,
            contentAmount,
            bindContentToFrame
        );
        frameContents[_tokenId] = newFrameContents;

        emit FrameContentsUpdated(_tokenId, contentContractAddress, contentTokenId, contentAmount, bindContentToFrame);
    }

    function mint(uint256 amount) public payable nonReentrant {
        mintManager.checkCanMintPublic(msg.sender, msg.value, amount);
        uint256 maxId = traitSeedManager.getMaxIdForCurrentPhase();
        for (uint256 i = 0; i < amount; ++i) {
            mintInternal(msg.sender, maxId);
        }
    }

    function mintPresale(
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof,
        uint256 amountDesired
    ) public payable nonReentrant {
        mintManager.checkCanMintPresale(msg.sender, msg.value, index, maxAmount, merkleProof, amountDesired);
        uint256 maxId = traitSeedManager.getMaxIdForCurrentPhase();
        uint256 amountToMint = maxAmount < amountDesired ? maxAmount : amountDesired;
        for (uint256 i = 0; i < amountToMint; ++i) {
            mintInternal(msg.sender, maxId);
        }
    }

    function mintInitial(uint256 amountToMint) public nonReentrant onlyAdmin returns (uint256) {
        mintManager.checkCanMintInitial(amountToMint);
        uint256 maxId = traitSeedManager.getMaxIdForCurrentPhase();
        for (uint256 i = 0; i < amountToMint; ++i) {
            mintInternal(msg.sender, maxId);
        }
    }

    function mintInternal(address account, uint256 maxId) private {
        require(totalSupply() <= MAX_SUPPLY, "Maximum number of NFTs minted");

        // mint a new frame
        uint256 _id = totalSupply();
        require(_id <= maxId, "Maximum number of NFTs for phase minted");
        _mint(account, _id);
        emit FrameMinted(_id, account);
    }

    function withdrawFunds(address payable _to) public onlyAdmin {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Failed to transfer the funds, aborting.");
    }

    function rescueTokens(address tokenAddress) public onlyAdmin {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(msg.sender, balance), "rescueTokens: Transfer failed.");
    }

    fallback() external payable {}

    receive() external payable {}
}
