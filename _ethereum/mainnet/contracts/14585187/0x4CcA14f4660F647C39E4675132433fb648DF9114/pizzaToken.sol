// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract Pizzas is ERC20, ERC20Burnable, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    event WithdrawPZA(address indexed userAddress, uint256 amount);
    event DepositPZA(address indexed userAddress, uint256 amount);

    bool public withdrawActive = true;
    bool public depositActive = true;

    mapping(uint256 => bool) public usedNonces;
    mapping(address => bool) controllers;

    address public signerAddress;

    constructor() ERC20("Pizza Token", "PZA") {}

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function withdraw(
        uint256 amount,
        uint256 nonce,
        uint256 blockHeight,
        bytes memory signature
    ) external nonReentrant {
        require(withdrawActive, "Withdraw is not active");
        require(!usedNonces[nonce], "Used nonce");
        require(blockHeight > block.number, "Expired signature");

        usedNonces[nonce] = true;
        bytes32 inputHash = keccak256(
            abi.encodePacked(msg.sender, amount, nonce, blockHeight)
        );
        bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
        address recoveredAddress = ethSignedMessageHash.recover(signature);

        require(recoveredAddress == signerAddress, "Wrong signature");

        _mint(msg.sender, amount);
        emit WithdrawPZA(msg.sender, amount);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(depositActive, "Deposit is not active");
        _burn(msg.sender, amount);
        emit DepositPZA(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setSignerAddress(address newAddress) external onlyOwner {
        signerAddress = newAddress;
    }

    function toggleWithdraw() external onlyOwner {
        withdrawActive = !withdrawActive;
    }

    function toggleDeposit() external onlyOwner {
        depositActive = !depositActive;
    }
}
