// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./UUPSProxiable.sol";
import "./Pausable.sol";
import "./IBSVault.sol";

abstract contract VaultStorageV1 is ReentrancyGuard, UUPSProxiable, Pausable, IBSVault {
    struct TotalBase {
        uint256 totalUnderlyingDeposit; // total underlying asset deposit
        uint256 totalSharesMinted; // total vault shares minted
    }

    /// @notice the flashloan rate to charge for flash loans
    uint256 public flashLoanRate;

    /// @notice the address that access to perform `admin` functions
    address public owner;

    /// @dev the address that access to perform `admin` functions
    address public newOwner;

    /// @dev cached domain separator
    bytes32 internal _CACHED_DOMAIN_SEPARATOR;

    /// @notice mapping of token asset to user address and balance
    mapping(IERC20 => mapping(address => uint256)) public override balanceOf;

    /// @notice mapping of user to contract to approval status
    mapping(address => mapping(address => bool)) public userApprovedContracts;

    /// @notice mapping of user to approval nonce
    mapping(address => uint256) public userApprovalNonce;

    /// @notice mapping to contract to whitelist status
    mapping(address => bool) public allowedContracts;

    /// @notice mapping of asset to total deposit and shares minted
    mapping(IERC20 => TotalBase) public totals;
    
}

abstract contract VaultBase is VaultStorageV1  {
    /// @notice vault name
    string public constant name = "WarpVault v1";

    /// @notice vault version
    string public constant version = "1";

    /// @dev vault approval message digest
    bytes32 internal constant _VAULT_APPROVAL_SIGNATURE_TYPE_HASH =
        keccak256(
            "VaultAccessApproval(bytes32 warning,address user,address contract,bool approved,uint256 nonce)"
        );

    /// @dev EIP712 type hash
    bytes32 internal constant _EIP712_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    
    /// @dev ERC3156 constant for flashloan callback success
    bytes32 internal constant FLASHLOAN_CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    
    /// @notice max flashlaon rate 10%
    uint256 public constant MAX_FLASHLOAN_RATE = 1e17;

    /// @dev minimum vault share balance
    uint256 internal constant MINIMUM_SHARE_BALANCE = 1000; // To prevent the ratio going off

    bytes32 internal immutable _HASHED_NAME;
    bytes32 internal immutable _HASHED_VERSION;
    uint256 private immutable _CACHED_CHAIN_ID;


    constructor() {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _CACHED_CHAIN_ID = _getChainId();
    }

    function _buildDomainSeparator(
        bytes32 _typeHash,
        bytes32 _name,
        bytes32 _version
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(_typeHash, _name, _version, _getChainId(), address(this)));
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_EIP712_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _getChainId() private view returns (uint256 chainId) {
        // solhint-disable-next-line
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}
