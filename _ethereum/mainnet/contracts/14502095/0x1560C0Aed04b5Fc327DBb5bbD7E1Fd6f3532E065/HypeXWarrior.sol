//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract HypeXWarrior is ERC1155SupplyUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    string public name;
    string public code;
    bool public isCodeValuable;

    uint256 public priceForW;
    uint256 public priceForNW;

    address public operator;
    uint256 public countOfUse;
    uint256 public maxSupply;
    string public _uri;
    mapping(address => bool) public whitelistedRecipients;

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Warrior: PERMISSION_DENIED");
        _;
    }

    function initialize(string memory name_) public initializer {
        __ERC1155Supply_init();
        __ERC1155_init("");
        __Ownable_init();
        __ReentrancyGuard_init();

        name = name_;
        maxSupply = 500;
        priceForW = 1e17;
        priceForNW = 15e16;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Warrior: WITHDRAW_FAILED");
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Warrior: INVALID_OPERATOR");
        operator = newOperator;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwnerOrOperator {
        require(newMaxSupply >= totalSupply(1), "Warrior: ALREADY_MINTED_OVER");
        maxSupply = newMaxSupply;
    }

    function setPresetCode(string memory code_, bool valuable) external onlyOwnerOrOperator {
        code = code_;
        isCodeValuable = valuable;
    }

    function setWhitelistedRecipients(address[] calldata recipients, bool[] calldata approved)
        external
        onlyOwnerOrOperator
    {
        for (uint256 i; i < recipients.length; i++)
            whitelistedRecipients[recipients[i]] = approved[i];
    }

    function setPriceForW(uint256 newPrice) external onlyOwnerOrOperator {
        priceForW = newPrice;
    }

    function setPriceForNW(uint256 newPrice) external onlyOwnerOrOperator {
        priceForNW = newPrice;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function mintWithCode(string memory code_) external nonReentrant {
        require(false, "Warrior: DISABLED_FEATURE");
        require(isCodeValuable && countOfUse < 200, "Warrior: CODE_DISABLED");
        require(compareStrings(code, code_), "Warrior: INVALID_CODE");
        require(totalSupply(1) < maxSupply, "Warrior: INSUFFICIENT_AMOUNT");
        require(balanceOf(msg.sender, 1) < 2, "Warrior: OVERFLOW_BALANCE");

        countOfUse += 1;
        _mint(msg.sender, 1, 1, "");
    }

    function mint() external payable nonReentrant {
        require(
            msg.value == (whitelistedRecipients[msg.sender] ? priceForW : priceForNW),
            "Warrior: INCORRECT_PRICE"
        );
        require(totalSupply(1) < maxSupply, "Warrior: INSUFFICIENT_AMOUNT");
        require(balanceOf(msg.sender, 1) < 2, "Warrior: OVERFLOW_BALANCE");

        _mint(msg.sender, 1, 1, "");
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwnerOrOperator
    {
        require(recipients.length == amounts.length, "Warrior: INVALID_ARGUMENTS");
        for (uint256 i; i < recipients.length; i += 1) {
            _mint(recipients[i], 1, amounts[i], "");
        }
    }

    function setURI(string memory uri_) external onlyOwnerOrOperator {
        _uri = uri_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uri;
    }
}
