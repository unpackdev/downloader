// SPDX-License-Identifier: MIT

/*
                8888888888 888                   d8b
                888        888                   Y8P
                888        888
                8888888    888 888  888 .d8888b  888 888  888 88888b.d88b.
                888        888 888  888 88K      888 888  888 888 "888 "88b
                888        888 888  888 "Y8888b. 888 888  888 888  888  888
                888        888 Y88b 888      X88 888 Y88b 888 888  888  888
                8888888888 888  "Y88888  88888P' 888  "Y88888 888  888  888
                                    888
                               Y8b d88P
                                "Y88P"
                888b     d888          888              .d8888b.                888
                8888b   d8888          888             d88P  Y88b               888
                88888b.d88888          888             888    888               888
                888Y88888P888  .d88b.  888888  8888b.  888         .d88b.   .d88888 .d8888b
                888 Y888P 888 d8P  Y8b 888        "88b 888  88888 d88""88b d88" 888 88K
                888  Y8P  888 88888888 888    .d888888 888    888 888  888 888  888 "Y8888b.
                888   "   888 Y8b.     Y88b.  888  888 Y88b  d88P Y88..88P Y88b 888      X88
                888       888  "Y8888   "Y888 "Y888888  "Y8888P88  "Y88P"   "Y88888  88888P'
*/

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract GODToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {

    address private signerAddress;

    uint256 public maxSupply;

    uint256 public withdrawRequestLifetimeSeconds;

    uint256 public withdrawTax;

    mapping(address => bool) public authorisedAddresses;

    mapping(uint256 => bool) public handledRequests;

    event Deposit(address wallet, uint256 amount);

    event WithdrawalRequestFinished(address wallet, uint256 internalIdentifier, bool successful);

    modifier authorised() {
        require(authorisedAddresses[msg.sender], "NOT AUTHORISED");
        _;
    }

    function initialize() public initializer {

        __ERC20_init("GOD Token", "GOD");
        __Ownable_init();
        __Pausable_init();

        maxSupply = 969914500 ether;
        withdrawTax = 30;
    }

    function withdraw(
        uint256 internalIdentifier_, uint256 amount_, uint256 generationDate_, bytes calldata signature_
    ) external whenNotPaused {
        require(handledRequests[internalIdentifier_] == false);
        _validateWithdrawSignature(internalIdentifier_, amount_, generationDate_, signature_);
        uint256 amountAfterTax = amount_ - amount_ * withdrawTax / 100;
        require(totalSupply() + amountAfterTax <= maxSupply);
        _mint(msg.sender, amountAfterTax);
        signalSuccessfulWithdraw(msg.sender, internalIdentifier_);
    }

    function cancelWithdrawForWallet(address wallet_, uint256 internalIdentifier_) external onlyOwner {
        signalCancelWithdraw(wallet_, internalIdentifier_);
    }

    function cancelWithdraw(uint256 internalIdentifier_, bytes calldata signature_) external whenNotPaused {
        _validateCancelWithdrawSignature(internalIdentifier_, signature_);
        signalCancelWithdraw(msg.sender, internalIdentifier_);
    }

    function depositTokens(address wallet_, uint256 amount_) external whenNotPaused {
        _burn(msg.sender, amount_);
        emit Deposit(wallet_, amount_);
    }

    function add(address wallet, uint256 amount) external authorised {
        emit Deposit(wallet, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTax(uint256 newWithdrawTax_) external onlyOwner {
        withdrawTax = newWithdrawTax_;
    }

    function setSignerAddress(address signerAddress_) external onlyOwner {
        signerAddress = signerAddress_;
    }

    function setMaxSupply(uint256 newMaxSupply_) external onlyOwner {
        maxSupply = newMaxSupply_;
    }

    function setWithdrawRequestLifetimeSeconds(uint256 withdrawRequestLifetimeSeconds_) external onlyOwner {
        withdrawRequestLifetimeSeconds = withdrawRequestLifetimeSeconds_;
    }

    function setAuthorised(address[] calldata addresses_, bool[] calldata authorisations_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            authorisedAddresses[addresses_[i]] = authorisations_[i];
        }
    }

    function signalWithdrawFinished(address wallet_, uint256 internalIdentifier_, bool successful_) internal {
        handledRequests[internalIdentifier_] = true;
        emit WithdrawalRequestFinished(wallet_, internalIdentifier_, successful_);
    }

    function signalCancelWithdraw(address wallet_, uint256 internalIdentifier_) internal {
        signalWithdrawFinished(wallet_, internalIdentifier_, false);
    }

    function signalSuccessfulWithdraw(address wallet_, uint256 internalIdentifier_) internal {
        signalWithdrawFinished(wallet_, internalIdentifier_, true);
    }

    function _validateWithdrawSignature(
        uint256 internalIdentifier_, uint256 amount_, uint256 generationDate_, bytes calldata signature_
    ) internal view {
        bytes32 dataHash = keccak256(abi.encodePacked(internalIdentifier_, amount_, generationDate_, msg.sender));
        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSAUpgradeable.recover(message, signature_);
        require(receivedAddress != address(0) && receivedAddress == signerAddress);
        require(block.timestamp <= (generationDate_ + withdrawRequestLifetimeSeconds));
    }

    function _validateCancelWithdrawSignature(uint256 internalIdentifier_, bytes calldata signature_) internal view {
        bytes32 dataHash = keccak256(abi.encodePacked(internalIdentifier_, msg.sender));
        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSAUpgradeable.recover(message, signature_);
        require(receivedAddress != address(0) && receivedAddress == signerAddress);
    }

}

