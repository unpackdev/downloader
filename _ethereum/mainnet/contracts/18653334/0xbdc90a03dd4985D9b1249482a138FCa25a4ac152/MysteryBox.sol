//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IMackerel.sol";

contract MysteryBox is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    bytes32 private constant RANDOMNESS_REPLIER = keccak256("RANDOMNESS_REPLIER");

    IMackerel private _mackerel;
    uint256 _price;
    mapping(address => uint256) private lastBlockNumberCalled;

    function initialize(address Mackerel_, uint256 price_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _mackerel = IMackerel(Mackerel_);
        _price = price_;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function setMackerel(address Mackerel_) external onlyRole(ADMIN_ROLE) {
        _mackerel = IMackerel(Mackerel_);
    }

    function setPrice(uint256 price_) external onlyRole(ADMIN_ROLE) {
        _price = price_;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function openBox() external payable whenNotPaused onlyNonContract oncePerBlock(_msgSender()) returns (uint256) {
        require(_price > 0 && msg.value >= _price, "not enough money");
        return _mackerel.safeMint(_msgSender());
    }

    function withdrawAll(address addr) external onlyRole(WITHDRAWER) {
        address payable _to = payable(addr);
        _to.transfer(address(this).balance);
    }

    function withdraw(address addr, uint256 amount) external onlyRole(WITHDRAWER) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "invalid amount");
        address payable _to = payable(addr);
        _to.transfer(amount);
    }

    //////////////
    /// Modifiers
    //////////////
    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == _msgSender(), "only non contract");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "one per block");
        lastBlockNumberCalled[user] = block.number;
    }
}
