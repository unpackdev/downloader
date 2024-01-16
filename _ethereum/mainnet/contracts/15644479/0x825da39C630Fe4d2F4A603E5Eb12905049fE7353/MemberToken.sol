// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";

contract MemberToken is Initializable, UUPSUpgradeable, ERC20VotesUpgradeable {
    address public minter;
    address public dao;

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao, "Not dao");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        address _minter,
        string memory _name,
        string memory _symbol
    ) external initializer {
        require(_minter != address(0), "minter is null");
        minter = _minter;
        dao = msg.sender;
        __ERC20Permit_init(_name);
        __ERC20_init(_name, _symbol);
    }

    function mint(
        address account,
        uint256 amount
    ) external onlyMinter {
        _mint(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);

        _delegate(to, to);
    }

    function getPastTotalSupply(uint256 blockNumber) public view override returns (uint256) {
        return super.getPastTotalSupply(blockNumber) - super.getPastVotes(minter, blockNumber);
    }

    function getPastVotes(address account, uint256 blockNumber) public view override returns (uint256) {
        if(account == minter) return 0;
        return super.getPastVotes(account, blockNumber);
    }

    function getVotes(address account) public view virtual override returns (uint256) {
        if(account == minter) return 0;
        return super.getVotes(account);
    }

    function delegate(address) public virtual override {
        revert("Not support delegate Vote");
    }
    function delegateBySig(
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) public virtual override {
        revert("Not support delegate Vote");
    }

    function _authorizeUpgrade(address) internal view override onlyDao {}

    uint256[50] private __gap;
}