//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract HypeXSatellite is
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    string public name;
    string public symbol;

    uint256 public price;
    address public operator;
    mapping(uint256 => bool) public allowedIds;
    uint256 public countOfAirdrop;
    uint256 public countOfMint;
    uint256 public maxForAirdrop;
    uint256 public maxForMint;
    string[] public uris;
    mapping(uint256 => string) public _uris;

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Satellite: PERMISSION_DENIED");
        _;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Satellite: WITHDRAW_FAILED");
    }

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC1155Supply_init();
        __ERC1155_init("");
        __Ownable_init();
        __ReentrancyGuard_init();

        name = name_;
        symbol = symbol_;
        allowedIds[1] = true;
        price = 1e17;
        maxForAirdrop = 50;
        maxForMint = 100;
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Satellite: INVALID_OPERATOR");
        operator = newOperator;
    }

    function allowTokenId(uint256 id, bool approved) external onlyOwnerOrOperator {
        allowedIds[id] = approved;
    }

    function setMaxCount(uint256 count, bool forMint) external onlyOwnerOrOperator {
        require(count >= (forMint ? countOfMint : countOfAirdrop), "Satellite: ALREADY_OVER");
        if (forMint) maxForMint = count;
        else maxForAirdrop = count;
    }

    function mint(uint256 id) external payable nonReentrant {
        require(allowedIds[id], "Satellite: NOT_ALLOWED_TOKEN_ID");
        require(countOfMint < maxForMint, "Satellite: INSUFFICIENT_AMOUNT");
        require(msg.value == price, "Satellite: INCORRECT_PRICE");

        countOfMint += 1;
        _mint(msg.sender, id, 1, "");
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwnerOrOperator {
        require(
            recipients.length == ids.length && recipients.length == amounts.length,
            "Satellite: INVALID_ARGUMENTS"
        );
        require(
            countOfAirdrop + recipients.length <= maxForAirdrop,
            "Satellite: INSUFFICIENT_AMOUNT"
        );
        for (uint256 i; i < recipients.length; i += 1) {
            countOfAirdrop += 1;
            _mint(recipients[i], ids[i], amounts[i], "");
        }
    }

    function setURI(string memory _uri, uint256 id) external onlyOwnerOrOperator {
        _uris[id] = _uri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uris[id];
    }
}
