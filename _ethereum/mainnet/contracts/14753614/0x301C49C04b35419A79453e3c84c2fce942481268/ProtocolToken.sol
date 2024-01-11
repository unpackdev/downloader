// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./ERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20Checkpointable.sol";
import "./IManager.sol";
import "./IPoolFactory.sol";

// ANW Finanace token with Governance.
contract ProtocolToken is IERC20Metadata, ERC20, ERC20Checkpointable {
    address public poolFactory;
    IManager public manager;

    modifier onlyAdmin() {
        require(manager.isAdmin(_msgSender()), "Pool::onlyAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(manager.isGorvernance(_msgSender()), "Pool::onlyGovernance");
        _;
    }

    constructor(
        address _poolFactory,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _manager
    ) ERC20(_tokenName, _tokenSymbol) {
        poolFactory = _poolFactory;
        manager = IManager(_manager);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by a pool with this token as it's reward.
    function mint(address _to, uint256 _amount) public {
        require(_msgSender() == IPoolFactory(poolFactory).rewardPools(address(this)), "ProtocolToken::mint: FORBIDDEN");
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }

    function setFactory(address _poolFactory) public onlyAdmin {
        poolFactory = _poolFactory;
    }

    // record checkpoint data after successful token transfer
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 newFrom = balanceOf(from);
        uint256 newTo = balanceOf(to);

        if (from != address(0)) {
            // no need to checkpoint the 0x0 address during mint
            _writeCheckpoint(from, newFrom + amount, newFrom);
        }

        if (to != address(0)) {
            // no need to checkpoint the 0x0 address during burn
            _writeCheckpoint(to, newTo - amount, newTo);
        }
    }
}
