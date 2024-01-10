// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./ISystemStatus.sol";
import "./ExternStateToken.sol";
import "./MixinResolver.sol";
import "./SafeMath.sol";

interface IRewardEscrow {
    // Views
    function balanceOf(address account) external view returns (uint);
    function numVestingEntries(address account) external view returns (uint);
    function totalEscrowedAccountBalance(address account) external view returns (uint);
    function totalVestedAccountBalance(address account) external view returns (uint);
    // Mutative functions
    function appendVestingEntry(address account, uint quantity) external;
    function vest() external;
}

interface IHasBalance {
    // Views
    function balanceOf(address account) external view returns (uint);
}

interface IVault {

}

contract Elysian is  ExternStateToken, MixinResolver {
    using SafeMath for uint256;
    
    // ========== STATE VARIABLES ==========
    string public constant TOKEN_NAME = "Elysian Network Token";
    string public constant TOKEN_SYMBOL = "LYS";
    uint8  public constant DECIMALS = 9;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_TREASURY = "Treasury";
    bytes32 private constant CONTRACT_ELYSIANESCROW = "ElysianEscrow";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_VAULT = "ElysianVault";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";

     // ========== CONSTRUCTOR ==========
    constructor(
        address payable _proxy,
        TokenState _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(
            _proxy, 
            _tokenState, 
            TOKEN_NAME, 
            TOKEN_SYMBOL, 
            _totalSupply, 
            DECIMALS, 
            _owner
        )
        MixinResolver(_resolver) {}


    function totalBalance(address account) external view returns (uint) {
        uint balance = tokenState.balanceOf(account);
        if (address(elysianEscrow()) != address(0)) {
            balance = balance.add(elysianEscrow().balanceOf(account));
        }
        if (address(rewardEscrow()) != address(0)) {
            balance = balance.add(rewardEscrow().balanceOf(account));
        }
        return balance;
    }

    function mint(uint _amount, address _recipient, bool _isEscrowed) external onlyInternalContracts issuanceActive returns (bool) {
        require(_amount > 0, "Cannot mint 0 tokens");
        bool result = _internalIssue(_recipient, _amount, _isEscrowed);
        return result;
    }

    function _internalIssue(address account, uint amount, bool _isEscrowed) internal returns (bool) {
        if (_isEscrowed) {
            tokenState.setBalanceOf(address(this), tokenState.balanceOf(address(this)).add(amount));
            _transfer(address(rewardEscrow()), amount);
            rewardEscrow().appendVestingEntry(account, amount);
            emitTransfer(address(0), address(rewardEscrow()), amount);
        } else {
            tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
            emitTransfer(address(0), account, amount);
        }
        totalSupply = totalSupply.add(amount);
        emitIssued(account, amount);
        return true;
    }

    function burn(uint _amount, address _account) external onlyInternalContracts returns (bool) {
        bool result = _internalBurn(_account, _amount);
        return result;
    }

    function _internalBurn(address account, uint amount) internal returns (bool) {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount, "internal error during burn");

        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
        return true;
    }

    function _transfer(address to, uint value) internal returns (bool) {
        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(address(this), to, value);
        return true;
    }

    function transfer(address to, uint value) external optionalProxy systemActive returns (bool) {
        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(messageSender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy systemActive returns (bool) {
        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        return _transferFromByProxy(messageSender, from, to, value);
    }

    modifier onlyInternalContracts() {
        bool isVault = messageSender == address(vault());
        require(
            isVault,
            "Only authorized contracts allowed"
        );
        _;
    }

    modifier issuanceActive() {
        systemStatus().requireIssuanceActive();
        _;
    }

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(resolver.requireAndGetAddress("SystemStatus", "Missing SystemStatus address"));
    }

    function vault() public view returns (IVault) {
        return IVault(resolver.requireAndGetAddress(CONTRACT_VAULT, "Missing Vault address"));
    }

    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(resolver.requireAndGetAddress(CONTRACT_REWARDESCROW, "Missing reward escrow address"));
    }

    function elysianEscrow() internal view returns (IHasBalance) {
        return IHasBalance(resolver.requireAndGetAddress(CONTRACT_ELYSIANESCROW, "Missing Elysian escrow address"));
    }

    /* ========== EVENTS ========== */
    event Issued(address indexed account, uint value);
    bytes32 private constant ISSUED_SIG = keccak256("Issued(address,uint256)");

    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, addressToBytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);
    bytes32 private constant BURNED_SIG = keccak256("Burned(address,uint256)");

    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, addressToBytes32(account), 0, 0);
    }
}
