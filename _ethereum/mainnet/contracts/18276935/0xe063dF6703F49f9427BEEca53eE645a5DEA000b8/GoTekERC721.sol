// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./GoTekERC20.sol";

contract GoTekERC721 is ERC721EnumerableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    bool private initialized;
    GoTekERC20 public wallet;

    //    constructor(string memory name_, string memory symbol_, address _walletAddress)
    //        ERC721(name_, symbol_) {
    //        wallet = GoTekERC20(_walletAddress);
    //    }

    function initialize(address _walletAddress) public initializer {

        require(!initialized, "Contract instance has already been initialized");
        initialized = true;

        __ERC721_init("GPlus NFT", "GPNFT");
        __Ownable_init();
        __UUPSUpgradeable_init();

        wallet = GoTekERC20(_walletAddress);
    }

    //UUPS module required by openZ — Stops unauthorized upgrades
    function _authorizeUpgrade(address) internal override onlyOwner {

    }

    //Owner to Phone
    mapping(address => uint256[]) public phones;

    //Phone to Balance
    mapping(uint256 => uint256) public balances;

    //Phone to Validity Time
    mapping(uint256 => uint256) public validity;

    mapping(uint256 => Transaction[]) public transactions;

    struct PhoneData {
        uint256 mobile;
        uint256 balance;
        uint256 time;
        uint256 current;
    }

    struct Transaction {
        uint256 amount;
        uint256 time;
    }

    function register(address owner, uint256 phone, uint256 balance) public onlyOwner {
        _mint(owner, phone);
        phones[owner].push(phone);
        balances[phone] = balance;
        validity[phone] = block.timestamp + 365 days;
        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function debit(address owner, uint256 phone, uint256 balance) public onlyOwner {
        require(balances[phone] > balance, "You do not have enough balance");
        balances[phone] -= balance;
    }

    function credit(address owner, uint256 phone, uint256 balance) public onlyOwner {

        wallet.burn(owner, balance);

        balances[phone] += balance;

        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function renew(address owner, uint256 phone, uint256 balance) public onlyOwner {
        if (validity[phone] > block.timestamp) {
            validity[phone] = validity[phone] + 365 days;
        } else {
            validity[phone] = block.timestamp + 365 days;
        }

        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function details(address owner) public view returns (PhoneData[] memory) {
        uint256[] memory ownerPhones = phones[owner];

        PhoneData[] memory newBalance = new PhoneData[](ownerPhones.length);

        for (uint256 i = 0; i < ownerPhones.length; i++) {
            uint256 phone = ownerPhones[i];
            PhoneData memory phoneData = PhoneData(phone, balances[phone], validity[phone], block.timestamp);
            newBalance[i] = phoneData;
        }
        return newBalance;
    }

    function getTransaction(uint256 phone) public view returns (Transaction[] memory){
        return transactions[phone];
    }

    // added in version 1

    function transfer(address sender, address receiver, uint256 phone) public onlyOwner {
        uint256[] memory ownerPhones = phones[sender];
        for (uint256 i = 0; i < ownerPhones.length; i++) {
            if (ownerPhones[i] == phone) {
                _transfer(sender, receiver, phone);
                //todo push to receiver
                phones[receiver].push(phone);
                //todo delete from sender
                if (ownerPhones.length > 1) {
                    phones[sender][i] == ownerPhones[ownerPhones.length - 1];
                    phones[sender][ownerPhones.length - 1] = phone;
                }
                phones[sender].pop();
                //                delete phones[sender][i];
                return;
            }
        }
        return;
    }

    function remove(address owner, uint256 phone) public onlyOwner {
        uint256[] memory ownerPhones = phones[owner];
        for (uint256 i = 0; i < ownerPhones.length; i++) {
            if (ownerPhones[i] == phone) {
                //todo delete from sender
                if (ownerPhones.length > 1) {
                    phones[owner][i] == ownerPhones[ownerPhones.length - 1];
                    phones[owner][ownerPhones.length - 1] = phone;
                }
                phones[owner].pop();
                //                delete phones[owner][i];
                _burn(phone);
                return;
            }
        }
        return;
    }
}
