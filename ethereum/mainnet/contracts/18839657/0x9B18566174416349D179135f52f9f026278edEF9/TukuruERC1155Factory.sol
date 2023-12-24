// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./TukuruERC1155.sol";

contract TukuruERC1155ContractFactory is AccessControl, Ownable {
    using Clones for address;

    bytes32 public constant ADMIN = "ADMIN";

    event Created(address indexed contractAddress, address indexed owner, string name, string symbol, bool isLocked, uint96 royaltyFee, address withdrawAddress, uint256 systemRoyalty, address royaltyReceiver);

    uint256 public usageFee = 0.1 ether;
    uint256 public systemRoyalty = 5;
    address public royaltyReceiver = 0x1476468886C76575CdB78b2cCBa37eAd1b3ea181;

    // Constructor
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    // Setter
    function setUsageFee(uint256 _value) external onlyRole(ADMIN) {
        usageFee = _value;
    }
    function setSystemRoyalty(uint256 _value) external onlyRole(ADMIN) {
        systemRoyalty = _value;
    }
    function setRoyaltyReceiver(address _value) external onlyRole(ADMIN) {
        royaltyReceiver = _value;
    }

    // Factory
    function createWithPayment(
        string memory _name,
        string memory _symbol,
        bool _isLocked,
        uint96 _royaltyFee,
        address _withdrawAddress
    ) external payable {
        require(usageFee > 0, "No Usage Fee");
        require(msg.value >= usageFee, "Not Enough Eth");
        address clone = address(new TukuruERC1155());
        TukuruERC1155(clone).initialize(
            msg.sender,
            _name,
            _symbol,
            _isLocked,
            _royaltyFee,
            _withdrawAddress,
            0,
            royaltyReceiver
        );
        emit Created(clone, msg.sender, _name, _symbol, _isLocked, _royaltyFee, _withdrawAddress, 0, royaltyReceiver);
    }

    function createWithSystemRoyalty(
        string memory _name,
        string memory _symbol,
        bool _isLocked,
        uint96 _royaltyFee,
        address _withdrawAddress
    ) external {
        address clone = address(new TukuruERC1155());
        TukuruERC1155(clone).initialize(
            msg.sender,
            _name,
            _symbol,
            _isLocked,
            _royaltyFee,
            _withdrawAddress,
            systemRoyalty,
            royaltyReceiver
        );
        emit Created(clone, msg.sender, _name, _symbol, _isLocked, _royaltyFee, _withdrawAddress, systemRoyalty, royaltyReceiver);
    }
}