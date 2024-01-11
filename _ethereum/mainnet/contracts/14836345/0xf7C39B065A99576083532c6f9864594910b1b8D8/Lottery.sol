// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";

import "./RequestValidator.sol";

// ██╗  ██╗██╗██████╗ ███████╗ ██████╗ ██╗   ██╗████████╗    ██╗      █████╗ ██████╗ ███████╗
// ██║  ██║██║██╔══██╗██╔════╝██╔═══██╗██║   ██║╚══██╔══╝    ██║     ██╔══██╗██╔══██╗██╔════╝
// ███████║██║██║  ██║█████╗  ██║   ██║██║   ██║   ██║       ██║     ███████║██████╔╝███████╗
// ██╔══██║██║██║  ██║██╔══╝  ██║   ██║██║   ██║   ██║       ██║     ██╔══██║██╔══██╗╚════██║
// ██║  ██║██║██████╔╝███████╗╚██████╔╝╚██████╔╝   ██║       ███████╗██║  ██║██████╔╝███████║
// ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝    ╚═╝       ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
/// @title  Lottery
/// @dev    v1.2
/// @author kemimeister | hideoutlabs (https://www.twitter.com/hideoutlabs)

contract Lottery is AccessControl, ReentrancyGuard, RequestValidator {
    event EnteredDraw(
        address indexed wallet,
        uint256 amount,
        uint256 indexed lotteryId,
        uint256 totalPrice
    );

    uint256 public entryPrice;
    address public beneficiary;
    ERC20 private Ammolite;
    bool public isOpen;
    address public operator;
    address public defaultAdmin;

    mapping(address => uint256) private nonces;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier verifyEntryRequest(
        uint256 _lottery,
        uint256 _numberOfEntries,
        uint256 _expiryTime,
        bytes memory _signature
    ) {
        require(isOpen, "Lottery is closed");
        require(_expiryTime >= block.timestamp, "Request expired");
        _;
        bytes32 inputsHash = keccak256(
            abi.encode(
                operator,
                msg.sender,
                address(this),
                _lottery,
                _numberOfEntries,
                _expiryTime,
                nonces[msg.sender]
            )
        );
        require(
            verifySignatureSource(operator, inputsHash, _signature),
            "Unauthorised request"
        );
        _;
    }

    constructor() {
        beneficiary = address(this);
        operator = 0x3F2F8b5582a01442a746bF976E7F2B7E1c3aF21C;
        defaultAdmin = 0xAE2573d714D4df7DB925776aCF90065BBc12531A;
        Ammolite = ERC20(0xBcB6112292a9EE9C9cA876E6EAB0FeE7622445F1);
        entryPrice = 100 * 10**18;
        isOpen = true;
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _setupRole(MANAGER_ROLE, defaultAdmin);
    }

    function setAmmoliteContract(address _ammolite)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Ammolite = ERC20(_ammolite);
    }

    function enterDraw(
        uint256 _numberOfEntries,
        uint256 _expiryTime,
        uint256 _lotteryId,
        bytes memory _signature
    )
        external
        nonReentrant
        verifyEntryRequest(
            _lotteryId,
            _numberOfEntries,
            _expiryTime,
            _signature
        )
    {
        require(
            Ammolite.balanceOf(msg.sender) >= entryPrice * _numberOfEntries,
            "Not enough Ammo"
        );
        nonces[msg.sender]++;
        uint256 totalPrice = entryPrice * _numberOfEntries;
        Ammolite.transferFrom(msg.sender, beneficiary, totalPrice);
        emit EnteredDraw(msg.sender, _numberOfEntries, _lotteryId, totalPrice);
    }

    function toggleOpen() external onlyRole(MANAGER_ROLE) {
        isOpen = !isOpen;
    }

    function withdrawAmmolite() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Ammolite.transfer(msg.sender, Ammolite.balanceOf(address(this)));
    }

    function setBeneficiary(address _beneficiary)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        beneficiary = _beneficiary;
    }

    function setOperator(address _operator) external onlyRole(MANAGER_ROLE) {
        operator = _operator;
    }

    function getNonce(address wallet) external view returns (uint256) {
        return nonces[wallet];
    }

    function setEntryPrice(uint256 _entryPrice)
        external
        onlyRole(MANAGER_ROLE)
    {
        entryPrice = _entryPrice;
    }
}
