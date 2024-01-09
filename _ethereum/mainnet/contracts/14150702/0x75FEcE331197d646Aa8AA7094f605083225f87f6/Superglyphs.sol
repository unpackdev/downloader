//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";

import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleWithRoyalties.sol";
import "./INiftyForge721.sol";

import "./SignedAllowance.sol";

import "./Randomize.sol";
import "./StringHelpers.sol";

import "./ISuperglyphsRenderer.sol";

/// @title Superglyphs
/// @author Simon Fremaux (@dievardump)
contract Superglyphs is
    Ownable,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties,
    SignedAllowance
{
    // withdraw
    error WithdrawError();

    // auth
    error NotAuthorized();

    // custom / freeze
    error InvalidName();
    error NameAlreadyUsed();
    error WrongCharacter();
    error AlreadyFrozen();
    error OnlyForCustom();
    error CollabSplitterFactoryNotSet();

    // claim
    error WrongParameters();
    error WrongLength();

    error NotOnMainnet();

    event TokenChanged(uint256 tokenId);

    struct TokenMeta {
        bytes16 colors;
        bytes16 symbols;
        address royaltiesSplit;
        string name;
    }

    /// @notice contract on which nfts are created
    address public nftContract;

    /// @notice contract used to do the rendering
    address public renderer;

    /// @notice contract used to extend the list of symbols available
    address public symbolExtension;

    /// @notice collab splitter factory for when people freeze updates
    address public collabSplitterFactory;

    /// @notice token metadata
    mapping(uint256 => TokenMeta) public tokenMetas;

    /// @notice list of already used names
    mapping(bytes32 => bool) private usedNames;

    constructor(
        string memory contractURI_,
        address renderer_,
        address owner_,
        address collabSplitterFactory_,
        address signer
    ) NFBaseModule(contractURI_) {
        renderer = renderer_;

        if (signer != address(0)) {
            _setAllowancesSigner(signer);
        }

        if (collabSplitterFactory_ != address(0)) {
            collabSplitterFactory = collabSplitterFactory_;
        }

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    modifier approvedAndNotFrozen(address operator, uint256 tokenId) {
        if (!isApprovedOrOwner(operator, tokenId)) {
            revert NotAuthorized();
        }
        if (tokenMetas[tokenId].royaltiesSplit != address(0)) {
            revert AlreadyFrozen();
        }
        _;
    }

    /// @dev Receive, for royalties
    receive() external payable {}

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    /// @inheritdoc	INFModule
    function onAttach()
        external
        virtual
        override(INFModule, NFBaseModule)
        returns (bool)
    {
        if (nftContract == address(0)) {
            nftContract = msg.sender;
            return true;
        }

        // only allows attachment if nftContract if not set
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(address(0), tokenId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256 tokenId)
        public
        view
        override
        returns (address receiver, uint256 basisPoint)
    {
        TokenMeta memory tokenMeta = tokenMetas[tokenId];

        // if the token has a royaltiesSplit address, it's a frozen token
        // and the person who froze it is as much its creator as I am
        // so any royalties will be splitted, using a royalties split contract
        // see https://collab-splitter.org
        if (tokenMeta.royaltiesSplit != address(0)) {
            receiver = tokenMeta.royaltiesSplit;
        } else {
            receiver = address(this);
        }

        // 8% royalties
        basisPoint = 800;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(address(0), tokenId);
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        TokenMeta memory tokenMeta = tokenMetas[tokenId];

        uint256 autoColorSeed = tokenMeta.colors != 0
            ? 0
            : getAutoColorSeed(tokenId, IERC721(nftContract).ownerOf(tokenId));

        return
            renderWith(
                _getName(tokenMeta.name),
                tokenId,
                autoColorSeed,
                tokenMeta.colors,
                tokenMeta.symbols,
                tokenMeta.royaltiesSplit != address(0)
            );
    }

    ////////////////////////////////////////////////////
    ///// Getters / Views                             //
    ////////////////////////////////////////////////////

    /// @notice helper to know if a name can be used
    /// @param newName the name to check
    /// @return if the name can be used
    function canUseName(string memory newName) external view returns (bool) {
        if (bytes(newName).length == 0) return true;

        bytes32 slugBytes = keccak256(bytes(StringHelpers.slugify(newName)));
        return (StringHelpers.isNameValid(newName) && !usedNames[slugBytes]);
    }

    /// @notice returns a token name
    /// @param tokenId the token id
    /// @return the token name
    function getName(uint256 tokenId) external view returns (string memory) {
        return _getName(tokenMetas[tokenId].name);
    }

    /// @notice generates the color seed for a tokenId and its owner
    ///         non customised tokens have colors bound to the current owner
    ///         if the owner changes, the colors change
    /// @param tokenId the token id
    /// @param owner_ the owner address
    /// @return the auto generated color seed
    function getAutoColorSeed(uint256 tokenId, address owner_)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(tokenId, owner_)));
    }

    /// @notice renders with given parameters
    /// @param tokenName the name
    /// @param tokenId thhe token id (and seed)
    /// @param colorSeed the seed to use for colors (if not selected before)
    /// @param selectedColors the selected colors
    /// @param selectedSymbols the selected symbols
    /// @param frozen if the token is frozen
    /// @return the json for the token
    function renderWith(
        string memory tokenName,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) public view returns (string memory) {
        return
            ISuperglyphsRenderer(renderer).render(
                tokenName,
                tokenId,
                colorSeed,
                selectedColors,
                selectedSymbols,
                frozen
            );
    }

    /// @notice Gets a symbol from the "symbolExtension"
    /// @param symbolId the symbolId not already existing in renderer
    /// @param random the current randomizer
    /// @return the symbol (empty if not existing)
    function getSymbol(uint256 symbolId, Randomize.Random memory random)
        public
        view
        returns (bytes memory)
    {
        address extension = symbolExtension;
        if (extension != address(0)) {
            return ISymbolExtension(extension).getSymbol(symbolId, random);
        }

        return bytes('');
    }

    /// @notice helper to know if operator is owner or approvedForAll on a token
    /// @param operator the current operator
    /// @param tokenId the tokenId
    /// @return true if operator is owner or approved on the token else false
    function isApprovedOrOwner(address operator, uint256 tokenId)
        public
        view
        returns (bool)
    {
        address nftContract_ = nftContract;
        address owner_ = IERC721(nftContract_).ownerOf(tokenId);
        return (owner_ == operator ||
            IERC721(nftContract_).isApprovedForAll(owner_, operator));
    }

    ////////////////////////////////////////////////////
    ///// Collectors                                  //
    ////////////////////////////////////////////////////

    /// @notice Claiming function
    /// @param recipient the recipient address (the one that did the migration)
    /// @param allocation for the claim (can be 1 or 2 since there are 2 collections that were migrated)
    /// @param signature for the claim
    function claim(
        address recipient,
        uint256 allocation,
        bytes memory signature
    ) public {
        if (allocation == 0 || allocation > 2) {
            revert WrongParameters();
        }

        _useAllowance(recipient, allocation, signature);

        _mint(recipient, allocation);
    }

    /// @notice allows an owner to freeze the Superglyph forever in its curent state
    ///         and become 50% secondary sales royalties recipient for this token, forever
    ///         The owner at the time this function is called will be the recipient
    /// @param tokenId the token id
    function freeze(uint256 tokenId)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        address collabSplitterFactory_ = collabSplitterFactory;
        if (address(0) == collabSplitterFactory_) {
            revert CollabSplitterFactoryNotSet();
        }

        TokenMeta memory meta = tokenMetas[tokenId];

        // need to be fully customized
        if (
            bytes(meta.name).length == 0 ||
            meta.colors == 0 ||
            meta.symbols == 0
        ) {
            revert OnlyForCustom();
        }

        // this creates what is called a CollabSplitter that will be the new RoyaltiesRecipient
        // and will allow to share the royalties between dievardump and the user who freezes their Superglyph
        // https://collab-splitter.org
        address recipient = IERC721(nftContract).ownerOf(tokenId);
        address self = address(this);

        bytes32 leftNode = keccak256(abi.encode(recipient, 5000));
        bytes32 rightNode = keccak256(abi.encode(self, 5000));

        // because of how OZ MerkleTree implementation is done
        if (leftNode > rightNode) {
            (leftNode, rightNode) = (rightNode, leftNode);
        }

        // calculate root with only 2 nodes.
        bytes32 root = keccak256(abi.encodePacked(leftNode, rightNode));

        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = self;

        // divide royalties 50/50
        uint256[] memory allocations = new uint256[](2);
        allocations[0] = 5000;
        allocations[1] = 5000;

        // create collabSplitter and associate it with the token
        tokenMetas[tokenId].royaltiesSplit = ICollabSplitterFactory(
            collabSplitterFactory_
        ).createSplitter(
                string(abi.encodePacked('Superglyphs Splitter - ', meta.name)),
                root,
                recipients,
                allocations
            );
    }

    /// @notice allows an owner to customize their NFT all at once
    /// @param tokenId the token id
    /// @param name the custom name
    /// @param selectedColors the selected colors
    /// @param selectedSymbols the selected symbols
    function customize(
        uint256 tokenId,
        string memory name,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    ) external approvedAndNotFrozen(msg.sender, tokenId) {
        if (selectedColors != 0) {
            _validateColors(selectedColors);
        }

        if (
            keccak256(abi.encodePacked(tokenMetas[tokenId].name)) !=
            keccak256(abi.encodePacked(name))
        ) {
            _setName(tokenId, name);
        }

        tokenMetas[tokenId].colors = selectedColors;
        tokenMetas[tokenId].symbols = selectedSymbols;

        emit TokenChanged(tokenId);
    }

    /// @notice Colors setters for a token
    /// @param tokenId the token Id to set the colors for
    /// @param selectedColors the seclected colors, in 16bytes
    function setColors(uint256 tokenId, bytes16 selectedColors)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        _validateColors(selectedColors);
        tokenMetas[tokenId].colors = selectedColors;
        emit TokenChanged(tokenId);
    }

    /// @notice Symbols setters for a token
    /// @param tokenId the token Id to set the colors for
    /// @param selectedSymbols the seclected symbols, in 16bytes
    function setSymbols(uint256 tokenId, bytes16 selectedSymbols)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        tokenMetas[tokenId].symbols = selectedSymbols;
        emit TokenChanged(tokenId);
    }

    /// @notice Function allowing an owner (or Approved) to set a token name
    ///         User needs to be extra careful. Some characters might completly break the token.
    ///         Since the metadata are generated in the contract.
    ///         if this ever happens, you can simply reset the name to nothing or for something else
    /// @dev sender must be tokenId owner
    /// @param tokenId the token to name
    /// @param newName the name
    function setName(uint256 tokenId, string memory newName)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        _setName(tokenId, newName);
        emit TokenChanged(tokenId);
    }

    ////////////////////////////////////////////////////
    ///// Contract Owner                              //
    ////////////////////////////////////////////////////

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        address owner_ = owner();
        (bool success, ) = owner_.call{value: address(this).balance}('');
        if (!success) revert WithdrawError();
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        _setContractURI(newURI);
    }

    /// @notice sets the collab splitter factory
    /// @param newCollabSplitterFactory the new collab splitter address
    function setCollabSplitterFactory(address newCollabSplitterFactory)
        external
        onlyOwner
    {
        collabSplitterFactory = newCollabSplitterFactory;
    }

    /// @notice Allows to later add an extension to the current symbols
    /// @param extension the address of the extension
    function setSymbolExtension(address extension) public onlyOwner {
        symbolExtension = extension;
    }

    /// @notice Allows to update the renderer contract
    /// @param newRenderer the new renderer address
    function setRenderer(address newRenderer) public onlyOwner {
        renderer = newRenderer;
    }

    ////////////////////////////////////////////////////
    ///// Internal                                    //
    ////////////////////////////////////////////////////

    function _mint(address recipient, uint256 howMany) internal {
        // start seed with values linked to this tx
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                block.coinbase,
                block.difficulty,
                tx.gasprice,
                recipient,
                howMany
            )
        );

        address nftContract_ = nftContract;
        uint256 lastTokenId = INiftyForge721Extended(nftContract_)
            .lastTokenId();

        for (uint256 i; i < howMany; i++) {
            // then play with the allocation id
            seed = keccak256(abi.encode(i, seed, lastTokenId + i + 1));

            // the seed is the token id
            INiftyForge721(nftContract_).mint(
                recipient,
                '',
                uint256(seed),
                address(0),
                0,
                address(0)
            );
        }
    }

    function _getName(string memory name_)
        internal
        pure
        returns (string memory)
    {
        return bytes(name_).length > 0 ? name_ : 'Superglyph';
    }

    /// @dev Validate colors
    /// @param selectedColors the colors in one string (ex: #ffffff#000000)
    function _validateColors(bytes16 selectedColors) internal pure {
        uint256 temp;
        for (uint256 i; i < selectedColors.length; i++) {
            if (i == 14 || i == 15) {
                if (selectedColors[i] != 0) {
                    revert WrongCharacter();
                }
            } else if (i == 0 || i == 7) {
                if (selectedColors[i] != 0x23) {
                    revert WrongCharacter();
                }
            } else {
                temp = uint8(selectedColors[i]);
                if (
                    !(temp >= 97 && temp <= 102) && // a - f
                    !(temp >= 65 && temp <= 70) && // A - F
                    !(temp >= 48 && temp <= 57) // 0 - 9
                ) {
                    revert WrongCharacter();
                }
            }
        }
    }

    /// @dev allows to set a name internally.
    ///      checks that the name is valid and not used, else throws
    /// @param tokenId the token to name
    /// @param newName the name
    function _setName(uint256 tokenId, string memory newName) internal {
        bytes32 slugBytes;

        // if the name is not empty, require that it's valid and not used
        if (bytes(newName).length > 0) {
            if (!StringHelpers.isNameValid(newName)) revert InvalidName();

            // also requires the name is not already used
            slugBytes = keccak256(bytes(StringHelpers.slugify(newName)));
            if (usedNames[slugBytes]) revert NameAlreadyUsed();

            // set as used
            usedNames[slugBytes] = true;
        }

        // if it already has a name, mark the old name as unused
        string memory oldName = tokenMetas[tokenId].name;
        if (bytes(oldName).length > 0) {
            slugBytes = keccak256(bytes(StringHelpers.slugify(oldName)));
            usedNames[slugBytes] = false;
        }

        tokenMetas[tokenId].name = newName;
    }
}

interface ICollabSplitterFactory {
    function createSplitter(
        string memory name_,
        bytes32 merkleRoot,
        address[] memory recipients,
        uint256[] memory amounts
    ) external payable returns (address newContract);
}

interface INiftyForge721Extended {
    function lastTokenId() external view returns (uint256);
}

interface ISymbolExtension {
    function getSymbol(uint256 symbolId, Randomize.Random memory random)
        external
        pure
        returns (bytes memory);
}
