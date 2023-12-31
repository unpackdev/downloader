// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";

contract MelonPresaleUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    using ECDSA for bytes32;

    struct Settings {
        uint maxSupply;
        uint totalSupply;
        uint maxPerWallet;
        uint startDate;
        uint endDate;
    }

    struct Deposit {
        address account;
        uint256 ethAmount;
        uint256 melonAmount;
    }

    mapping(address => uint) public balances;
    Settings public saleSettings;

    address private signerAddress;

    bytes32 private constant DEPOSIT_TYPEHASH =
        keccak256("Deposit(address account,uint256 ethAmount,uint256 melonAmount)");

    event NewDeposit(address account, uint ethAmount, uint melonAmount, uint accountBalance);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("MelonPresale", "1");
    }

    function makeDeposit(
        Deposit calldata deposit,
        bytes calldata signature
    ) external payable nonReentrant {
        require(
            block.timestamp >= saleSettings.startDate && block.timestamp < saleSettings.endDate,
            "Presale paused"
        );
        require(
            balances[deposit.account] + deposit.melonAmount <= saleSettings.maxPerWallet,
            "Max per wallet exceeded"
        );
        require(
            saleSettings.totalSupply + deposit.melonAmount <= saleSettings.maxSupply,
            "Max supply exceeded"
        );
        require(msg.sender == deposit.account, "Invalid sender");
        require(_validateSigner(deposit, signature), "Invalid signer");
        require(msg.value == deposit.ethAmount, "Invalid msg.value");

        balances[deposit.account] += deposit.melonAmount;
        saleSettings.totalSupply += deposit.melonAmount;

        emit NewDeposit(deposit.account, deposit.ethAmount, deposit.melonAmount, balances[deposit.account]);
    }

    function getPresaleDetails(address account) external view returns(Settings memory settings, uint accountBalance) {
        return (saleSettings, balances[account]);
    } 

    function _validateSigner(
        Deposit calldata deposit,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                DEPOSIT_TYPEHASH,
                deposit.account,
                deposit.ethAmount,
                deposit.melonAmount
            )
        );
        address recoveredSignerAddress = ECDSA.recover(
            ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash),
            signature
        );

        return recoveredSignerAddress == signerAddress;
    }

    function setup(
        address _signer,
        uint _maxSupply,
        uint _maxPerWallet,
        uint _startDate,
        uint _endDate
    ) external onlyOwner {
        signerAddress = _signer;

        saleSettings.maxSupply = _maxSupply;
        saleSettings.maxPerWallet = _maxPerWallet;
        saleSettings.startDate = _startDate;
        saleSettings.endDate = _endDate;
    }

    function withdrawERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function withdrawEarnings(address to, uint256 balance) external onlyOwner {
        payable(to).transfer(balance);
    }
}
