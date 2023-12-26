// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC721AntiScam.sol";
import "./ERC2981.sol";

contract DigDogTowns is
    AccessControl,
    ERC721AntiScam,
    ERC2981
{
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    mapping(uint256 => string) private _tokenURIs;

    address public royaltyReceiver = 0x30e2B5141e57607B6E154B2Eb937d18dBF42298A;

    constructor() ERC721Psi("DigDogTowns!!!", "DDT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);

        _setDefaultRoyalty(royaltyReceiver, 1000); // 10%
    }

    /**
     * ミント関数
     */
    /// @dev MINTERによる外部ミント関数
    /// @notice この関数を止める機能は実装していません。
    ///         MINTERロールをrevokeするか、ミント用コントラクトにpauseを実装してください。
    function mint(address _to, uint256 _amount) external onlyRole(MINTER) {
        /**
         * @notice ミント用コントラクトでコントラクトからのミントをrevertするので
         *         _safeMint()ではなく_mint()を使用しています
         */
        _mint(_to, _amount);
    }

    /// @dev エアドロミント関数
    function adminMint(
        address[] calldata _airdropAddresses,
        uint256[] calldata _UserMintAmount
    ) external onlyRole(ADMIN) {
        require(
            _airdropAddresses.length == _UserMintAmount.length,
            "array length unmatch"
        );

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            require(_UserMintAmount[i] > 0, "amount 0 address exists!");

            _safeMint(_airdropAddresses[i], _UserMintAmount[i]);
        }
    }

    /**
     * tokenURI関係
     */
    /// @dev ERC721URIStorageをそのまま流用 冗長かも
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /// @dev tokenIdごとメタデータファイルのsetter
    function setTokenURI(
        uint256[] calldata _tokenId,
        string[] calldata _tokenURI
    ) external onlyRole(ADMIN) {
        require(_tokenId.length == _tokenURI.length, "array length unmatch");

        for (uint256 i = 0; i < _tokenId.length; i++) {
            _tokenURIs[_tokenId[i]] = _tokenURI[i];
        }
    }

    /**
     * ADMIN用 setter関数
     */
    /// @dev sAFA抑止機能のON/OFF（基本はONですが、念のため）
    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    /// @dev ロック機構のON/OFF（基本はONですが、念のため）
    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
    }

    /**
     * OVERRIDES ERC721Lockable functions
     */
    /**
     * @notice setTokenLock()とsetWalletLock()は持ち主に加え、ADMINも操作できるようにしました
     *         setContractLock()はownerでなく、ADMINが使えるようにしました
     */
    function setTokenLock(
        uint256[] calldata tokenIds,
        LockStatus lockStatus
    ) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(tokenIds[i]) ||
                    hasRole(ADMIN, msg.sender),
                "not owner or admin."
            );
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setWalletLock(
        address to,
        LockStatus lockStatus
    ) external override {
        require(
            to == msg.sender || hasRole(ADMIN, msg.sender),
            "not yourself or admin."
        );
        _setWalletLock(to, lockStatus);
    }

    function setContractLock(
        LockStatus lockStatus
    ) external override onlyRole(ADMIN) {
        _setContractLock(lockStatus);
    }

    /**
     * OVERRIDES ERC721RestrictApprove functions
     */
    function addLocalContractAllowList(
        address transferer
    ) external override onlyRole(ADMIN) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(
        address transferer
    ) external override onlyRole(ADMIN) {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        override
        returns (address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) external override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    /**
     * ERC2981のSetter関数
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(ADMIN) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(ADMIN) {
        _deleteDefaultRoyalty();
    }

    /**
     * その他の関数
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC721AntiScam, ERC2981)
        returns (bool)
    {
        return (AccessControl.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId));
    }

    /// @notice admin専用burn関数
    function adminBurn(
        address _address,
        uint256 _tokenId
    ) external onlyRole(ADMIN) {
        require(_address == ownerOf(_tokenId), "address is not owner");

        _burn(_tokenId);
    }
}