// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./IMinter.sol";

/** 
 * @title ETH (or other gascoin) native swap for a fixed exchanged rate for whitelisted wallets.
 *
 * @dev Collect gas coin in exchange of ERC20 by a fixed rate,
 * save metadata (KYC signature) as part of transaction.
 *
 * whitelisting code and EIP-712 is stolen from Gnosis IDO contracts: 
 * https://github.com/gnosis/ido-contracts/blob/8427e9f2de730fab837db67bc3b00abddb84b0b3/contracts/allowListExamples/AllowListOffChainManaged.sol
 */
contract NativeSwap is AccessControlEnumerable, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Value returned by a call to `isAllowed` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("isAllowed(address,bytes)"))
    bytes4 internal constant MAGICVALUE = 0xe3f756de;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant DOMAIN_NAME = keccak256("AccessManager");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant DOMAIN_VERSION = keccak256("v1");

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable DOMAIN_SEPARATOR;

    address payable public immutable BENEFICIARY;
    IMinter public immutable VENDOR_TOKEN;

    uint public exchangeRate;
    uint public exchangeBase;
    uint public bonusExchangeRate;

    bytes32 public bonusCodeHash = 0x5fcc1a9aad6c24111f44346c75d2f0da9cdbe0cc4d473b8bc1452e54a304746d;
    bytes public kycSignerData;

    event Contribution(
        address indexed from,
        address vendorToken,
        uint256 contributed,
        uint256 recieved,
        bytes32 ref,
        bytes32 bonus,
        bytes signature
    );

    modifier isPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role");
        _;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        _;
    }

    /** 
     * @dev Setup seed token.
     */
    constructor(
        address _admin,
        address payable _beneficiary,
        address _vendorToken,
        uint _exchangeRate,
        uint _exchangeBase,
        uint _bonusExchangeRate,
        bytes memory _kycSignerData
    ) {
        BENEFICIARY = _beneficiary;
        VENDOR_TOKEN = IMinter(_vendorToken);

        exchangeRate = _exchangeRate;
        exchangeBase = _exchangeBase;
        bonusExchangeRate = _bonusExchangeRate;

        kycSignerData = _kycSignerData;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _msgSender());

        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Exchange gas coin for VENDOR_TOKEN by a fixed exchangeRate.
     *
     * @param _ref Reference to terms.
     * @param _bonusHash Discount code.
     * @param _callData Digest of signed wallets.
     */
    function contribute(bytes32 _ref, bytes32 _bonusHash, bytes calldata _callData) external payable whenNotPaused {
        address _sender = _msgSender();

        require(isAllowed(_sender, _callData) == MAGICVALUE, "not whitelisted wallet");
        BENEFICIARY.transfer(msg.value);

        uint _recieveAmount = getVendorTokenAmount(msg.value, _bonusHash);
        VENDOR_TOKEN.mint(_sender, _recieveAmount);
        emit Contribution(_sender, address(VENDOR_TOKEN), msg.value, _recieveAmount, _ref, _bonusHash, _callData);
    }

    /**
     * @dev Estimate amount VENDOR_TOKEN from a given amount of gas coin.
     *
     * @param _amount Gas coin amount to exchange.
     * @param _bonusHash Discount code hash.
     * @return amount of VENDOR_TOKEN to be given.
     */
    function getVendorTokenAmount(uint _amount, bytes32 _bonusHash) public view returns(uint) {
        if (_bonusHash == bonusCodeHash) {
            return _amount / bonusExchangeRate * exchangeBase;
        } else {
            return _amount / exchangeRate * exchangeBase;
        }
    }

    /**
     * @dev Get amount of gas coin which was contributed for VENDOR_TOKEN from a given address.
     * will be wrong if rate has changed, use Contribution event for precise data.
     *
     * @param _address Address which contribution is checked.
     * @param _bonusHash Discount code hash.
     * @return amount of gas coin which was already contributed.
     */
    function getContributedAmount(address _address, bytes32 _bonusHash) public view returns(uint) {
        if (_bonusHash == bonusCodeHash) {
            return VENDOR_TOKEN.balanceOf(_address) * bonusExchangeRate / exchangeBase;
        } else {
            return VENDOR_TOKEN.balanceOf(_address) * exchangeRate / exchangeBase;
        }
    }

    /**
     * @dev Checks if user is whitelisted wallet.
     *
     * @param user Address to check for whitelisting.
     * @param callData Digest of signed wallets.
     * @return 0xe3f756de for success 0x00000000 for failure.
     */
    function isAllowed(
        address user,
        bytes calldata callData
    ) public view returns (bytes4) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = abi.decode(callData, (uint8, bytes32, bytes32));
        bytes32 hash = keccak256(abi.encode(getDomainSeparator(), user));
        address signer =
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                v,
                r,
                s
            );

        if (abi.decode(kycSignerData, (address)) == signer) {
            return MAGICVALUE;
        } else {
            return bytes4(0);
        }
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getDomainSeparator() public virtual view returns(bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @dev Pauses all trades.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external isPauser {
        _pause();
    }

    /**
     * @dev Unpauses all trades.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external isPauser {
        _unpause();
    }

    /**
     * @dev Update payment token and exchange rate.
     *
     * @param _exchangeRate Amount of seed tokens given for 1 contributed gas coin against the _exchangeBase.
     * @param _exchangeBase Base for exchange as floats are not supported in Solidity yet.
     * @param _bonusExchangeRate Bonus exchange rate for discount code owners.
     */
    function changeExchangeRate(
        uint _exchangeRate,
        uint _exchangeBase,
        uint _bonusExchangeRate
    ) external isAdmin {
        exchangeRate = _exchangeRate;
        exchangeBase = _exchangeBase;
        bonusExchangeRate = _bonusExchangeRate;
    }

    /**
     * @dev Update whitelisting wallet.
     *
     * @param _kycSignerData Digest of comma separated whitelisted wallets.
     */
    function updateKycSigner(
        bytes memory _kycSignerData
    ) external isAdmin {
        kycSignerData = _kycSignerData;
    }

    /**
     * @dev Update discount code.
     *
     * @param _bonusCodeHash Hash of discount code.
     */
    function updateBonusCodeHash(bytes32  _bonusCodeHash) external isAdmin {
        bonusCodeHash = _bonusCodeHash;
    }
}