//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Interfaces.sol";
import "./Uniswap.sol";
import "./BPool.sol";
import "./ERC20.sol";

contract Main {
    event NewAdmin(address);
    address public admin;

    // The exchange pools indexed by their pair address.
    mapping(address => TRBBalancer) public pools;

    ERC20 public oldTellorContract;

    // All LP tokens are sent to this address when
    // the owner receives their TRB equivalent.
    address public constant MULTISIG_DEV_WALLET =
        0x39E419bA25196794B595B2a595Ea8E527ddC9856;

    address constant UNISWAP_POOL = 0x70258Aa9830C2C84d855Df1D61E12C256F6448b4;

    mapping(address => bool) public migratedContracts;

    Migrator public newTRBContract;

    constructor(address _newTRBContract) {
        admin = MULTISIG_DEV_WALLET;
        // Not using the hardcoded address makes testing easier
        // newTRBContract = Migrator(0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0);
        newTRBContract = Migrator(_newTRBContract);

        oldTellorContract = ERC20(0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5);

        _addExchangePools();
    }

    function _addExchangePools() internal {
        pools[0x70258Aa9830C2C84d855Df1D61E12C256F6448b4] = new Uniswap(
            0x70258Aa9830C2C84d855Df1D61E12C256F6448b4,
            MULTISIG_DEV_WALLET
        );

        BPool bpool = new BPool(MULTISIG_DEV_WALLET);

        // The Balancer pools.
        // https://pools.balancer.exchange/#/explore?token=0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5

        // https://pools.balancer.exchange/#/pool/0x1373E57F764a7944bDd7A4BD5ca3007D496934DA/
        pools[0x1373E57F764a7944bDd7A4BD5ca3007D496934DA] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x74a5D106b18c86dC37be5c817093a873CdcFF216/
        pools[0x74a5D106b18c86dC37be5c817093a873CdcFF216] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0xa1Ec308F05bca8ACc84eAf76Bc9C92A52ac25415/
        pools[0xa1Ec308F05bca8ACc84eAf76Bc9C92A52ac25415] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0xa74485e5f668Bba37b5C044c386B363f4cBd7c8c/
        pools[0xa74485e5f668Bba37b5C044c386B363f4cBd7c8c] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x838d504010d83a343Db2462256180cA311d29d90/
        pools[0x838d504010d83a343Db2462256180cA311d29d90] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x9c5EF1D941EAefF8774128a8b2C58Fce2C2BC7fA/
        pools[0x9c5EF1D941EAefF8774128a8b2C58Fce2C2BC7fA] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x07B18C2686F3d1BA0Fa8C51edc856819f2b1100A/
        pools[0x07B18C2686F3d1BA0Fa8C51edc856819f2b1100A] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0xd386bb106E6FB44F91E180228EDECA24EF73C812/
        pools[0xd386bb106E6FB44F91E180228EDECA24EF73C812] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x3B6C3600B6350eB34Da0eAF26204fBED8953A14E/
        pools[0x3B6C3600B6350eB34Da0eAF26204fBED8953A14E] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x7c1460E627d64feBe9294c9b6Aabd5BB801d7AB6/
        pools[0x7c1460E627d64feBe9294c9b6Aabd5BB801d7AB6] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0xd386bb106E6FB44F91E180228EDECA24EF73C812/
        pools[0xd386bb106E6FB44F91E180228EDECA24EF73C812] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x3B6C3600B6350eB34Da0eAF26204fBED8953A14E/
        pools[0x3B6C3600B6350eB34Da0eAF26204fBED8953A14E] = TRBBalancer(bpool);

        // https://pools.balancer.exchange/#/pool/0x7c1460E627d64feBe9294c9b6Aabd5BB801d7AB6/
        pools[0x7c1460E627d64feBe9294c9b6Aabd5BB801d7AB6] = TRBBalancer(bpool);
    }

    //slither-disable-next-line unimplemented-functions
    function migratePool(address poolAddr) external {
        // require(poolAddr == UNISWAP_POOL, "must be the uniswap pool");
        uint256 balance =
            pools[UNISWAP_POOL].trbBalanceOf(poolAddr, msg.sender);
        require(balance > 0, "no balance to migrate");
        require(pools[UNISWAP_POOL].burn(poolAddr, msg.sender), "burn failed");
        newTRBContract.migrateFor(msg.sender, balance, false);
    }

    function migratePoolFor(address poolAddr, address _user)
        external
        onlyAdmin
    {
        uint256 balance = pools[poolAddr].trbBalanceOf(poolAddr, _user);
        require(balance > 0, "no balance to migrate");
        require(pools[poolAddr].burn(poolAddr, _user), "burn failed");
        newTRBContract.migrateFor(_user, balance, false);
    }

    //slither-disable-next-line unimplemented-functions
    function getPool(address poolAddr) external view returns (address) {
        return address(pools[poolAddr]);
    }

    function setPool(address pool, address poolAddr) external onlyAdmin {
        pools[pool] = TRBBalancer(poolAddr);
    }

    // Admin functions
    //slither-disable-next-line unimplemented-functions
    function migrateFrom(address _contract, address _owner) external onlyAdmin {
        uint256 balance = oldTellorContract.balanceOf(_contract);
        require(balance > 0, "no balance to migrate");
        _migrateFrom(_contract, _owner, balance, false);
    }

    function migrateFromCustom(
        address _contract,
        address _owner,
        uint256 _amount,
        bool _bypass
    ) external onlyAdmin {
        require(_amount > 0, "no balance to migrate");
        _migrateFrom(_contract, _owner, _amount, _bypass);
    }

    function migrateFromBatch(
        address[] calldata _contracts,
        address[] calldata _owners
    ) external onlyAdmin {
        require(
            _contracts.length == _owners.length,
            "mismatching array inputs"
        );
        uint256[] memory _balances = new uint256[](_owners.length);
        for (uint256 index = 0; index < _owners.length; index++) {
            _balances[index] = oldTellorContract.balanceOf(_contracts[index]);
        }
        _migrateFromBatch(_contracts, _owners, _balances);
    }

    function migrateFromBatchCustom(
        address[] calldata _contracts,
        address[] calldata _owners,
        uint256[] calldata _amounts
    ) external onlyAdmin {
        require(
            _contracts.length == _owners.length &&
                _owners.length == _amounts.length,
            "mismatching array inputs"
        );
        _migrateFromBatch(_contracts, _owners, _amounts);
    }

    function migrateFor(address _owner) public onlyAdmin {
        uint256 _balance = oldTellorContract.balanceOf(_owner);
        require(_balance > 0, "no balance to migrate");
        _migrateFor(_owner, _balance, false);
    }

    function migrateForCustom(
        address _owner,
        uint256 _amount,
        bool _bypass
    ) external onlyAdmin {
        require(_amount > 0, "no balance to migrate");
        _migrateFor(_owner, _amount, _bypass);
    }

    function migrateForBatch(address[] calldata _owners) external onlyAdmin {
        uint256[] memory _balances = new uint256[](_owners.length);
        for (uint256 index = 0; index < _owners.length; index++) {
            _balances[index] = oldTellorContract.balanceOf(_owners[index]);
        }
        _migrateForBatch(_owners, _balances);
    }

    function migrateForBatchCustom(
        address[] calldata _owners,
        uint256[] calldata _amounts
    ) external onlyAdmin {
        require(_owners.length == _amounts.length, "mismatching array inputs");
        _migrateForBatch(_owners, _amounts);
    }

    // Internal Functions
    function _migrateFor(
        address _owner,
        uint256 _amount,
        bool _bypass
    ) internal {
        if (!_bypass)
            require(!migratedContracts[_owner], "contract already migrated");
        // Tellor also keeps track of migrated contracts
        migratedContracts[_owner] = true;
        newTRBContract.migrateFor(_owner, _amount, _bypass);
    }

    function _migrateForBatch(
        address[] calldata _owners,
        uint256[] memory _amounts
    ) internal {
        for (uint256 index = 0; index < _owners.length; index++) {
            require(
                !migratedContracts[_owners[index]],
                "contract already migrated"
            );
            migratedContracts[_owners[index]] = true;
        }
        // Tellor also keeps track of migrated contracts
        newTRBContract.migrateForBatch(_owners, _amounts);
    }

    function _migrateFrom(
        address _owner,
        address _dest,
        uint256 _amount,
        bool _bypass
    ) internal {
        if (!_bypass)
            require(!migratedContracts[_owner], "contract already migrated");
        // Tellor also keeps track of migrated contracts
        migratedContracts[_owner] = true;
        newTRBContract.migrateFrom(_owner, _dest, _amount, _bypass);
    }

    function _migrateFromBatch(
        address[] calldata _owners,
        address[] calldata _dests,
        uint256[] memory _amounts
    ) internal {
        for (uint256 index = 0; index < _owners.length; index++) {
            require(
                !migratedContracts[_owners[index]],
                "contract already migrated"
            );
            migratedContracts[_owners[index]] = true;
        }
        newTRBContract.migrateFromBatch(_owners, _dests, _amounts);
    }

    function trbBalanceOf(address poolAddr, address holder)
        external
        view
        returns (uint256)
    {
        uint256 totalBalance = pools[poolAddr].trbBalanceOf(poolAddr, holder);
        return totalBalance;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call this function.");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(
            _admin != address(0),
            "shouldn't set admin to the zero address"
        );
        admin = _admin;
        emit NewAdmin(_admin);
    }
}
