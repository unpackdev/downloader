// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20FlashMintUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./DaxMining.sol";

contract DaxCoin is
    Initializable,
    AccessControlUpgradeable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20FlashMintUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    event Cashin(address indexed account, uint256 etherAmount, uint256 tokenAmount);
    event Cashout(address indexed account, uint256 tokenAmount, uint256 etherAmount);

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant EXCHANGE_TO_ETHER_ROLE = keccak256("EXCHANGE_TO_ETHER_ROLE");
    bytes32 public constant EXCHANGE_TO_TOKEN_ROLE = keccak256("EXCHANGE_TO_TOKEN_ROLE");
    bytes32 public constant FLASH_FEE_ROLE = keccak256("FLASH_FEE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    DaxMining private _miningContract;
    DaxToken private _tokenContract;
    uint256 private _etherToTokenExchangeRate;
    uint256 private _tokenToEtherExchangeRate;
    uint256 private _flatFlashFee;

    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        require(_etherToTokenExchangeRate != 0, "DaxCoin: ether to token unsupported");

        uint256 etherAmount = _msgValue();
        uint256 tokenAmount = etherAmount * _etherToTokenExchangeRate;
        address sender = _msgSender();

        _mint(sender, tokenAmount);

        emit Cashin(sender, etherAmount, tokenAmount);
    }

    function initialize(DaxToken tokenContract)
    public initializer {
        __AccessControl_init();
        __ERC20_init("DaxCoin", "DAXC");
        __ERC20Burnable_init();
        __ERC20FlashMint_init();
        __UUPSUpgradeable_init();

        address sender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(CONTRACT_ADMIN_ROLE, sender);
        _grantRole(EXCHANGE_TO_ETHER_ROLE, sender);
        _grantRole(EXCHANGE_TO_TOKEN_ROLE, sender);
        _grantRole(FLASH_FEE_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

        _tokenContract = tokenContract;
        _etherToTokenExchangeRate = 10000;
        _tokenToEtherExchangeRate = 10000;
    }

    function actualBalanceOf(address account)
    public view
    returns (uint256) {
        return super.balanceOf(account);
    }

    function balanceOf(address account)
    public view virtual override
    returns (uint256) {
        return super.balanceOf(account) + _miningContract.mined(account);
    }

    function improve(uint256 miner, uint256 amount)
    public {
        burn(amount);
        _miningContract.improve(miner, amount);
    }

    function mine(uint256 miner)
    public {
        address owner = _tokenContract.ownerOf(miner);
        address sender = _msgSender();
        require(owner == sender, "DaxCoin: miner not owned");

        _mint(owner, _miningContract.mine(miner));
    }

    function mine()
    public {
        address sender = _msgSender();
        _mint(sender, _miningContract.mine(sender));
    }

    function __config()
    public view
    returns (
        DaxMining miningContract,
        DaxToken tokenContract,
        uint256 etherToTokenExchangeRate,
        uint256 tokenToEtherExchangeRate,
        uint256 flatFlashFee)
    {
        miningContract = _miningContract;
        tokenContract = _tokenContract;
        etherToTokenExchangeRate = _etherToTokenExchangeRate;
        tokenToEtherExchangeRate = _tokenToEtherExchangeRate;
        flatFlashFee = _flatFlashFee;
    }

    function __etherToTokenExchangeRate()
    public view returns (uint256) {
        return _etherToTokenExchangeRate;
    }

    function __flatFlashFee()
    public view returns (uint256) {
        return _flatFlashFee;
    }

    function __miningContract()
    public view returns (DaxMining) {
        return _miningContract;
    }

    function __tokenContract()
    public view returns (DaxToken) {
        return _tokenContract;
    }

    function __tokenToEtherExchangeRate()
    public view returns (uint256) {
        return _tokenToEtherExchangeRate;
    }

    function __setEtherToTokenExchangeRate(uint256 rate)
    public onlyRole(EXCHANGE_TO_TOKEN_ROLE) {
        _etherToTokenExchangeRate = rate;
    }

    function __setFlashFee(uint256 fee)
    public onlyRole(FLASH_FEE_ROLE) {
        _flatFlashFee = fee;
    }

    function __setMiningContract(DaxMining miningContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _miningContract = miningContract;
    }

    function __setTokenContract(DaxToken tokenContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _tokenContract = tokenContract;
    }

    function __setTokenToEtherExchangeRate(uint256 rate)
    public onlyRole(EXCHANGE_TO_ETHER_ROLE) {
        _tokenToEtherExchangeRate = rate;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal override {
        super._afterTokenTransfer(from, to, amount);

        if (to == address(this)) {
            _burn(to, amount);
            uint256 etherAmount = amount.div(_tokenToEtherExchangeRate);
            require(etherAmount <= address(this).balance, "DaxCoin: insufficient ether");
            require(payable(from).send(etherAmount), "DaxCoin: cashout failed");

            emit Cashout(from, amount, etherAmount);
        } else if (to == address(_tokenContract)) {
            _burn(to, amount);
            uint256 miner = _tokenContract.mint(from, from, "");
            _miningContract.improve(miner, amount);
            _miningContract.mine(miner);
        } else if (to == address(_miningContract)) {
            _burn(to, amount);
            _miningContract.improve(from, amount);
            _mint(from, _miningContract.mine(from));
        }
    }

    function _authorizeUpgrade(address newImplementation)
    internal onlyRole(UPGRADER_ROLE) override {}

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { return; }

        uint256 accountBalance = super.balanceOf(from);
        uint256 miningBalance = _miningContract.mined(from);
        if (accountBalance < amount && accountBalance + miningBalance >= amount) {
            _mint(from, _miningContract.mine(from));
        }
    }

    function _flashFee(address token, uint256 amount)
    internal view virtual
    returns (uint256) {
        token;
        amount;
        
        return _flatFlashFee;
    }
    
    function _msgValue()
    private returns (uint256) {
        return msg.value;
    }
}
