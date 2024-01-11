// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Errors.sol";
import "./ERC20LockerUpgradeable.sol";
import "./UncheckedIncrement.sol";

contract CAFE is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20LockerUpgradeable
{
    using UncheckedIncrement for uint256;

    event AccountFunded(address indexed account, uint256 indexed amount);
    event SudoApproverSet(address indexed account, bool indexed newState);

    uint256 public constant ALLOC_TOTAL = 900_000_000 ether;

    // 44.5% of ALLOC_TOTAL
    uint256 public constant ALLOC_STAKING = (445 * ALLOC_TOTAL) / 1000;
    // 12.5% of ALLOC_TOTAL (7.5+5)
    uint256 public constant ALLOC_VESTING = (125 * ALLOC_TOTAL) / 1000;
    // 10.0% of ALLOC_TOTAL
    uint256 public constant ALLOC_FUTURE = ALLOC_TOTAL / 10;
    // 7.5% of ALLOC_TOTAL
    uint256 public constant ALLOC_TEAM = (75 * ALLOC_TOTAL) / 1000;
    // 25% of ALLOC_TOTAL
    uint256 public constant ALLOC_BREWHOUSE = ALLOC_TOTAL / 4;
    // 0.5% of ALLOC_TOTAL
    uint256 public constant COMMUNITY = ALLOC_TOTAL / 200;

    uint256 public communitySupply;
    bool public fundingDone;

    mapping(address => bool) public sudoApprovers;

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init("Soul Cafe Token", "$CAFE");
        ERC20LockerUpgradeable.__init();
    }

    function setLockerAdmin(address admin) external {
        _onlyOwner();
        _setLockerAdmin(admin);
    }

    function setSudoApprover(address approver, bool state) external {
        _onlyOwner();
        emit SudoApproverSet(approver, state);
        sudoApprovers[approver] = state;
    }

    function sudoLimitedApprove(address account, uint256 amount) external {
        _onlySudoApprovers();

        uint256 currentAllowance = allowance(account, msg.sender);

        if (currentAllowance < amount) {
            _approve(account, msg.sender, currentAllowance + amount);
        }
    }

    function fund(
        address staking,
        address vesting,
        address team,
        address future,
        address brewhouse
    ) external {
        _onlyOwner();
        if (fundingDone) revert OnceOnly();
        fundingDone = true;

        _dispense(staking, ALLOC_STAKING);
        _dispense(vesting, ALLOC_VESTING);
        _dispense(team, ALLOC_TEAM);
        _dispense(future, ALLOC_FUTURE);
        _dispense(brewhouse, ALLOC_BREWHOUSE);
    }

    function airdrop(address[] calldata to, uint256[] calldata amounts)
        external
    {
        _onlyOwner();
        if (to.length != amounts.length) revert InvalidArrayLength();

        for (uint256 i = 0; i < to.length; i = i.inc()) {
            if (to[i] != address(0)) {
                uint256 amount = amounts[i] * 1e18;
                if (communitySupply + amount > COMMUNITY)
                    revert MintingExceedsSupply(COMMUNITY);
                communitySupply += amount;

                _dispense(to[i], amount);
            }
        }
    }

    function _dispense(address account, uint256 amount) internal {
        if (totalSupply() + amount > ALLOC_TOTAL)
            revert MintingExceedsSupply(ALLOC_TOTAL);
        emit AccountFunded(account, amount);
        _mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        to;
        if (from == address(0)) return;

        if (balanceOf(from) - locked(from) < amount) revert InsufficientCAFE();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _onlySudoApprovers() internal view {
        if (!sudoApprovers[msg.sender]) revert Unauthorized();
    }
}