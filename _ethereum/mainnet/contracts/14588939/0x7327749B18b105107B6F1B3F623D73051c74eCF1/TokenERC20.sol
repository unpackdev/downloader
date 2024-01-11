// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract TokenERC20 is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address private owner;
    bool public paused;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blocklist;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    modifier notBlocked(address _recipient) {
        require(
            !blocklist[msg.sender] && !blocklist[_recipient],
            "You are in blocklist"
        );
        _;
    }

    modifier pausable(address _recipient) {
        if (paused) {
            require(
                whitelist[msg.sender] || whitelist[_recipient],
                "Only whitelisted users can transfer while token paused!"
            );
        }
        _;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override notBlocked(_to) pausable(_to) {
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        _burn(account, amount);
    }

    function setWhitelistStatus(address _user, bool _status)
        public
        onlyRole(ADMIN_ROLE)
    {
        whitelist[_user] = _status;
    }

    function setBlocklistStatus(address _user, bool _status)
        public
        onlyRole(ADMIN_ROLE)
    {
        blocklist[_user] = _status;
    }

    function setPause(bool _state) public onlyRole(ADMIN_ROLE) {
        paused = _state;
    }

    function withdrawToken(address token, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function setOwner(address _newOnwer) external {
        require(msg.sender == owner, "you are not owner");
        owner = _newOnwer;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
