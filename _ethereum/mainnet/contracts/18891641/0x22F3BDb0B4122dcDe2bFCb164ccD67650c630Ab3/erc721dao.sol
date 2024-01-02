// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./AccessControl.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IERC721Receiver.sol";
import "./ERC2981.sol";
import "./erc20dao.sol";
import "./emitter.sol";
import "./helper.sol";
import "./factory.sol";

contract ERC721DAO is
    IERC721Receiver,
    ERC721Upgradeable,
    AccessControl,
    ERC2981,
    Helper
{
    using SafeERC20 for IERC20;

    uint256 public _tokenIdTracker;

    mapping(uint256 => string) private _tokenURIs;

    address public factoryAddress;

    address public emitterAddress;

    ERC721DAOdetails public erc721DaoDetails;

    /// @dev initialize Function to initialize NFT Token contract
    /// @param _DaoName name of DAO
    /// @param _DaoSymbol symbol of DAO
    function initializeERC721(
        string calldata _DaoName,
        string calldata _DaoSymbol,
        address _factoryAddress,
        address _emitterAddress,
        uint256 _quorum,
        uint256 _threshold,
        uint256 _maxTokensPerUser,
        bool _isTransferable,
        bool _isNftTotalSupplyUnlimited,
        bool _isGovernanceActive,
        bool _onlyAllowWhitelist,
        address _ownerAddress
    ) external initializer {
        factoryAddress = _factoryAddress;
        emitterAddress = _emitterAddress;
        ERC721DAOdetails memory _erc721DaoDetails = ERC721DAOdetails(
            _DaoName,
            _DaoSymbol,
            _quorum,
            _threshold,
            _maxTokensPerUser,
            _isTransferable,
            _isNftTotalSupplyUnlimited,
            _isGovernanceActive,
            _onlyAllowWhitelist,
            _ownerAddress
        );
        erc721DaoDetails = _erc721DaoDetails;

        __ERC721_init(_DaoName, _DaoSymbol);
    }

    /// @dev This function returns details of a particular dao
    function getERC721DAOdetails()
        external
        view
        returns (ERC721DAOdetails memory)
    {
        return erc721DaoDetails;
    }

    /// @dev Function to mint Governance Token and assign delegate
    /// @param _to Address to which tokens will be minted
    /// @param _tokenURI token URI of nft
    function mintNft(
        address _to,
        string memory _tokenURI,
        bytes32[] calldata _merkleProof
    ) public onlyFactory(factoryAddress) {
        if (balanceOf(_to) == erc721DaoDetails.maxTokensPerUser)
            revert MaxTokensMintedForUser(_to);

        if (erc721DaoDetails.onlyAllowWhitelist) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .merkleRoot,
                    keccak256(abi.encodePacked(_to))
                ),
                "Incorrect proof"
            );
        }

        _tokenIdTracker += 1;
        if (!erc721DaoDetails.isNftTotalSupplyUnlimited) {
            require(
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .distributionAmount >= _tokenIdTracker,
                "Max supply reached"
            );
        }

        _safeMint(_to, _tokenIdTracker);
        _setTokenURI(_tokenIdTracker, _tokenURI);

        Emitter(emitterAddress).mintNft(
            _to,
            address(this),
            _tokenURI,
            _tokenIdTracker
        );
    }

    /// @dev Function execute proposals called by gnosis safe
    /// @param _data function signature data encoded along with parameters
    function updateProposalAndExecution(
        address _contract,
        bytes memory _data
    ) external onlyGnosis(factoryAddress, address(this)) {
        if (_contract == address(0))
            revert AddressInvalid("_contract", _contract);
        (bool success, ) = _contract.call(_data);
        require(success);
    }

    /// @dev Function to transfer NFT from this contract
    /// @param _nft address of nft to transfer
    /// @param _to address of receiver
    /// @param _tokenId tokenId of nft to transfer
    function transferNft(
        address _nft,
        address _to,
        uint256 _tokenId
    ) external onlyCurrentContract {
        if (_nft == address(0)) revert AddressInvalid("_nft", _nft);
        if (_to == address(0)) revert AddressInvalid("_to", _to);
        IERC721(_nft).safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @dev Function to change governance active
    /// @param _isGovernanceActive New governance active status
    function updateGovernanceActive(
        bool _isGovernanceActive
    ) external payable onlyCurrentContract {
        erc721DaoDetails.isGovernanceActive = _isGovernanceActive;
    }

    /// @param _amountArray array of amount to be transferred
    /// @param _tokenURI array of token uri for each nft
    /// @param _userAddress array of address where the amount should be transferred
    function mintGTToAddress(
        uint256[] memory _amountArray,
        string[] memory _tokenURI,
        address[] memory _userAddress
    ) external onlyCurrentContract {
        if (_tokenURI.length != _userAddress.length)
            revert ArrayLengthMismatch(_tokenURI.length, _userAddress.length);

        if (_amountArray.length != _userAddress.length)
            revert ArrayLengthMismatch(
                _amountArray.length,
                _userAddress.length
            );

        uint256 length = _userAddress.length;
        for (uint256 i; i < length; ) {
            for (uint j; j < _amountArray[i]; ) {
                if (
                    balanceOf(_userAddress[i]) ==
                    erc721DaoDetails.maxTokensPerUser
                ) revert MaxTokensMintedForUser(_userAddress[i]);
                _tokenIdTracker += 1;
                if (!erc721DaoDetails.isNftTotalSupplyUnlimited) {
                    require(
                        Factory(factoryAddress)
                            .getDAOdetails(address(this))
                            .distributionAmount >= _tokenIdTracker,
                        "Max supply reached"
                    );
                }
                _safeMint(_userAddress[i], _tokenIdTracker);
                _setTokenURI(_tokenIdTracker, _tokenURI[i]);
                unchecked {
                    ++j;
                }
            }

            Emitter(emitterAddress).newUser(
                address(this),
                _userAddress[i],
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .depositTokenAddress,
                0,
                block.timestamp,
                _amountArray[i],
                Safe(
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .gnosisAddress
                ).isOwner(_userAddress[i])
            );

            unchecked {
                ++i;
            }
        }

        Emitter(emitterAddress).mintGTToAddress(
            address(this),
            _amountArray,
            _userAddress
        );
    }

    /// @dev function to update governance settings
    /// @param _quorum update quorum into the contract
    /// @param _threshold update threshold into the contract
    function updateGovernanceSettings(
        uint256 _quorum,
        uint256 _threshold
    ) external onlyCurrentContract {
        if (_quorum == 0) revert AmountInvalid("_quorum", _quorum);
        if (_threshold == 0) revert AmountInvalid("_threshold", _threshold);

        if (!(_quorum <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_quorum", _quorum);
        if (!(_threshold <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_threshold", _threshold);

        erc721DaoDetails.quorum = _quorum;
        erc721DaoDetails.threshold = _threshold;

        Emitter(emitterAddress).updateGovernanceSettings(
            address(this),
            _quorum,
            _threshold
        );
    }

    /// @dev Function to set whitelist to true for a particular token contract
    function toggleOnlyAllowWhitelist() external payable onlyCurrentContract {
        erc721DaoDetails.onlyAllowWhitelist = !erc721DaoDetails
            .onlyAllowWhitelist;
    }

    /// @dev Function to update nft transferability for a particular token contract
    /// @param _isNftTransferable New nft transferability
    function updateTokenTransferability(
        bool _isNftTransferable
    ) external payable onlyCurrentContract {
        erc721DaoDetails.isTransferable = _isNftTransferable;

        Emitter(emitterAddress).updateTokenTransferability(
            address(this),
            _isNftTransferable
        );
    }

    function updateMaxTokensPerUser(
        uint256 _maxTokensPerUser
    ) external payable onlyCurrentContract {
        erc721DaoDetails.maxTokensPerUser = _maxTokensPerUser;
        Emitter(emitterAddress).updateMaxTokensPerUser(
            address(this),
            _maxTokensPerUser
        );
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        return _tokenURIs[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        require(balanceOf(to) <= erc721DaoDetails.maxTokensPerUser);
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        require(erc721DaoDetails.isTransferable, "NFT Non Transferable");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) {
        require(balanceOf(to) <= erc721DaoDetails.maxTokensPerUser);
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        require(erc721DaoDetails.isTransferable, "NFT Non Transferable");
        _safeTransfer(from, to, tokenId, data);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    function setRoyalty(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyCurrentContract {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }
}
