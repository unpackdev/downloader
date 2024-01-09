// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports: Inherited Contracts ============
import "./ERC20VotesComp.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20.sol";

/*
Party Token
by Anna Carroll
*/
contract PartyToken is ERC20VotesComp {
    // ============ Immutables ============

    address public immutable partyDAOMultisig;
    address public immutable deprecationContract;

    // ============ State ============

    bool isUnlocked;

    // ============ Events ============

    event Unlocked();

    // ======== Constructor =========

    constructor(address _partyDAOMultisig, address _deprecationContract) ERC20("Party", "PARTY") ERC20Permit("Party") {
        // set partyDAO multisig & deprecation contract addresses
        partyDAOMultisig = _partyDAOMultisig;
        deprecationContract = _deprecationContract;
        // mint 100M totalSupply to partyDAO multisig
        _mint(_partyDAOMultisig, 100_000_000 * (10 ** 18));
    }

    // ======== External Functions =========

    function unlock() external {
        require(msg.sender == partyDAOMultisig, "only partyDAO");
        require(!isUnlocked, "already unlocked");
        isUnlocked = true;
        emit Unlocked();
    }

    // ======== Public Functions =========

    /**
     * @dev See {IERC20-transfer}.
     * Requirements:
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - the contract must be unlocked,
     *   unless called by PartyDAO multisig or deprecation contract
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isUnlocked || msg.sender == deprecationContract || msg.sender == partyDAOMultisig, "in lockup");
        super.transfer(recipient, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     * - the contract must be unlocked
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(isUnlocked || sender == partyDAOMultisig, "in lockup");
        super.transferFrom(sender, recipient, amount);
    }
}
