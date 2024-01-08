pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./ITokenStorage.sol";
import "./TokenStorage.sol";

contract EYESToken is AccessControl, ERC20Burnable, ERC20Pausable {
    using SafeMath for uint256;

    uint256 constant EXPECTED_TOTAL_SUPPLY    = 10000000000 ether;
    uint256 public constant MINTAGE_SALE_TOKEN       =  1500000000 ether;
    uint256 public constant MINTAGE_PER_WALLET       =   100000000 ether;
    uint256 public constant MINTAGE_ECO_TOKEN        =  5000000000 ether;
    uint256 public constant MINTAGE_TEAM_TOKEN       =  1500000000 ether;
    uint256 public constant MINTAGE_MARKET_TOKEN     =  2000000000 ether;

    bytes32 public constant ROLE_ADMIN       = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_ADMIN_ADMIN = keccak256("ROLE_ADMIN_ADMIN");
    bytes32 public constant ROLE_MULTISIG    = keccak256("ROLE_MULTISIG");
    bytes32 public constant ROLE_PREVENT     = keccak256("ROLE_PREVENT");

    ITokenStorage[37] private _token_storages;

    uint public constant INDEX_TOKEN_STORAGE_ECO         = 0;
    uint public constant INDEX_TOKEN_STORAGE_TEAM        = 1;
    uint public constant INDEX_TOKEN_STORAGE_SALE_ZERO   = 2;
    uint public constant INDEX_TOKEN_STORAGE_MARKET_ZERO = 17;

    uint public constant NUMBER_TOKEN_STORAGE_SALE   = 15;
    uint public constant NUMBER_TOKEN_STORAGE_MARKET = 20;
    uint public constant NUMBER_TOKEN_STORAGE        = 37;

    struct LockDataEntry {
        uint256 unlock_timestamp;
        uint256 locked_amount;
    }

    struct LockData {
        mapping (uint256 => LockDataEntry[12]) entries;
        uint256 length;
    }

    mapping (address => LockData) private _lock_data;
    mapping (address => bool) private _locked_wallets;

    bool private _minted;
    bool private _inited;

    constructor(address multisig) ERC20("EYES Protocol", "EYES") {
        _minted = false;
        _inited = false;

        /*
         * Transfer access
         *
         * 1. Multisig address has role `ROLE_MULTISIG`
         * 2. Multisig address has role `ROLE_ADMIN`
         * 3. Multisig address has role `ROLE_ADMIN_ADMIN`
         *
         * Addresses with `ROLE_MULTISIG` can
         * 1. Pause/unpause token contract
         * 2. Burn tokens held by 'eco'
         * 3. Burn tokens held by 'sale'
         * 4. Burn tokens held by 'team'
         * 5. Burn tokens held by 'market'
         *
         * Addresses with `ROLE_ADMIN` can
         * 1. Transfer tokens held by 'sale'
         * 2. Transfer tokens held by 'eco'
         * 3. Transfer tokens held by 'team'
         * 4. Transfer tokens held by 'market'
         *
         * Addresses with `ROLE_ADMIN_ADMIN` can
         * 1. Grant other addresses `ROLE_ADMIN` role
         */

        _setupRole(ROLE_MULTISIG,    multisig);
        _setupRole(ROLE_ADMIN,       multisig);
        _setupRole(ROLE_ADMIN_ADMIN, multisig);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN_ADMIN);

        /*
         * By default `ROLE_ADMIN_ADMIN` and `ROLE_ADMIN_ADMIN`'s admin role
         * are the same. Setting it to `ROLE_PREVENT` to prevent someone with
         * `ROLE_ADMIN_ADMIN` role from granting others `ROLE_ADMIN_ADMIN` role.
         */
        _setRoleAdmin(ROLE_ADMIN_ADMIN, ROLE_PREVENT);
    }

    function mint_reserved(uint index) public onlyRole(ROLE_ADMIN) {
        require (!_minted);
        require (index != INDEX_TOKEN_STORAGE_ECO);
        require (index != INDEX_TOKEN_STORAGE_TEAM);
        require (index < NUMBER_TOKEN_STORAGE);
        require (address(_token_storages[index]) == address(0x0));
        _token_storages[index] = new TokenStorage();
        _mint(address(_token_storages[index]), MINTAGE_PER_WALLET);
    }

    function mint_other() public onlyRole(ROLE_ADMIN) {
        require (!_minted);
        require (!_inited);

        _token_storages[INDEX_TOKEN_STORAGE_ECO] = new TokenStorage();
        _mint(address(_token_storages[INDEX_TOKEN_STORAGE_ECO]), MINTAGE_ECO_TOKEN);

        _token_storages[INDEX_TOKEN_STORAGE_TEAM] = new TokenStorage();
        _mint(address(_token_storages[INDEX_TOKEN_STORAGE_TEAM]), MINTAGE_TEAM_TOKEN);

        assert (totalSupply() == EXPECTED_TOTAL_SUPPLY);

        _inited = true;
    }

    function get_locked_balance(address owner) public view returns (uint256) {
        require (owner != address(0x0), "invalid address");

        uint256 length = _lock_data[owner].length;
        mapping (uint256 => LockDataEntry[12]) storage entries = _lock_data[owner].entries;
        uint256 acc = 0;

        for (uint256 i = 0; i < length; i = i.add(1)) {
            for (uint j = 0; j < 12; j += 1) {
                LockDataEntry storage e = entries[i][j];
                if (block.timestamp < e.unlock_timestamp)
                    acc = acc.add(e.locked_amount);
            }
        }

        return acc;
    }

    /*
     * `_unlock` unlocks unlockable tokens and return locked balance.
     * To get locked balance call `get_locked_balance` instead
     */
    function _unlock(address owner) internal returns (uint256) {
        require (owner != address(0x0), "invalid address");

        uint256 length = _lock_data[owner].length;
        mapping (uint256 => LockDataEntry[12]) storage entries = _lock_data[owner].entries;
        uint256 acc_locked = 0;

        for (uint256 i = 0; i < length; i = i.add(1)) {
            for (uint j = 0; j < 12; j += 1) {
                LockDataEntry storage e = entries[i][j];
                if (block.timestamp < e.unlock_timestamp) {
                    acc_locked = acc_locked.add(e.locked_amount);
                } else if (e.locked_amount != 0) {
                    // check for zero to prevent unnecessary write
                    e.locked_amount = 0;
                }
            }
        }

        return acc_locked;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require (balanceOf(msg.sender).sub(_unlock(msg.sender)) >= value, "insufficient unlocked token balance");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require (balanceOf(from).sub(_unlock(from)) >= value, "insufficient unlocked token balance");
        return super.transferFrom(from, to, value);
    }

    function transfer_sale_token(uint index, address to, uint256 amount) public onlyRole(ROLE_ADMIN) {
        require (index < NUMBER_TOKEN_STORAGE_SALE);
        _token_storages[INDEX_TOKEN_STORAGE_SALE_ZERO + index].transfer(this, to, amount);
    }

    function transfer_eco_token(address to, uint256 amount) public onlyRole(ROLE_ADMIN) {
        _token_storages[INDEX_TOKEN_STORAGE_ECO].transfer(this, to, amount);
    }

    function transfer_team_token(address to, uint256 amount) public onlyRole(ROLE_ADMIN) {
        _token_storages[INDEX_TOKEN_STORAGE_TEAM].transfer(this, to, amount);
    }

    function transfer_market_token(uint index, address to, uint256 amount) public onlyRole(ROLE_ADMIN) {
        require (index < NUMBER_TOKEN_STORAGE_MARKET);
        _token_storages[INDEX_TOKEN_STORAGE_MARKET_ZERO + index].transfer(this, to, amount);
    }

    function _transfer_locked_token(
        ITokenStorage from,
        address to,
        uint256 amount,
        uint256[12] memory locked_amounts,
        uint256[12] memory unlock_timestamps
    ) internal {
        uint256 lock_number = _lock_data[to].length;
        _lock_data[to].length = lock_number.add(1);

        LockDataEntry[12] storage entry = _lock_data[to].entries[lock_number];
        uint256 acc_amount = 0;
        for (uint i = 0; i < 12; i += 1) {
            entry[i].locked_amount = locked_amounts[i];
            acc_amount = acc_amount.add(locked_amounts[i]);
            entry[i].unlock_timestamp = unlock_timestamps[i];
        }
        require (acc_amount == amount);

        from.transfer(this, to, amount);
    }

    function transfer_locked_sale_token(
        uint256 index,
        address to,
        uint256 amount,
        uint256[12] memory locked_amounts,
        uint256[12] memory unlock_timestamps
    ) public onlyRole(ROLE_ADMIN) {
        require (index < NUMBER_TOKEN_STORAGE_SALE);
        uint storage_index = index.add(INDEX_TOKEN_STORAGE_SALE_ZERO);
        _transfer_locked_token(
            _token_storages[storage_index],
            to,
            amount,
            locked_amounts,
            unlock_timestamps);
    }

    function transfer_locked_eco_token(
        address to,
        uint256 amount,
        uint256[12] memory locked_amounts,
        uint256[12] memory unlock_timestamps
    ) public onlyRole(ROLE_ADMIN) {
        _transfer_locked_token(
            _token_storages[INDEX_TOKEN_STORAGE_ECO],
            to,
            amount,
            locked_amounts,
            unlock_timestamps);
    }

    function transfer_locked_team_token(
        address to,
        uint256 amount,
        uint256[12] memory locked_amounts,
        uint256[12] memory unlock_timestamps
    ) public onlyRole(ROLE_ADMIN) {
        _transfer_locked_token(
            _token_storages[INDEX_TOKEN_STORAGE_TEAM],
            to,
            amount,
            locked_amounts,
            unlock_timestamps);
    }

    function transfer_locked_market_token(
        uint256 index,
        address to,
        uint256 amount,
        uint256[12] memory locked_amounts,
        uint256[12] memory unlock_timestamps
    ) public onlyRole(ROLE_ADMIN) {
        require (index < NUMBER_TOKEN_STORAGE_MARKET);
        uint256 storage_index = index.add(INDEX_TOKEN_STORAGE_MARKET_ZERO);
        _transfer_locked_token(
            _token_storages[storage_index],
            to,
            amount,
            locked_amounts,
            unlock_timestamps);
    }

    function burn_sale_token(uint index, uint256 amount) public onlyRole(ROLE_MULTISIG) {
        require (index < NUMBER_TOKEN_STORAGE_SALE);
        _token_storages[INDEX_TOKEN_STORAGE_SALE_ZERO + index].burn(this, amount);
    }

    function burn_eco_token(uint256 amount) public onlyRole(ROLE_MULTISIG) {
        _token_storages[INDEX_TOKEN_STORAGE_ECO].burn(this, amount);
    }

    function burn_team_token(uint256 amount) public onlyRole(ROLE_MULTISIG) {
        _token_storages[INDEX_TOKEN_STORAGE_TEAM].burn(this, amount);
    }

    function burn_market_token(uint index, uint256 amount) public onlyRole(ROLE_MULTISIG) {
        require (index < NUMBER_TOKEN_STORAGE_MARKET);
        _token_storages[INDEX_TOKEN_STORAGE_MARKET_ZERO + index].burn(this, amount);
    }

    function pause() public onlyRole(ROLE_MULTISIG) {
        _pause();
    }

    function unpause() public onlyRole(ROLE_MULTISIG) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        require (!_locked_wallets[from], "source wallet address is locked");
        super._beforeTokenTransfer(from, to, amount);
    }

    function lock_wallet(address wallet, bool lock) public onlyRole(ROLE_MULTISIG) {
        require (wallet != address(0x0), "you can't lock 0x0");
        require (_locked_wallets[wallet] != lock, "the wallet is set to given state already");
        _locked_wallets[wallet] = lock;
    }

    function burn_locked_from(address from) public onlyRole(ROLE_MULTISIG) {
        require (from != address(0x0), "invalid address");

        uint256 length = _lock_data[from].length;
        mapping (uint256 => LockDataEntry[12]) storage entries = _lock_data[from].entries;
        uint256 acc_burnt = 0;

        for (uint256 i = 0; i < length; i = i.add(1)) {
            for (uint j = 0; j < 12; j += 1) {
                LockDataEntry storage e = entries[i][j];
                if (block.timestamp < e.unlock_timestamp) {
                    acc_burnt = acc_burnt.add(e.locked_amount);
                    e.locked_amount = 0;
                }
            }
        }

        _burn(from, acc_burnt);
    }

    function balance_of_token_storage(uint index) public view returns (uint256) {
        require (index < NUMBER_TOKEN_STORAGE);
        return balanceOf(address(_token_storages[index]));
    }
}
