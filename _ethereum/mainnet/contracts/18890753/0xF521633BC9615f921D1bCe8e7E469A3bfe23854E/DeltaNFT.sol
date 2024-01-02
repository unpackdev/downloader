// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./IDeltaNFT.sol";

contract DeltaNFT is IDeltaNFT, ERC721Enumerable, AccessControl {
    bool private initialized;
    using Strings for uint256;

    string constant ROLE_MINTER_STR = "ROLE_MINTER";

    // 0xaeaef46186eb59f884e36929b6d682a6ae35e1e43d8f05f058dcefb92b601461
    bytes32 constant ROLE_MINTER = keccak256(bytes(ROLE_MINTER_STR));

    string constant ROLE_MINTER_ADMIN_STR = "ROLE_MINTER_ADMIN";

    // 0xc30b6f1bcbf41750053d221187e3d61595d548191e1ee1cab3dd3ae1dc469c0a
    bytes32 constant ROLE_MINTER_ADMIN =
        keccak256(bytes(ROLE_MINTER_ADMIN_STR));

    string private baseURI;

    uint256 private tokenId = 0;
    mapping(uint256 => UnlockArgs) public unlockArgsMaps;
    mapping(uint256 => TargetArgs) public targetArgsMaps;

    event MINT(
        address indexed to,
        uint256 indexed tokenId,
        UnlockArgs unlockArgs,
        TargetArgs targetArgs
    );

    event BURN(uint256 indexed tokenId);

    constructor() ERC721("delta.dego", "DELTA") {}

    function initialize(
        address controller,
        address luckyPoolontroller
    ) external {
        require(!initialized, "initialize: Already initialized!");
        baseURI = "https://deltahub.pro/api/delta/metadata/";
        _setRoleAdmin(ROLE_MINTER, ROLE_MINTER_ADMIN);
        _setupRole(ROLE_MINTER_ADMIN, controller);
        _setupRole(ROLE_MINTER_ADMIN, luckyPoolontroller);
        initialized = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(
        address to,
        UnlockArgs calldata unlockArgs,
        TargetArgs calldata targetArgs
    ) external override returns (uint256) {
        require(
            hasRole(ROLE_MINTER, msg.sender),
            "DeltaNFT: Caller is not a minter"
        );
        tokenId++;
        unlockArgsMaps[tokenId] = unlockArgs;
        targetArgsMaps[tokenId] = targetArgs;
        _mint(to, tokenId);
        emit MINT(to, tokenId, unlockArgs, targetArgs);
        return tokenId;
    }

    function getTokenUnlockArgs(
        uint256 _tokenId
    )
        external
        view
        override
        returns (
            uint256 firstReleaseTime,
            uint256 firstBalance,
            uint256 remainingUnlockedType,
            uint256[4] memory remainingUnlocked,
            uint256 totalBalance
        )
    {
        require(_exists(_tokenId), "DeltaNFT: tokenId not exist");
        UnlockArgs memory unlockArgs = unlockArgsMaps[_tokenId];
        firstReleaseTime = unlockArgs.firstReleaseTime;
        firstBalance = unlockArgs.firstBalance;
        remainingUnlockedType = unlockArgs.remainingUnlockedType;
        remainingUnlocked = unlockArgs.remainingUnlocked;
        totalBalance = unlockArgs.totalBalance;
    }

    function getTokenTargetToken(
        uint256 _tokenId
    )
        external
        view
        override
        returns (address targetToken, address poolAddress)
    {
        require(_exists(_tokenId), "DeltaNFT: tokenId not exist");
        targetToken = targetArgsMaps[_tokenId].targetToken;
        poolAddress = targetArgsMaps[_tokenId].poolAddress;
    }

    function burnNFT(uint256 _tokenId) external override {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721: burn caller is not owner nor approved"
        );

        _burn(_tokenId);
        uint256[4] memory zeroArr = [uint256(0), 0, 0, 0];
        unlockArgsMaps[_tokenId] = UnlockArgs(0, 0, 0, zeroArr, 0);
        targetArgsMaps[_tokenId] = TargetArgs(address(0), address(0));
        emit BURN(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "DeltaNFT: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }


    function name() public view virtual override returns (string memory) {
        return "delta.dego";
    }

    function symbol() public view virtual override returns (string memory) {
        return "DELTA";
    }
}
