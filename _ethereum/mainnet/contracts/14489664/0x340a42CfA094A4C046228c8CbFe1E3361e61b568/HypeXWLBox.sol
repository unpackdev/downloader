//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract HypeXWLBox is ERC1155SupplyUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    string public name;
    string public code;
    bool public isCodeValuable;

    address public operator;
    uint256 public countOfUse;
    uint256[] public maxSupplies;
    mapping(uint256 => bool) public allowedIds;
    mapping(uint256 => string) public uris;

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "WL Box: PERMISSION_DENIED");
        _;
    }

    function initialize(string memory name_) public initializer {
        __ERC1155Supply_init();
        __ERC1155_init("");
        __Ownable_init();
        __ReentrancyGuard_init();

        name = name_;
        maxSupplies.push(500);
        maxSupplies.push(500);
        allowedIds[1] = true;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WL Box: WITHDRAW_FAILED");
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "WL Box: INVALID_OPERATOR");
        operator = newOperator;
    }

    function setMaxSupply(uint256 newMaxSupply, uint256 id) external onlyOwnerOrOperator {
        require(id > 0, "WL Box: INVALID_ID");
        require(newMaxSupply >= totalSupply(id), "WL Box: ALREADY_MINTED_OVER");

        if (id > maxSupplies.length) maxSupplies.push(newMaxSupply);
        else maxSupplies[id - 1] = newMaxSupply;
    }

    function setPresetCode(string memory code_, bool valuable) external onlyOwnerOrOperator {
        code = code_;
        isCodeValuable = valuable;
    }

    function allowTokenId(uint256 id, bool approved) external onlyOwnerOrOperator {
        allowedIds[id] = approved;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function mintWithCode(string memory code_) external payable nonReentrant {
        require(isCodeValuable && countOfUse < 200, "WL Box: CODE_DISABLED");
        require(compareStrings(code, code_), "WL Box: INVALID_CODE");
        require(totalSupply(1) < maxSupplies[0], "WL Box: INSUFFICIENT_AMOUNT");

        countOfUse += 1;
        _mint(msg.sender, 1, 1, "");
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwnerOrOperator {
        require(
            recipients.length == ids.length && recipients.length == amounts.length,
            "WL Box: INVALID_ARGUMENTS"
        );
        for (uint256 i; i < recipients.length; i += 1) {
            _mint(recipients[i], ids[i], amounts[i], "");
        }
    }

    function setURI(string memory _uri, uint256 id) external onlyOwnerOrOperator {
        uris[id] = _uri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }
}
