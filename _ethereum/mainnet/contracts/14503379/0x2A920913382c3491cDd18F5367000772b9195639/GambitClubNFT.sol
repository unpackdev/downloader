//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 *   _____ _             ____                 _     _ _      ____ _       _
 *  |_   _| |__   ___   / ___| __ _ _ __ ___ | |__ (_) |_   / ___| |_   _| |__
 *    | | | '_ \ / _ \ | |  _ / _` | '_ ` _ \| '_ \| | __| | |   | | | | | '_ \
 *    | | | | | |  __/ | |_| | (_| | | | | | | |_) | | |_  | |___| | |_| | |_) |
 *    |_| |_| |_|\___|  \____|\__,_|_| |_| |_|_.__/|_|\__|  \____|_|\__,_|_.__/
 */

import "./IGambitClubNFT.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./TokenRescuer.sol";
import "./MerkleProof.sol";

/// @title The Gambit Club
/// @author Aaron Hanson <coffee.becomes.code@gmail.com> @CoffeeConverter
contract GambitClubNFT is
    IGambitClubNFT,
    ERC721Enumerable,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 3200;

    /// The maximum number of token mints per transaction.
    uint256 public constant MAX_MINT_PER_TX = 25;

    /// The maximum number of presale+whitelist token mints per address.
    uint256 public constant MAX_PRESALE_PER_ADDRESS = 5;

    /// The price per token mint.
    uint256 public constant PRICE = 0.08 ether;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 1000; // 10%

    /// The base URI for token metadata.
    string public baseURI;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The provenance hash summarizing token order and content.
    bytes32 public provenanceHash;

    /// Whether the provenance hash has been locked forever.
    bool public provenanceIsLocked;

    /// Whether the tokenURI() method returns fully revealed tokenURIs
    bool public isRevealed;

    /// The token sale state (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
    SaleState public saleState;

    /// The address of the OpenSea proxy registry contract.
    address public proxyRegistry;

    /// The merkle root summarizing all whitelisted addresses.
    bytes32 public whitelistMerkleRoot;

    /// The merkle root summarizing all presale addresses.
    bytes32 public presaleMerkleRoot;

    /// Whether an address has revoked the automatic OpenSea proxy approval.
    mapping(address => bool) public userRevokedRegistryApproval;

    /// Whether a project proxy contract has been granted automatic approval.
    mapping(address => bool) public projectProxy;

    /// The total tokens minted by an address in presale and whitelist phases.
    mapping(address => uint256) public presaleMinted;

    /// Reverts if the current sale state is not `_saleState`.
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SalePhaseNotActive();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        string memory _contractURI,
        string memory _baseURI,
        bytes32 _provenanceHash,
        bytes32 _whitelistMerkleRoot,
        bytes32 _presaleMerkleRoot,
        address _proxyRegistry
    )
        ERC721(_name, _symbol, _startingTokenID)
    {
        contractURI = _contractURI;
        baseURI = _baseURI;
        provenanceHash = _provenanceHash;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        presaleMerkleRoot = _presaleMerkleRoot;
        proxyRegistry = _proxyRegistry;
    }

    /// @notice Mints a single token to the caller if the proof is valid.
    /// @param _proof The caller's whitelist merkle proof.
    function mintWhitelist(
        bytes32[] calldata _proof
    )
        external
        payable
        onlyInSaleState(SaleState.Whitelist)
    {
        if (!isValidMerkleProof(_proof, whitelistMerkleRoot, _msgSender()))
            revert InvalidMerkleProof();

        if (msg.value != PRICE)
            revert IncorrectPaymentAmount();

        if (presaleMinted[_msgSender()] != 0)
            revert ExceedsMintPhaseAllocation();

        uint256 totalSupply = _owners.length;

        if (totalSupply == MAX_SUPPLY)
            revert ExceedsMaxSupply();

        presaleMinted[_msgSender()] = 1;
        _mint(_msgSender(), totalSupply);
    }

    /// @notice Mints `_mintAmount` tokens to the caller if the proof is valid.
    /// @param _mintAmount The number of tokens to mint (1-5).
    /// @param _proof The caller's presale merkle proof.
    function mintPresale(
        uint256 _mintAmount,
        bytes32[] calldata _proof
    )
        external
        payable
        onlyInSaleState(SaleState.Presale)
    {
        if (!isValidMerkleProof(_proof, presaleMerkleRoot, _msgSender()))
            revert InvalidMerkleProof();

        uint256 totalSupply = _owners.length;

        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();

            if (msg.value != _mintAmount * PRICE)
                revert IncorrectPaymentAmount();

            presaleMinted[_msgSender()] += _mintAmount;

            if (presaleMinted[_msgSender()] > MAX_PRESALE_PER_ADDRESS)
                revert ExceedsMintPhaseAllocation();

            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice Mints `_mintAmount` tokens to the caller.
    /// @param _mintAmount The number of tokens to mint (1-25).
    function mintPublic(
        uint256 _mintAmount
    )
        external
        payable
        onlyInSaleState(SaleState.Public)
    {
        if (_mintAmount > MAX_MINT_PER_TX)
            revert ExceedsMaxMintPerTransaction();

        uint256 totalSupply = _owners.length;

        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();

            if (msg.value != _mintAmount * PRICE)
                revert IncorrectPaymentAmount();

            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice Revokes the automatic approval of the caller's OpenSea proxy.
    function revokeRegistryApproval()
        external
    {
        if (userRevokedRegistryApproval[_msgSender()] == true)
            revert AlreadyRevokedRegistryApproval();

        userRevokedRegistryApproval[_msgSender()] = true;
    }

    /// @notice (only owner) Mints `_mintAmount` free tokens to the caller.
    /// @param _mintAmount The number of tokens to mint.
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        uint256 totalSupply = _owners.length;

        if (totalSupply + _mintAmount > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        unchecked {
            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice (only owner) Sets the saleState to `_newSaleState`.
    /// @param _newSaleState The new sale state
    /// (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /// @notice (only owner) Sets the OpenSea proxy registry contract address.
    /// @param _newProxyRegistry The OpenSea proxy registry contract address.
    function setProxyRegistry(
        address _newProxyRegistry
    )
        external
        onlyOwner
    {
        proxyRegistry = _newProxyRegistry;
    }

    /// @notice (only owner) Toggles the state of a project proxy address.
    /// @param _proxy The project proxy address to toggle true/false.
    function toggleProjectProxy(
        address _proxy
    )
        external
        onlyOwner
    {
        projectProxy[_proxy] = !projectProxy[_proxy];
    }

    /// @notice (only owner) Sets the whitelist merkle root.
    /// @param _newMerkleRoot The new whitelist merkle root.
    function setWhitelistMerkleRoot(
        bytes32 _newMerkleRoot
    )
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
    }

    /// @notice (only owner) Sets the presale merkle root.
    /// @param _newMerkleRoot The new presale merkle root.
    function setPresaleMerkleRoot(
        bytes32 _newMerkleRoot
    )
        external
        onlyOwner
    {
        presaleMerkleRoot = _newMerkleRoot;
    }

    /// @notice (only owner) Sets the contract URI for contract metadata.
    /// @param _newContractURI The new contract URI.
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /// @notice (only owner) Sets the base URI for token metadata.
    /// @param _newBaseURI The new base URI.
    /// @param _doReveal If true, this reveals the full tokenURIs.
    function setBaseURI(
        string calldata _newBaseURI,
        bool _doReveal
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
        isRevealed = _doReveal;
    }

    /// @notice (only owner) Sets the provenance hash, optionally locking it.
    /// @param _newProvenanceHash The new provenance hash.
    /// @param _lockForever Whether to lock this new provenance hash forever.
    function setProvenanceHash(
        bytes32 _newProvenanceHash,
        bool _lockForever
    )
        external
        onlyOwner
    {
        if (provenanceIsLocked) revert ProvenanceHashAlreadyLocked();

        provenanceHash = _newProvenanceHash;
        if (_lockForever) provenanceIsLocked = true;
    }

    /// @notice (only owner) Withdraws `_weiAmount` wei to the caller.
    /// @param _weiAmount The amount of ether (in wei) to withdraw.
    function withdraw(
        uint256 _weiAmount
    )
        external
        onlyOwner
    {
        withdrawTo(_weiAmount, payable(_msgSender()));
    }

    /// @notice (only owner) Withdraws `_weiAmount` wei to `_to`.
    /// @param _weiAmount The amount of ether (in wei) to withdraw.
    /// @param _to The address to which to withdraw ether.
    function withdrawTo(
        uint256 _weiAmount,
        address payable _to
    )
        public
        onlyOwner
    {
        (bool success, ) = _to.call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /// @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
    /// @param _recipient The address to which to send royalties.
    /// @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        if(_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /// @notice Transfers multiple tokens from `_from` to `_to`.
    /// @param _from The address from which to transfer tokens.
    /// @param _to The address to which to transfer tokens.
    /// @param _tokenIDs An array of token IDs to transfer.
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                transferFrom(_from, _to, _tokenIDs[i]);
            }
        }
    }

    /// @notice Safely transfers multiple tokens from `_from` to `_to`.
    /// @param _from The address from which to transfer tokens.
    /// @param _to The address to which to transfer tokens.
    /// @param _tokenIDs An array of token IDs to transfer.
    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs,
        bytes calldata _data
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                safeTransferFrom(_from, _to, _tokenIDs[i], _data);
            }
        }
    }

    /// @notice Determines whether `_account` owns all token IDs `_tokenIDs`.
    /// @param _account The account to be checked for token ownership.
    /// @param _tokenIDs An array of token IDs to be checked for ownership.
    /// @return True if `_account` owns all token IDs `_tokenIDs`, else false.
    function isOwnerOf(
        address _account,
        uint256[] calldata _tokenIDs
    )
        external
        view
        returns (bool)
    {
        unchecked {
            for (uint256 i; i < _tokenIDs.length; ++i) {
                if (ownerOf(_tokenIDs[i]) != _account)
                    return false;
            }
        }

        return true;
    }

    /// @notice Returns an array of all token IDs owned by `_owner`.
    /// @param _owner The address for which to return all owned token IDs.
    /// @return An array of all token IDs owned by `_owner`.
    function walletOfOwner(
        address _owner
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokenIDs;
    }

    /// @notice Checks if `_operator` can transfer tokens owned by `_owner`.
    /// @param _owner The address that may own tokens.
    /// @param _operator The address that may be able to transfer tokens of `_owner`.
    /// @return True if `_operator` can transfer tokens of `_owner`, else false.
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        override (ERC721, IERC721)
        returns (bool)
    {
        if (projectProxy[_operator]) return true;

        if (!userRevokedRegistryApproval[_owner]) {
            OpenSeaProxyRegistry registry = OpenSeaProxyRegistry(proxyRegistry);
            if (address(registry.proxies(_owner)) == _operator) return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /// @notice Returns the token metadata URI for token ID `_tokenID`.
    /// @param _tokenID The token ID whose metadata URI should be returned.
    /// @return The metadata URI for token ID `_tokenID`.
    function tokenURI(
        uint256 _tokenID
    )
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenID)) revert TokenDoesNotExist();
        if (!isRevealed) return baseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenID), ".json"));
    }

    /// @inheritdoc ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Checks whether the merkle proof `_proof` is valid for `_sender`.
    /// @param _proof The merkle proof.
    /// @param _root The merkle root.
    /// @param _sender The sender address for which to validate the proof/root.
    /// @return True if the proof is valid for the sender/root, else false.
    function isValidMerkleProof(
        bytes32[] calldata _proof,
        bytes32 _root,
        address _sender
    )
        public
        pure
        returns (bool)
    {
        bytes32 leaf;
        bytes20 addr = bytes20(_sender);
        assembly {
            mstore(0x00, addr)
            leaf := keccak256(0x00, 0x14)
        }
        return MerkleProof.verify(
            _proof,
            _root,
            leaf
        );
    }

    /// @notice Mints internal token ID `_tokenID` to `_to`, emits actual token ID.
    /// @dev Must be a sequential mint starting at internal token ID 0.
    function _mint(
        address _to,
        uint256 _tokenID
    )
        internal
        override
    {
        _owners.push(_to);
        emit Transfer(address(0), _to, _startingTokenID + _tokenID);
    }
}

/// Stub for OpenSea's per-user-address proxy contract.
contract OwnableDelegateProxy {}

/// Stub for OpenSea's proxy registry contract.
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
