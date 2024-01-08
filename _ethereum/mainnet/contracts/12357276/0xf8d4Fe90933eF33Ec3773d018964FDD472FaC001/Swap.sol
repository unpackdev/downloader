// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./IMinter.sol";

/** 
 * @title Simple ERC20 swap for a fixed exchanged rate for whitelisted wallets.
 *
 * @dev Collect ERC20 payment token in exchange of another ERC20 by a fixed rate,
 * save metadata (KYC signature) as part of transaction.
 *
 * whitelisting code and EIP-712 is stolen from Gnosis IDO contracts: 
 * https://github.com/gnosis/ido-contracts/blob/8427e9f2de730fab837db67bc3b00abddb84b0b3/contracts/allowListExamples/AllowListOffChainManaged.sol
 */
contract Swap is AccessControlEnumerable, Pausable {
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

    address public immutable BENEFICIARY;
    IERC20 public immutable PAYMENT_TOKEN;
    IMinter public immutable VENDOR_TOKEN;
    uint public immutable EXCHANGE_RATE;
    uint public immutable EXCHANGE_BASE = 1000;

    bytes public kycSignerData;
    uint public minContribution = 50000 ether;
    uint public maxContribution = 150000 ether;

    event Contribution(
        address indexed from,
        address paymentToken,
        address vendorToken,
        uint256 contributed,
        uint256 recieved,
        bytes32 ref,
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
        address _beneficiary,
        address _paymentToken,
        address _vendorToken,
        uint _exchangeRate,
        bytes memory _kycSignerData
    ) {
        BENEFICIARY = _beneficiary;
        PAYMENT_TOKEN = IERC20(_paymentToken);
        VENDOR_TOKEN = IMinter(_vendorToken);
        EXCHANGE_RATE = _exchangeRate;
        kycSignerData = _kycSignerData;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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
     * @dev Exchange PAYMENT_TOKEN for VENDOR_TOKEN by EXCHANGE_RATE.
     *
     * @param _amount Total tokens to exchange.
     * @param _ref Reference to terms.
     * @param _callData Digest of signed wallets.
     */
    function contribute(uint _amount, bytes32 _ref, bytes calldata _callData) external whenNotPaused {
        address _sender = _msgSender();

        require(_amount >= minContribution && (_amount + getContributedAmount(_sender)) <= maxContribution, "invalid amount");
        require(isAllowed(_sender, _callData) == MAGICVALUE, "not whitelisted wallet");
        require(PAYMENT_TOKEN.transferFrom(_sender, BENEFICIARY, _amount), "payment failed");

        uint _recieveAmount = getVendorTokenAmount(_amount);
        VENDOR_TOKEN.mint(_sender, _recieveAmount);
        emit Contribution(_sender, address(PAYMENT_TOKEN), address(VENDOR_TOKEN), _amount, _recieveAmount, _ref, _callData);
    }

    /**
     * @dev Estimate amount VENDOR_TOKEN from a given amount of PAYMENT_TOKEN.
     *
     * @param _amount PAYMENT_TOKEN amount to exchange.
     * @return amount of VENDOR_TOKEN to be given.
     */
    function getVendorTokenAmount(uint _amount) public view returns(uint) {
        return _amount / EXCHANGE_RATE * EXCHANGE_BASE;
    }

    /**
     * @dev Get amount of PAYMENT_TOKEN which was contributed for VENDOR_TOKEN from a given address.
     *
     * @param _address Address which contribution is checked.
     * @return amount of PAYMENT_TOKEN which was already contributed.
     */
    function getContributedAmount(address _address) public view returns(uint) {
        return VENDOR_TOKEN.balanceOf(_address) * EXCHANGE_RATE / EXCHANGE_BASE;
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
     * @dev Updated whitelisted wallets.
     *
     * @param _kycSignerData Digest of comma separated whitelisted wallets.
     */
    function updateContractData(
        bytes memory _kycSignerData,
        uint _minContribution,
        uint _maxContribution
    ) external isAdmin {
        kycSignerData = _kycSignerData;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }
}