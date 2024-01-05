// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBagBang.sol";
import "./BAGToken.sol";
import "./LinearVest.sol";

contract BagBang is Ownable, IBagBang {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Allocation {
        address owner;
        uint256 total;
        uint256 withdrawn;
    }

    // token allocation limits
    uint256 public constant TREASURY_TOTAL_AMOUNT = 500000e18;
    uint256 public constant POOL_TOTAL_AMOUNT = 200000e18;
    uint256 public constant DEV_TOTAL_AMOUNT = 200000e18;
    uint256 public constant AIRDROP_TOTAL_AMOUNT = 50000e18;
    uint256 public constant ADVISORS_TOTAL_AMOUNT = 50000e18;

    uint256 public constant INITIAL_LIQUIDITY_AMOUNT = 100e18; // from TREASURY

    BAGToken public bagToken;
    Allocation public airdropAllocation;
    Allocation public treasuryAllocation;
    Allocation public advisorsAllocation;
    Allocation public devAllocation;
    Allocation public poolAllocation;

    constructor(BAGToken _bagToken) public {
        bagToken = _bagToken;
        airdropAllocation = Allocation(msg.sender, AIRDROP_TOTAL_AMOUNT, 0);
        treasuryAllocation = Allocation(msg.sender, TREASURY_TOTAL_AMOUNT, 0);
        advisorsAllocation = Allocation(msg.sender, ADVISORS_TOTAL_AMOUNT, 0);
        devAllocation = Allocation(msg.sender, DEV_TOTAL_AMOUNT, 0);
        poolAllocation = Allocation(msg.sender, POOL_TOTAL_AMOUNT, 0);
    }

    function updateTokenDAO(address newTokenOwner) public onlyOwner {
        bagToken.transferOwnership(newTokenOwner);
    }

    function setAirdropOwner(address _owner) public onlyOwner {
        airdropAllocation.owner = _owner;
    }

    function setTreasuryOwner(address _owner) public onlyOwner {
        treasuryAllocation.owner = _owner;
    }

    function setAdvisorsOwner(address _owner) public onlyOwner {
        advisorsAllocation.owner = _owner;
    }

    function setDevOwner(address _owner) public onlyOwner {
        devAllocation.owner = _owner;
    }

    function setPoolOwner(address _owner) public onlyOwner {
        poolAllocation.owner = _owner;
    }

    // Minting is strictly limited to allocated amounts regardless of allocation ownership
    function _mint(Allocation storage  _allocation, address _to, uint256 _amount) internal {
        require(msg.sender == _allocation.owner, "_mint: not authorized");
        require(_amount>0, "_mint: amount must be nonzero");

        uint256 withdrawn = _allocation.withdrawn.add(_amount);
        require(withdrawn <= _allocation.total, "_mint: allocation exceeded");

        bagToken.mint(_to, _amount);
        _allocation.withdrawn = withdrawn;
    }

    function mintAirdrop(address _to, uint256 _amount) external override {
        _mint(airdropAllocation, _to, _amount);
    }

    function mintTreasury(address _to, uint256 _amount) external override {
        _mint(treasuryAllocation, _to, _amount);
    }

    function mintAdvisors(address _to, uint256 _amount) external override {
        _mint(advisorsAllocation, _to, _amount);
    }

    function mintDev(address _to, uint256 _amount) external override {
        _mint(devAllocation, _to, _amount);
    }

    function mintPool(address _to, uint256 _amount) external override {
        _mint(poolAllocation, _to, _amount);
    }
}
