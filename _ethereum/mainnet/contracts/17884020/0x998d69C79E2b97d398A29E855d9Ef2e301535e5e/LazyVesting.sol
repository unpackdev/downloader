// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./draft-EIP712.sol";

/** 
 * @dev {LazyVesting} contract handles the off-chain contributions for ERC20 token. Including:
 *
 *  - an admin role that allows to withdraw tokens leftovers.
 *  - an operator role that grants rights to claim tokens.
 *  - ability for contributors to claim their tokens.
 * 
 * The account that deploys the contract will be granted the `admin` & `operator`
 * roles, as well as the `default admin` role, which will let it grant roles to other accounts.
*/
contract LazyVesting is AccessControlEnumerable, EIP712 {
    /**
     * @dev Emitted when tokens are claimed by `contributor`.
     */
    event Claim(address indexed contributor, uint256 amount, uint256 bonus, uint256 start, uint256 outcome, uint256 leftovers);
   
    /**
     * @dev Emitted when tokens are withdrawn by `admin`.
     */
    event Withdraw(uint256 amount);

    /* Contribution data */
    struct ContributionData {
        address contributor;
        uint256 amount;
        uint256 bonus;
        uint256 outcome;
        uint256 start;
        uint256 timestamp;
        bool executed;
    }

    /* Contribution type hash */
    bytes32 public constant CONTRIBUTION_TYPEHASH = keccak256("Contribution(uint256 id,address contributor,uint256 amount,uint256 start)");

    /* EIP712 domain name */
    string public constant EIP712_DOMAIN_NAME = "LAZY VESTING";

    /* EIP712 domain version */
    string public constant EIP712_DOMAIN_VERSION = "1";

    /* Role to tokenize */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /** Role to add contributions */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /** HardLock duration */
    uint256 public constant HARDLOCK = 120 days;

    /** SoftLock stage duration */
    uint256 public constant SOFTLOCK = 30 days;

    /* The denominator for rates */
    uint96 public constant DENOMINATOR = 10000;

    /* The APY numerator is expressed in basis points. Defaults to 6.66% (20% APY). */
    uint96 public constant APY = 666;

    /* SoftLock first stage numerator is expressed in basis points. Defaults to 30%. */
    uint96 public constant FIRST_PENALTY = 3000;

    /* SoftLock second stage numerator is expressed in basis points. Defaults to 20%. */
    uint96 public constant SECOND_PENALTY = 2000;
    
    /* SoftLock third stage numerator is expressed in basis points. Defaults to 10%. */
    uint96 public constant THIRD_PENALTY = 1000;

    /** Claimed contributions by id */
    mapping (uint256 => ContributionData) private _contributions;

     /* Penalty leftovers vault */
    address private immutable _vault;

     /* Contribution token */
    address private immutable _token;    

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(address token_, address vault_) EIP712(EIP712_DOMAIN_NAME, EIP712_DOMAIN_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        require(token_ != address(0), "Vesting: token is the zero address");
        require(vault_ != address(0), "Vesting: vault is the zero address");

        _token = token_;
        _vault = vault_;
    }

    /**
     * @dev Returns version of the contract instance.
     */
    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Returns the chain id of the current blockchain.
     */
    function getChainID() external view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns contribution token address.
     */
    function token() public view returns (address) {
        return _token;
    }

    /**
     * @dev Returns the penalty leftovers vault address.
     */
    function vault() public view returns (address) {
        return _vault;
    }
    /**
     * @dev Returns contribution by `id`.
     */
    function getContributionById(uint id) external view returns(ContributionData memory contribution) {
        return _contributions[id];
    }

    /**
     * @dev Returns the address that signed `contribution` with `signature` field.
     */  
    function recover(uint256 id, address contributor, uint256 amount, uint256 start, bytes calldata signature) external view returns (address) {
        return _recover(id, contributor, amount, start, signature);
    }

    /**
     * @dev Returns a hash of the `contribution`, prepared using EIP712 typed data hashing rules.
     */
    function _hash(uint256 id, address contributor, uint256 amount, uint256 start) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            CONTRIBUTION_TYPEHASH,
            id,
            contributor,
            amount,
            start
        )));
    }

    /**
     * @dev See {ECDSA-recover}.
     */
    function _recover(uint256 id, address contributor, uint256 amount, uint256 start, bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hash(id, contributor, amount, start);
        return ECDSA.recover(digest, signature);
    }

    /**
     * @dev Withdraw contributor tokens by contribution `id`, `contributor`, `amount` & `start` date.
     * 
     * - `signature`: The EIP-712 signature of `contribution`. It must be signed by an account with the OPERATOR_ROLE.
     * 
     * Emits a {Withdraw} event.
     */
    function claimContribution(uint256 id, address contributor, uint256 amount, uint256 start, bytes calldata signature) external {
        address signer = _recover(id, contributor, amount, start, signature);

        require(hasRole(OPERATOR_ROLE, signer), "Vesting: signature invalid or unauthorized");

        uint256 bonus = amount * APY / DENOMINATOR;
        uint256 hardlock = start + HARDLOCK;

        ContributionData storage contribution = _contributions[id];

        require(!contribution.executed, "Vesting: contribution is already executed");
        require(hardlock < block.timestamp, "Vesting: current time is before hardlock");
        require(contributor == msg.sender, "Vesting: contributor is not the message sender");
        
        uint256 outcome;
        uint256 total = amount + bonus;

        if (start + HARDLOCK + 3 * SOFTLOCK < block.timestamp) {
            outcome = total;
        } else if (start + HARDLOCK + 2 * SOFTLOCK < block.timestamp) {
            outcome = total - total * THIRD_PENALTY / DENOMINATOR;
        } else if (start + HARDLOCK + SOFTLOCK < block.timestamp) {
            outcome = total - total * SECOND_PENALTY / DENOMINATOR;
        } else {
            outcome = total - total * FIRST_PENALTY / DENOMINATOR;
        }

        uint256 leftovers = total - outcome;

        _contributions[id] = ContributionData(contributor, amount, bonus, outcome, start, block.timestamp, true);

        IERC20(_token).transfer(contributor, outcome);
        IERC20(_token).transfer(_vault, leftovers);

        emit Claim(contributor, amount, bonus, start, outcome, leftovers);
    }

    /**
     * @dev Withdraw tokens leftovers by admin.
     * 
     * Emits a {Withdraw} event.
     */
    function withdraw(uint256 amount) onlyRole(ADMIN_ROLE) external {
        IERC20(_token).transfer(_vault, amount);

        emit Withdraw(amount);
    }
}