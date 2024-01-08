pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./ERC721Full.sol";
import "./Counters.sol";
import "./IERC721.sol";

import "./Bytes32.sol";
import "./Adminable.sol";
import "./Initializable.sol";
import "./DefiPassportStorage.sol";
import "./ISapphirePassportScores.sol";
import "./SapphireTypes.sol";

contract DefiPassport is ERC721Full, Adminable, DefiPassportStorage, Initializable {

    /* ========== Libraries ========== */

    using Counters for Counters.Counter;
    using Bytes32 for bytes32;

    /* ========== Events ========== */

    event BaseURISet(string _baseURI);

    event ApprovedSkinStatusChanged(
        address _skin,
        uint256 _skinTokenId,
        bool _status
    );

    event ApprovedSkinsStatusesChanged(
        SkinAndTokenIdStatusRecord[] _skinsRecords
    );

    event DefaultSkinStatusChanged(
        address _skin,
        bool _status
    );

    event DefaultActiveSkinChanged(
        address _skin,
        uint256 _skinTokenId
    );

    event ActiveSkinSet(
        uint256 _tokenId,
        SkinRecord _skinRecord
    );

    event SkinManagerSet(address _skinManager);

    event PassportScoresContractSet(address _passportScoresContract);

    event WhitelistSkinSet(address _skin, bool _status);

    event ProofProtocolSet(string _protocol);

    /* ========== Public variables ========== */

    string public baseURI;

    bytes32 private _proofProtocol;

    /* ========== Constructor ========== */

    constructor()
        ERC721Full("", "")
        public
    {}

    /* ========== Modifier ========== */

    modifier onlySkinManager () {
        require(
            msg.sender == skinManager,
            "DefiPassport: caller is not skin manager"
        );
        _;
    }

    /* ========== Restricted Functions ========== */

    function init(
        string calldata _name,
        string calldata _symbol,
        address _passportScoresAddress,
        address _skinManager
    )
        external
        onlyAdmin
        initializer
    {
        name = _name;
        symbol = _symbol;
        skinManager = _skinManager;

        require(
            _passportScoresAddress.isContract(),
            "DefiPassport: passport scores address is not a contract"
        );

        passportScoresContract = ISapphirePassportScores(_passportScoresAddress);

        /*
        *   register the supported interfaces to conform to ERC721 via ERC165
        *   bytes4(keccak256('name()')) == 0x06fdde03
        *   bytes4(keccak256('symbol()')) == 0x95d89b41
        *   bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
        *
        *   => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
        */
        _registerInterface(0x5b5e139f);
    }

    /**
     * @dev Sets the base URI that is appended as a prefix to the
     *      token URI.
     */
    function setBaseURI(
        string calldata _baseURI
    )
        external
        onlyAdmin
    {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /**
     * @notice Sets the protocol to be used in the score proof when minting new passports
     */
    function setProofProtocol(
        bytes32 _protocol
    )
        external
        onlyAdmin
    {
        _proofProtocol = _protocol;

        emit ProofProtocolSet(_proofProtocol.toString());
    }

    /**
     * @dev Sets the address of the skin manager role
     *
     * @param _skinManager The new skin manager
     */
    function setSkinManager(
        address _skinManager
    )
        external
        onlyAdmin
    {
        require (
            _skinManager != skinManager,
            "DefiPassport: the same skin manager is already set"
        );

        skinManager = _skinManager;

        emit SkinManagerSet(skinManager);
    }

    /**
     * @notice Registers/unregisters a default skin
     *
     * @param _skin Address of the skin NFT
     * @param _status Wether or not it should be considered as a default
     *                skin or not
     */
    function setDefaultSkin(
        address _skin,
        bool _status
    )
        external
        onlySkinManager
    {
        if (!_status) {
            require(
                defaultActiveSkin.skin != _skin,
                "Defi Passport: cannot unregister the default active skin"
            );
        }

        require(
            defaultSkins[_skin] != _status,
            "DefiPassport: skin already has the same status"
        );

        require(
            _skin.isContract(),
            "DefiPassport: the given skin is not a contract"
        );

        require (
            IERC721(_skin).ownerOf(1) != address(0),
            "DefiPassport: default skin must at least have tokenId eq 1"
        );

        if (defaultActiveSkin.skin == address(0)) {
            defaultActiveSkin = SkinRecord(address(0), _skin, 1);
        }

        defaultSkins[_skin] = _status;

        emit DefaultSkinStatusChanged(_skin, _status);
    }

    /**
     * @dev    Set the default active skin, which will be used instead of
     *         unavailable user's active one
     * @notice Skin should be used as default one (with setDefaultSkin function)
     *
     * @param _skin        Address of the skin NFT
     * @param _skinTokenId The NFT token ID
     */
    function setDefaultActiveSkin(
        address _skin,
        uint256 _skinTokenId
    )
        external
        onlySkinManager
    {
        require(
            defaultSkins[_skin],
            "DefiPassport: the given skin is not registered as a default"
        );

        require(
            defaultActiveSkin.skin != _skin ||
                defaultActiveSkin.skinTokenId != _skinTokenId,
            "DefiPassport: the skin is already set as default active"
        );

        defaultActiveSkin = SkinRecord(address(0), _skin, _skinTokenId);

        emit DefaultActiveSkinChanged(_skin, _skinTokenId);
    }

    /**
     * @notice Approves a passport skin.
     *         Only callable by the skin manager
     */
    function setApprovedSkin(
        address _skin,
        uint256 _skinTokenId,
        bool _status
    )
        external
        onlySkinManager
    {
        approvedSkins[_skin][_skinTokenId] = _status;

        emit ApprovedSkinStatusChanged(_skin, _skinTokenId, _status);
    }

    /**
     * @notice Sets the approved status for all skin contracts and their
     *         token IDs passed into this function.
     */
    function setApprovedSkins(
        SkinAndTokenIdStatusRecord[] memory _skinsToApprove
    )
        public
        onlySkinManager
    {
        for (uint256 i = 0; i < _skinsToApprove.length; i++) {
            TokenIdStatus[] memory tokensAndStatuses = _skinsToApprove[i].skinTokenIdStatuses;

            for (uint256 j = 0; j < tokensAndStatuses.length; j ++) {
                TokenIdStatus memory tokenStatusPair = tokensAndStatuses[j];

                approvedSkins[_skinsToApprove[i].skin][tokenStatusPair.tokenId] = tokenStatusPair.status;
            }
        }

        emit ApprovedSkinsStatusesChanged(_skinsToApprove);
    }

    /**
     * @notice Adds or removes a skin contract to the whitelist.
     *         The Defi Passport considers all skins minted by whitelisted contracts
     *         to be valid skins for applying them on to the passport.
     *         The user applying the skins must still be their owner though.
     */
    function setWhitelistedSkin(
        address _skinContract,
        bool _status
    )
        external
        onlySkinManager
    {
        require (
            _skinContract.isContract(),
            "DefiPassport: address is not a contract"
        );

        require (
            whitelistedSkins[_skinContract] != _status,
            "DefiPassport: the skin already has the same whitelist status"
        );

        whitelistedSkins[_skinContract] = _status;

        emit WhitelistSkinSet(_skinContract, _status);
    }

    function setPassportScoresContract(
        address _passportScoresAddress
    )
        external
        onlyAdmin
    {
        require(
            address(passportScoresContract) != _passportScoresAddress,
            "DefiPassport: the same passport scores address is already set"
        );

        require(
            _passportScoresAddress.isContract(),
            "DefiPassport: the given address is not a contract"
        );

        passportScoresContract = ISapphirePassportScores(_passportScoresAddress);

        emit PassportScoresContractSet(_passportScoresAddress);
    }

    /* ========== Public Functions ========== */

    /**
     * @notice Mints a DeFi passport to the address specified by `_to`. Note:
     *         - The `_passportSkin` must be an approved or default skin.
     *         - The token URI will be composed by <baseURI> + `_to`,
     *           without the "0x" in front
     *
     * @param _to The receiver of the defi passport
     * @param _passportSkin The address of the skin NFT to be applied to the passport
     * @param _skinTokenId The ID of the passport skin NFT, owned by the receiver
     */
    function mint(
        address _to,
        address _passportSkin,
        uint256 _skinTokenId,
        SapphireTypes.ScoreProof calldata _scoreProof
    )
        external
        returns (uint256)
    {
        require(
            _to == _scoreProof.account,
            "DefiPassport: the proof must correspond to the receiver"
        );

        require(
            _scoreProof.protocol == _proofProtocol,
            "DefiPassport: invalid proof protocol"
        );

        passportScoresContract.verify(_scoreProof);

        require (
            isSkinAvailable(_to, _passportSkin, _skinTokenId),
            "DefiPassport: invalid skin"
        );

        // A user cannot have two passports
        require(
            balanceOf(_to) == 0,
            "DefiPassport: user already has a defi passport"
        );

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);
        _setActiveSkin(newTokenId, SkinRecord(_to, _passportSkin, _skinTokenId));

        return newTokenId;
    }

    /**
     * @notice Changes the passport skin of the caller's passport
     *
     * @param _skin The contract address to the skin NFT
     * @param _skinTokenId The ID of the skin NFT
     */
    function setActiveSkin(
        address _skin,
        uint256 _skinTokenId
    )
        external
    {
        require(
            balanceOf(msg.sender) > 0,
            "DefiPassport: caller has no passport"
        );

        require(
            isSkinAvailable(msg.sender, _skin, _skinTokenId),
            "DefiPassport: invalid skin"
        );

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        _setActiveSkin(tokenId, SkinRecord(msg.sender, _skin, _skinTokenId));
    }

    function approve(
        address to,
        uint256 tokenId
    )
        public
    {
        revert("DefiPassport: defi passports are not transferrable");
    }

    function setApprovalForAll(
        address to,
        bool approved
    )
        public
    {
        revert("DefiPassport: defi passports are not transferrable");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
    {
        revert("DefiPassport: defi passports are not transferrable");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        public
    {
        revert("DefiPassport: defi passports are not transferrable");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
    {
        revert("DefiPassport: defi passports are not transferrable");
    }

    /* ========== Public View Functions ========== */

    /**
     * @notice Returns whether a certain skin can be applied to the specified
     *         user's passport.
     *
     * @param _user The user for whom to check
     * @param _skinContract The address of the skin NFT
     * @param _skinTokenId The NFT token ID
     */
    function isSkinAvailable(
        address _user,
        address _skinContract,
        uint256 _skinTokenId
    )
        public
        view
        returns (bool)
    {
        if (defaultSkins[_skinContract]) {
            return IERC721(_skinContract).ownerOf(_skinTokenId) != address(0);
        } else if (
            whitelistedSkins[_skinContract] ||
            approvedSkins[_skinContract][_skinTokenId]
        ) {
            return _isSkinOwner(_user, _skinContract, _skinTokenId);
        }

        return false;
    }

    /**
     * @notice Returns the active skin of the given passport ID
     *
     * @param _tokenId Passport ID
     */
    function getActiveSkin(
        uint256 _tokenId
    )
        public
        view
        returns (SkinRecord memory)
    {
        SkinRecord memory _activeSkin = _activeSkins[_tokenId];

        if (isSkinAvailable(_activeSkin.owner, _activeSkin.skin, _activeSkin.skinTokenId)) {
            return _activeSkin;
        } else {
            return defaultActiveSkin;
        }
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(
        uint256 tokenId
    )
        external
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        address owner = ownerOf(tokenId);

        return string(abi.encodePacked(baseURI, "0x", _toAsciiString(owner)));
    }

    function getProofProtocol()
        external
        view
        returns (string memory)
    {
        return _proofProtocol.toString();
    }

    /* ========== Private Functions ========== */

    /**
     * @dev Converts the given address to string. Used when minting new
     *      passports.
     */
    function _toAsciiString(
        address _address
    )
        private
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_address)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return string(s);
    }

    function _char(
        bytes1 b
    )
        private
        pure
        returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Ensures that the user is the owner of the skin NFT
     */
    function _isSkinOwner(
        address _user,
        address _skin,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        /**
         * It is not sure if the skin contract implements the ERC721 or ERC1155 standard,
         * so we must do the check.
         */
        bytes memory payload = abi.encodeWithSignature("ownerOf(uint256)", _tokenId);
        (bool success, bytes memory returnData) = _skin.staticcall(payload);

        if (success) {
            (address owner) = abi.decode(returnData, (address));

            return owner == _user;
        } else {
            // The skin contract might be an ERC1155 (like OpenSea)
            payload = abi.encodeWithSignature("balanceOf(address,uint256)", _user, _tokenId);
            (success, returnData) = _skin.staticcall(payload);

            if (success) {
                (uint256 balance) = abi.decode(returnData, (uint256));

                return balance > 0;
            }
        }

        return false;
    }

    function _setActiveSkin(
        uint256 _tokenId,
        SkinRecord memory _skinRecord
    )
        private
    {
        SkinRecord memory currentSkin = _activeSkins[_tokenId];

        require(
            currentSkin.skin != _skinRecord.skin ||
                currentSkin.skinTokenId != _skinRecord.skinTokenId,
            "DefiPassport: the same skin is already active"
        );

        _activeSkins[_tokenId] = _skinRecord;

        emit ActiveSkinSet(_tokenId, _skinRecord);
    }
}
