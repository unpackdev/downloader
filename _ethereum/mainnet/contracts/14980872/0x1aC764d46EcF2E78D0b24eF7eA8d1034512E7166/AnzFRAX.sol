// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./ITimeLockPool.sol";

contract AnzFRAX is Context, AccessControlEnumerable, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    ITimeLockPool public timeLockPool;

    modifier onlyHasRole(bytes32 _role) {
        require(
            hasRole(_role, _msgSender()),
            "anzFRAX.onlyHasRole: Permission denied"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }

    function mint(address _account, uint256 _amount)
        external
        onlyHasRole(MINTER_ROLE)
    {
        super._mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount)
        external
        onlyHasRole(BURNER_ROLE)
    {
        super._burn(_account, _amount);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("anzFRAX is non-transferable");
    }

    function setUpTimeLockPool(address _poolAddress)
        external
        onlyHasRole(DEFAULT_ADMIN_ROLE)
    {
        timeLockPool = ITimeLockPool(_poolAddress);
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        uint256 balanceAccount = _balances[_account];
        if(address(timeLockPool) == address(0)) return balanceAccount;
        ITimeLockPool.Deposit[] memory deposits = timeLockPool.getDepositsOf(
            _account
        );
        uint256 actualBalance = 0;

        for (uint256 i = 0; i < deposits.length; i++) {
            ITimeLockPool.Deposit memory deposit = deposits[i];
            balanceAccount -=
                (deposit.amount *
                    timeLockPool.getMultiplier(deposit.end - deposit.start)) /
                1e18;

            actualBalance +=
                (deposit.amount *
                    getMultiplier(
                        deposit.end - deposit.start,
                        block.timestamp >= deposit.end
                            ? deposit.end - deposit.start
                            : block.timestamp - deposit.start
                    )) /
                1e18;
        }

        return balanceAccount + actualBalance;
    }

    function getMultiplier(uint256 _lockDuration, uint256 _elapsed)
        public
        view
        returns (uint256)
    {
        return
            1e18 +
            ((timeLockPool.getMaxBonus() * (_lockDuration - _elapsed)) /
                timeLockPool.getMaxLockDuration());
    }
}
