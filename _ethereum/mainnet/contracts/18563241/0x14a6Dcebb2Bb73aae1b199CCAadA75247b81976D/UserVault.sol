// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Owned.sol";
import "./ERC721.sol";
import "./SafeTransferLib.sol";

import "./AddressManager.sol";
import "./IUserVault.sol";

/// @title Auction Loan Liquidator
/// @author Florida St
/// @notice NFTs that represent bundles.
contract UserVault is ERC721, ERC721TokenReceiver, IUserVault, Owned {
    using SafeTransferLib for ERC20;

    string private constant _BASE_URI = "https://gondi.xyz/user_vaults/";
    uint256 private _nextId = 0;

    address public constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice IDs that were burnt are pending withdrawal
    mapping(uint256 => address) _readyForWithdrawal;

    /// @notice NFT balances for a given vault: collection => (tokenId => vaultId)
    mapping(address => mapping(uint256 => uint256)) _vaultERC721s;

    /// @notice ERC20 balances for a given vault: token => (vaultId => amount). address(0) = ETH
    mapping(address => mapping(uint256 => uint256)) _vaultERC20s;

    AddressManager private immutable _currencyManager;

    AddressManager private immutable _collectionManager;

    event ERC721Deposited(uint256 vaultId, address collection, uint256 tokenId);

    event ERC20Deposited(uint256 vaultId, address token, uint256 amount);

    event ERC721Withdrawn(uint256 vaultId, address collection, uint256 tokenId);

    event ERC20Withdrawn(uint256 vaultId, address token, uint256 amount);

    error CurrencyNotWhitelistedError();

    error CollectionNotWhitelistedError();

    error LengthMismatchError();

    error NotApprovedError(uint256 vaultId);

    error WithdrawingETHError();

    error WrongMethodError();

    error AssetNotOwnedError();

    error VaultNotExistsError(uint256 vaultId);

    modifier onlyApproved(uint256 _vaultId) {
        if (
            msg.sender != ownerOf(_vaultId) && !isApprovedForAll[ownerOf(_vaultId)][msg.sender]
                && getApproved[_vaultId] != msg.sender
        ) {
            revert NotApprovedError(_vaultId);
        }
        _;
    }

    modifier onlyReadyForWithdrawal(uint256 _vaultId) {
        if (_readyForWithdrawal[_vaultId] != msg.sender) {
            revert NotApprovedError(_vaultId);
        }
        _;
    }

    modifier vaultExists(uint256 _vaultId) {
        if (_ownerOf[_vaultId] == address(0)) {
            revert VaultNotExistsError(_vaultId);
        }
        _;
    }

    /// @param currencyManager Address of the CurrencyManager contract.
    /// @param collectionManager Address of the CollectionManager contract.
    constructor(address currencyManager, address collectionManager)
        ERC721("GONDI_USER_VAULT", "GUV")
        Owned(tx.origin)
    {
        _currencyManager = AddressManager(currencyManager);
        _collectionManager = AddressManager(collectionManager);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 _vaultId) public pure override returns (string memory) {
        return string.concat(_BASE_URI, Strings.toString(_vaultId));
    }

    /// @inheritdoc IUserVault
    function mint() external returns (uint256) {
        uint256 _vaultId;
        unchecked {
            _vaultId = ++_nextId;
        }
        _mint(msg.sender, _vaultId);
        return _vaultId;
    }

    /// @inheritdoc IUserVault
    function burn(uint256 _vaultId, address _assetRecipient) external {
        _thisBurn(_vaultId, _assetRecipient);
    }

    /// @inheritdoc IUserVault
    function burnAndWithdraw(
        uint256 _vaultId,
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        address[] calldata _tokens
    ) external {
        _thisBurn(_vaultId, msg.sender);
        for (uint256 i = 0; i < _collections.length;) {
            _withdrawERC721(_vaultId, _collections[i], _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < _tokens.length;) {
            _withdrawERC20(_vaultId, _tokens[i]);
            unchecked {
                ++i;
            }
        }
        _withdrawEth(_vaultId);
    }

    function ERC721OwnerOf(address _collection, uint256 _tokenId) external view returns (uint256) {
        return _vaultERC721s[_collection][_tokenId];
    }

    function ERC20BalanceOf(uint256 _vaultId, address _token) external view returns (uint256) {
        return _vaultERC20s[_token][_vaultId];
    }

    /// @inheritdoc IUserVault
    function depositERC721(uint256 _vaultId, address _collection, uint256 _tokenId) external vaultExists(_vaultId) {
        if (!_collectionManager.isWhitelisted(_collection)) {
            revert CollectionNotWhitelistedError();
        }
        _depositERC721(msg.sender, _vaultId, _collection, _tokenId);
    }

    /// @inheritdoc IUserVault
    /// @dev Read `depositERC721`.
    function depositERC721s(uint256 _vaultId, address _collection, uint256[] calldata _tokenIds)
        external
        vaultExists(_vaultId)
    {
        if (!_collectionManager.isWhitelisted(_collection)) {
            revert CollectionNotWhitelistedError();
        }
        for (uint256 i = 0; i < _tokenIds.length;) {
            _depositERC721(msg.sender, _vaultId, _collection, _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUserVault
    /// @dev Read `depositERC721`.
    function depositERC20(uint256 _vaultId, address _token, uint256 _amount) external vaultExists(_vaultId) {
        if (_token == ETH) {
            revert WrongMethodError();
        }
        _depositERC20(msg.sender, _vaultId, _token, _amount);
    }

    /// @inheritdoc IUserVault
    /// @dev Read `depositERC721`.
    function depositEth(uint256 _vaultId) external payable vaultExists(_vaultId) vaultExists(_vaultId) {
        _vaultERC20s[ETH][_vaultId] += msg.value;

        emit ERC20Deposited(_vaultId, ETH, msg.value);
    }

    /// @inheritdoc IUserVault
    function withdrawERC721(uint256 _vaultId, address _collection, uint256 _tokenId) external {
        _withdrawERC721(_vaultId, _collection, _tokenId);
    }

    /// @inheritdoc IUserVault
    function withdrawERC721s(uint256 _vaultId, address[] calldata _collections, uint256[] calldata _tokenIds)
        external
    {
        if (_collections.length != _tokenIds.length) {
            revert LengthMismatchError();
        }
        for (uint256 i = 0; i < _collections.length;) {
            _withdrawERC721(_vaultId, _collections[i], _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUserVault
    function withdrawERC20(uint256 _vaultId, address _token) external {
        _withdrawERC20(_vaultId, _token);
    }

    /// @inheritdoc IUserVault
    function withdrawERC20s(uint256 _vaultId, address[] calldata _tokens) external {
        for (uint256 i = 0; i < _tokens.length;) {
            _withdrawERC20(_vaultId, _tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUserVault
    function withdrawEth(uint256 _vaultId) external {
        _withdrawEth(_vaultId);
    }

    function _depositERC721(address _depositor, uint256 _vaultId, address _collection, uint256 _tokenId) private {
        ERC721(_collection).transferFrom(_depositor, address(this), _tokenId);

        _vaultERC721s[_collection][_tokenId] = _vaultId;

        emit ERC721Deposited(_vaultId, _collection, _tokenId);
    }

    function _depositERC20(address _depositor, uint256 _vaultId, address _token, uint256 _amount) private {
        if (!_currencyManager.isWhitelisted(_token)) {
            revert CurrencyNotWhitelistedError();
        }
        ERC20(_token).safeTransferFrom(_depositor, address(this), _amount);

        _vaultERC20s[_token][_vaultId] += _amount;
        emit ERC20Deposited(_vaultId, _token, _amount);
    }

    /// @dev We are allowing anyone to deposit NFTs into a vault (not just the owner). Because of this we call transferFrom
    /// and not safeTransferFrom to avoid someone locking assets by transferring an ERC721 with the hook corrupted (we do
    /// have a whitelist to avoid this but being extra cautious.)
    function _withdrawERC721(uint256 _vaultId, address _collection, uint256 _tokenId)
        private
        onlyReadyForWithdrawal(_vaultId)
    {
        if (_vaultERC721s[_collection][_tokenId] != _vaultId) {
            revert AssetNotOwnedError();
        }
        ERC721(_collection).transferFrom(address(this), msg.sender, _tokenId);

        delete _vaultERC721s[_collection][_tokenId];

        emit ERC721Withdrawn(_vaultId, _collection, _tokenId);
    }

    function _withdrawERC20(uint256 _vaultId, address _token) private onlyReadyForWithdrawal(_vaultId) {
        uint256 amount = _vaultERC20s[_token][_vaultId];
        if (amount == 0) {
            return;
        }
        delete _vaultERC20s[_token][_vaultId];

        ERC20(_token).safeTransfer(msg.sender, amount);

        emit ERC20Withdrawn(_vaultId, _token, amount);
    }

    function _thisBurn(uint256 _vaultId, address _assetRecipient) private onlyApproved(_vaultId) {
        _burn(_vaultId);
        _readyForWithdrawal[_vaultId] = _assetRecipient;
    }

    function _withdrawEth(uint256 _vaultId) private onlyReadyForWithdrawal(_vaultId) {
        uint256 amount = _vaultERC20s[ETH][_vaultId];
        if (amount == 0) {
            return;
        }
        delete _vaultERC20s[ETH][_vaultId];

        (bool sent,) = payable(msg.sender).call{value: amount}("");
        if (!sent) {
            revert WithdrawingETHError();
        }

        emit ERC20Withdrawn(_vaultId, ETH, amount);
    }
}
