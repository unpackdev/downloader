/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\AssetInterface.sol

pragma solidity 0.5.8;


contract AssetInterface {
    function _performTransferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performTransferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _performTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performGeneric(bytes memory, address) public payable {
        revert();
    }
}

// File: contracts\ERC20Interface.sol

pragma solidity 0.5.8;


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() public view returns(uint256 supply);
    function balanceOf(address _owner) public view returns(uint256 balance);
    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

    // function symbol() constant returns(string);
    function decimals() public view returns(uint8);
    // function name() constant returns(string);
}

// File: contracts\AssetProxyInterface.sol

pragma solidity 0.5.8;



contract AssetProxyInterface is ERC20Interface {
    function _forwardApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _forwardTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _forwardTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function recoverTokens(ERC20Interface _asset, address _receiver, uint _value)
    public returns(bool);

    function etoken2() external view returns(address); // To be replaced by the implicit getter;

    // To be replaced by the implicit getter;
    function etoken2Symbol() external view returns(bytes32);
}

// File: @orderbook\smart-contracts-common\contracts\Bytes32.sol

pragma solidity 0.5.8;


contract Bytes32 {
    function _bytes32(string memory _input) internal pure returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

// File: @orderbook\smart-contracts-common\contracts\ReturnData.sol

pragma solidity 0.5.8;


contract ReturnData {
    function _returnReturnData(bool _success) internal pure {
        assembly {
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch _success case 0 { revert(returndatastart, returndatasize) }
                default { return(returndatastart, returndatasize) }
        }
    }

    function _assemblyCall(address _destination, uint _value, bytes memory _data)
    internal returns(bool success) {
        assembly {
            success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
        }
    }
}

// File: contracts\Asset.sol

pragma solidity 0.5.8;






/**
 * @title EToken2 Asset implementation contract.
 *
 * Basic asset implementation contract, without any additional logic.
 * Every other asset implementation contracts should derive from this one.
 * Receives calls from the proxy, and calls back immediately without arguments modification.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Asset is AssetInterface, Bytes32, ReturnData {
    // Assigned asset proxy contract, immutable.
    AssetProxyInterface public proxy;

    /**
     * Only assigned proxy is allowed to call.
     */
    modifier onlyProxy() {
        if (address(proxy) == msg.sender) {
            _;
        }
    }

    /**
     * Sets asset proxy address.
     *
     * Can be set only once.
     *
     * @param _proxy asset proxy contract address.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function init(AssetProxyInterface _proxy) public returns(bool) {
        if (address(proxy) != address(0)) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferToICAPWithReference(
                bytes20(_to), _value, _reference, _sender);
        }
        return _transferWithReference(_to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromWithReference(
            _sender, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        return _transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(
            _sender, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferFromToICAPWithReference(
                _from, bytes20(_to), _value, _reference, _sender);
        }
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromWithReference(
            _from, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        return _transferFromToICAPWithReference(
            _from, _icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(
            _from, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performApprove(address _spender, uint _value, address _sender)
    public onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _approve(address _spender, uint _value, address _sender)
    internal returns(bool) {
        return proxy._forwardApprove(_spender, _value, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return bytes32 result.
     * @dev function is final, and must not be overridden.
     */
    function _performGeneric(bytes memory _data, address _sender)
    public payable onlyProxy() {
        _generic(_data, msg.value, _sender);
    }

    modifier onlyMe() {
        if (address(this) == msg.sender) {
            _;
        }
    }

    // Most probably the following should never be redefined in child contracts.
    address public genericSender;

    function _generic(bytes memory _data, uint _value, address _msgSender) internal {
        // Restrict reentrancy.
        require(genericSender == address(0));
        genericSender = _msgSender;
        bool success = _assemblyCall(address(this), _value, _data);
        delete genericSender;
        _returnReturnData(success);
    }

    // Decsendants should use _sender() instead of msg.sender to properly process proxied calls.
    function _sender() internal view returns(address) {
        return address(this) == msg.sender ? genericSender : msg.sender;
    }

    // Interface functions to allow specifying ICAP addresses as strings.
    function transferToICAP(string memory _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

    function transferToICAPWithReference(string memory _icap, uint _value, string memory _reference)
    public returns(bool) {
        return _transferToICAPWithReference(
            _bytes32(_icap), _value, _reference, _sender());
    }

    function transferFromToICAP(address _from, string memory _icap, uint _value)
    public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

    function transferFromToICAPWithReference(
        address _from,
        string memory _icap,
        uint _value,
        string memory _reference)
    public returns(bool) {
        return _transferFromToICAPWithReference(
            _from, _bytes32(_icap), _value, _reference, _sender());
    }

    function isICAP(address _address) public pure returns(bool) {
        bytes20 a = bytes20(_address);
        if (a[0] != 'X' || a[1] != 'E') {
            return false;
        }
        if (uint8(a[2]) < 48 || uint8(a[2]) > 57 || uint8(a[3]) < 48 || uint8(a[3]) > 57) {
            return false;
        }
        for (uint i = 4; i < 20; i++) {
            uint char = uint8(a[i]);
            if (char < 48 || char > 90 || (char > 57 && char < 65)) {
                return false;
            }
        }
        return true;
    }
}

// File: contracts\Ambi2Enabled.sol

pragma solidity 0.5.8;


contract Ambi2 {
    function claimFor(address _address, address _owner) public returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) public view returns(bool);
    function isOwner(address _node, address _owner) public view returns(bool);
}


contract Ambi2Enabled {
    Ambi2 public ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != address(0) && ambi2.hasRole(address(this), _role, msg.sender)) {
            _;
        }
    }

    // Perform only after claiming the node, or claim in the same tx.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != address(0)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

// File: contracts\Ambi2EnabledFull.sol

pragma solidity 0.5.8;



contract Ambi2EnabledFull is Ambi2Enabled {
    // Setup and claim atomically.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != address(0)) {
            return false;
        }
        if (!_ambi2.claimFor(address(this), msg.sender) &&
            !_ambi2.isOwner(address(this), msg.sender)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

// File: contracts\AssetWithAmbi.sol

pragma solidity 0.5.8;




contract AssetWithAmbi is Asset, Ambi2EnabledFull {
    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != address(0) && (ambi2.hasRole(address(this), _role, _sender()))) {
            _;
        }
    }
}

// File: contracts\AssetWithWhitelist.sol

pragma solidity 0.5.8;



interface INUXAsset {
    function availableBalanceOf(address _holder) external view returns(uint);
    function scheduleReleaseStart() external;
    function transferLock(address _to, uint _value) external;
}

contract NUXConstants {
    uint constant NUX = 10**18;
}

contract Readable {
    function since(uint _timestamp) internal view returns(uint) {
        if (not(passed(_timestamp))) {
            return 0;
        }
        return block.timestamp - _timestamp;
    }

    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

library ExtraMath {
    function toUInt64(uint _a) internal pure returns(uint64) {
        require(_a <= uint64(-1), 'uint64 overflow');
        return uint64(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= uint128(-1), 'uint128 overflow');
        return uint128(_a);
    }
}

contract EToken2Interface {
    function revokeAsset(bytes32 _symbol, uint _value) public returns(bool);
}

contract NUXAsset is AssetWithAmbi, NUXConstants, Readable {
    using SafeMath for uint;
    using ExtraMath for uint;

    uint public constant PRESALE_RELEASE_PERIOD = 760 days; // ~25 months
    uint64 constant UNSET = uint64(-1);

    struct ReleaseConfig {
        uint64 preSale;
        uint64 publicSale;
        uint64 publicSaleReleasePeriod;
    }

    ReleaseConfig private _releaseConfig = ReleaseConfig(UNSET, UNSET, UNSET);
    
    struct Lock {
        uint128 preSale;
        uint128 publicSale;
    }

    mapping(address => Lock) private _locked;

    event PreSaleLockTransfer(address _from, address _to, uint _value);
    event PublicSaleLockTransfer(address _from, address _to, uint _value);
    event PreSaleReleaseScheduled(uint _releaseStart);
    event PublicSaleReleaseScheduled(uint _releaseStart, uint _releasePeriod);

    modifier onlyRole(bytes32 _role) {
        require(address(ambi2) != address(0) && (ambi2.hasRole(address(this), _role, _sender())),
            'Access denied');
        _;
    }

    modifier validateAvailableBalance(address _sender, uint _value) {
        require(availableBalanceOf(_sender) >= _value, 'Insufficient available balance');
        _;
    }

    modifier validateAllowance(address _from, address _spender, uint _value) {
        require(proxy.allowance(_from, _spender) >= _value, 'Insufficient allowance');
        _;
    }

    function _migrate(address _holder, uint _preSaleLock) private {
        _locked[_holder].preSale = uint128(_preSaleLock);
        emit PreSaleLockTransfer(address(0), _holder, _preSaleLock);
    }

    constructor(address _treasury) public {
        uint128 preSaleLocked = uint128(22000000 * NUX);
        uint128 publicSaleLocked = uint128(6000000 * NUX);
        _locked[_treasury].preSale = preSaleLocked;
        _locked[_treasury].publicSale = publicSaleLocked;
        emit PreSaleLockTransfer(address(0), _treasury, preSaleLocked);
        emit PublicSaleLockTransfer(address(0), _treasury, publicSaleLocked);
        _migrate(0x7b1800B20e87e607b2791282dfF9e069Bb18493c, 244000000000000000000000);
        _migrate(0x3341c7C754C6c2Ebf524D411849D47F87cCD8A7B, 244000000000000000000000);
        _migrate(0x14Ce500a86F1e3aCE039571e657783E069643617, 244000000000000000000000);
        _migrate(0x5cb1D4B99F972cCdecCEFcfeC638d72f9629B5d0, 244000000000000000000000);
        _migrate(0x1ad015A04C3a21330a388f6a0995c7C092E66F93, 244000000000000000000000);
        _migrate(0x1d2d7490BfBa0a80F7A07dD3E369f5824e92b3F5, 200000000000000000000000);
        _migrate(0xc629357ca14A86a3198C5868BDabfe61EC6a6Dda, 195148516000000000000000);
        _migrate(0x9c22d83FB0315263566740d018f08e8c075FC927, 122000000000000000000000);
        _migrate(0xE1eB9cF168DB37c31B4bDf73511Bf44E2B8027Ef, 122000000000000000000000);
        _migrate(0x6fFeCB94FCbB212267a54d39728f7117BDdf9902, 122000000000000000000000);
        _migrate(0x344651A2445484bd2928eB46D2610DaaC1B42A66, 122000000000000000000000);
        _migrate(0x726CDC837384a7Deb8bbea64beba2E7b4d7346c0, 122000000000000000000000);
        _migrate(0x2BA56A2415DEdAaeF2a54a1A6CC90d4555e0000d, 122000000000000000000000);
        _migrate(0x5C239132825898bC0047Ed8A6b347A8a4Ee621eB, 122000000000000000000000);
        _migrate(0x83500F5571F81FF703D014cF05198fe10016b7dB, 97600000000000000000000);
        _migrate(0x46DE6387a065c936740F4eDB08bd42ABEbbb78FD, 73200000000000000000000);
        _migrate(0xe4069c2C2793D2E984A2b9FA2992D158a4d301B3, 69540000000000000000000);
        _migrate(0x2875c17548b538CA87ddce654B82889396376005, 61000000000000000000000);
        _migrate(0x913D74033D61dE00c388e4D30ba5ac016b104F56, 56730000000000000000000);
        _migrate(0x1476d037fbbDd6d632afAE6239c91646b0271656, 51240000000000000000000);
        _migrate(0x61A6007A980C8a8655071AE83930e8B2883e8407, 48800000000000000000000);
        _migrate(0xC8FDcCD9bB285b22a187F179D5EB9bfcA6459C41, 48800000000000000000000);
        _migrate(0x7B662F95cB081d1466fd2387e3F67BB28A98cB1E, 48800000000000000000000);
        _migrate(0xA734871BC0f9d069936db4fA44AeA6d4325F41e5, 48800000000000000000000);
        _migrate(0x53aFEB120eDCE5D778caB7DE76d34F5Fcd92C7d0, 40052000000000000000000);
        _migrate(0x2C1A7E92867BE07F944555c34759A210cb353A44, 36600000000000000000000);
        _migrate(0x27D8519774C77bAb85031463F236c702c7Ee8bD7, 34770000000000000000000);
        _migrate(0xa4317aB9d7DF7453d8E0853415e04f7e3a78f78F, 31720000000000000000000);
        _migrate(0xdB057B29Bc9219388820a438e26C561C16BCa8a1, 29036000000000000000000);
        _migrate(0x533f8B07d95e6eA313de3e3273d8908eBA2f42cA, 26840000000000000000000);
        _migrate(0xFf8A662fAb0745A5032cCF326Fd14b235Fa88C2B, 26840000000000000000000);
        _migrate(0xF25B386D342aE5b9E8cE5Be8D827203bA9321A65, 24400000000000000000000);
        _migrate(0xff5351A95c950964E14579716332eecac0118B20, 24400000000000000000000);
        _migrate(0x0998160bdF3Ff6D86A4E9D5c31e0eFC3Ca7e7D01, 24400000000000000000000);
        _migrate(0x0C25078Bf9F87E804738301e15047A6F3A646473, 24400000000000000000000);
        _migrate(0xe88663F5878Dd0967C905EC8c7Cc65d6d8e091E6, 24400000000000000000000);
        _migrate(0x675F60d68701ed237e19B78152dE1a68f3500e2F, 22916000000000000000000);
        _migrate(0x7f62Fbb8a9E707e44A198584ae2e8Db67cEfC30a, 19764000000000000000000);
        _migrate(0x0D955df946AbE59757eB5Ae31AA50bCB6D3317da, 19520000000000000000000);
        _migrate(0x2f4342CA050c46de579e995C16780dB2E87d0638, 18300000000000000000000);
        _migrate(0x68a313B6774E44beEb0f1Dcc868128b780B2F311, 15000000000000000000000);
        _migrate(0x970815c4ae5CC17d526199AC188A38Dab5324D8e, 12200000000000000000000);
        _migrate(0x951B6d50D07C39b0f97A7bb2F5c1e96F07a093d3, 12200000000000000000000);
        _migrate(0x1f036E4C35A222c8E03355C8E88d1Be1efB9D7D1, 12200000000000000000000);
        _migrate(0x011FAc5fB54c11e361d5120c6E7D52e5BdDEC789, 12200000000000000000000);
        _migrate(0x54640F357199a4E9E1b12E249A7Df9B52BEEfd1a, 10980000000000000000000);
        _migrate(0xEEED73B9A73664C90F58aa63Cb87C87C711AaA04, 9760000000000000000000);
        _migrate(0x767f0b01F6D4d5fcc64367a3a6bEE16fFd3D8f41, 9760000000000000000000);
        _migrate(0x4B4DF3B4c0A893C7BeefE72e1b8DAe7654ae6f47, 8000000000000000000000);
        _migrate(0xFFB3ad2b555dA15eb45CfdC76c43932262f18e68, 7686000000000000000000);
        _migrate(0xB09E89014831adD98273Eb7Dc40e894aADBD9320, 7320000000000000000000);
        _migrate(0xD7F0233f147De4E878C6A57E1B0b7BaAE4aC3516, 7320000000000000000000);
        _migrate(0x362a45cEbd74C06f0e42067134378cd9490b5524, 7320000000000000000000);
        _migrate(0x80c14edC8aD81c91ED5aa053eB2d99d1b97de37F, 7320000000000000000000);
        _migrate(0xE4580938d81F89a22fFD58B2145952D33A67d066, 7320000000000000000000);
        _migrate(0xcE185d79CE13b33a103219A55d88a0BDf9CD3946, 7320000000000000000000);
        _migrate(0x54898c1feb796F2c1ba092F1Cfd31B4c8dA8Ed61, 7198000000000000000000);
        _migrate(0xE10a4C2E6B461d9ad65eD7Cfa371cd3CE5D61Bf0, 7129680000000000000000);
        _migrate(0xe29bE3300909D7620fA9B0b893b8CC99BA334188, 7036960000000000000000);
        _migrate(0xEB5954a418392C4E2af30ab0EF32bc205fCf941B, 6607520000000000000000);
        _migrate(0x082D4eC311D99aE204cf3D193A2023dBc542c1A6, 6588000000000000000000);
        _migrate(0x14B95Ed55C0825A30C5bF6D4905379E06749B117, 6344000000000000000000);
        _migrate(0xd5f1acF04Ba9B20Bd4C6a5046aA4a584e0540D54, 6124400000000000000000);
        _migrate(0xBA3432337151A8abc465512Eafd1189b0b223390, 6100000000000000000000);
        _migrate(0xC77FA6C05B4e472fEee7c0f9B20E70C5BF33a99B, 6100000000000000000000);
        _migrate(0xB7D9945166e3DA89ee4c0947230753d656D116a5, 6100000000000000000000);
        _migrate(0x2b36Ad03207b04941dFBC914f0EBD043bd0a4EB3, 6013341632000000000000);
        _migrate(0x87eA867bDFFD1DdF6D301679DEE2FDA1b9c89eDd, 5831600000000000000000);
        _migrate(0x2f89011A30b3aBBf771B6098d384fEE44Fdee0bB, 5368000000000000000000);
        _migrate(0x3A628624B8dAe402EC1b01c6525C065784717Cb5, 5308078832000000000000);
        _migrate(0xE7FEb2135C91042d6579dB9E770c67DB2C8DeFB7, 5236240000000000000000);
        _migrate(0xcc71ABB11Ead716414A316c4B1121944F293Cc3b, 5124000000000000000000);
        _migrate(0xc7C1d1306f57e9f9c7a4728237Cc7508bcb4a67f, 5109383060000000000000);
        _migrate(0xF82d795132fbA786BBbB385Fb0AA9a990ce91E9d, 5016640000000000000000);
        _migrate(0x0A7A9D35BCf54dea0BabEA88a89A96c5493563B8, 4980040000000000000000);
        _migrate(0xAF27EcE5ACc5a858D6f8c205C5A4AE74cA85E3E3, 4941000000000000000000);
        _migrate(0x61751BC401f4EABe10A238661B4A60ba84910059, 4880000000000000000000);
        _migrate(0xA0D1476011a971B4F63Dd5b2b9Ac1E3F1229bb59, 4880000000000000000000);
        _migrate(0x82d8d99955e38239d865A9dd0D44EF5DD06bA99c, 4880000000000000000000);
        _migrate(0xEed4B9a3B478C554c8c9f14Df47df42bf212E747, 4880000000000000000000);
        _migrate(0x1A942E037Cdfe8098BFaE2a3F181CA22AA6BEaf7, 4880000000000000000000);
        _migrate(0x62d589BCAcCAA636827c5e0209468080ff4577B1, 4880000000000000000000);
        _migrate(0xca1B239F5e5Ef7B68B101A376013afF0EAe28478, 4880000000000000000000);
        _migrate(0x8117C9BE202B0442EFbc79BC81b07F39B148b770, 4880000000000000000000);
        _migrate(0x746E17548B63b0689E054D84a09abe1f5B70672C, 4880000000000000000000);
        _migrate(0xCb114805B901F7a9c38d5675272eF26459a7D805, 4880000000000000000000);
        _migrate(0x52dcBD812598dCD10dA71d65F9AE23A86B15999E, 4880000000000000000000);
        _migrate(0xa52197856025b614Ba5C3F88f5cD8739E09F049e, 4880000000000000000000);
        _migrate(0x53ff4967b854D70067Ffb31d47567D372ddee783, 4880000000000000000000);
        _migrate(0x6ea24f3cDDDF5B88F90B73A2d7df7ad9C0f9BEC4, 4880000000000000000000);
        _migrate(0xb81ab8a53E09e9c430c736d53D455A99C4F8e9Da, 4880000000000000000000);
        _migrate(0xB5806a701c2ae0366e15BDe9bE140E82190fa3d6, 4880000000000000000000);
        _migrate(0x61D988FCF27A988fCA324F1BEc8F57B236A85668, 4636000000000000000000);
        _migrate(0x0B82F2f2FB282bBA35619e16946c15E6B41F44c2, 4538399996000000000000);
        _migrate(0xBb8930FF7dce532260Eb275FafF81CBEdAD11230, 4426160000000000000000);
        _migrate(0xa1aEf6335a2F633cfb1FfEbdA0B5d32AcbC7E873, 4323680000000000000000);
        _migrate(0x1e66350d488ABd437925181Cc3F39A258416EDF4, 4079950476000000000000);
        _migrate(0xF9852FA5db7b62bC7B80Da0a0E408CFe08cED906, 4074800000000000000000);
        _migrate(0x7118Bb4c93b8fCa9273C74AF1d2FE4a923EcdEA9, 4008920000000000000000);
        _migrate(0x93d6711Fad14D498F9000dC4d9361bEf020e2259, 3960120000000000000000);
        _migrate(0xA10039AbC04d165325C5eaF16cb4dBEfF95254F0, 3660000000000000000000);
        _migrate(0xC51Fe3e473CE0Ba53B4cd1e7908b1942c5662A59, 3513600000000000000000);
        _migrate(0x32e49Dda638696B15ea3199DBc7441d18431bE46, 3294000000000000000000);
        _migrate(0x7C3928f5b6cDa431fEDF4a3FA9edEa5E558972E6, 3246331528000000000000);
        _migrate(0x521Af12dC5051e3850a5c44753d90822fb9E03c9, 3233512400000000000000);
        _migrate(0xBEEC08888f8BFAE5193279A2260C590Ad3136844, 2829526076000000000000);
        _migrate(0x1e642C61D03346f103f8f6ed2875E91cF8Ed3893, 2749880000000000000000);
        _migrate(0x02cEf7B37E6c6c70e465787bB92c2D4987Fc33C1, 2691320000000000000000);
        _migrate(0x3edD0DB98AaD6585DF88fe51499C0D20ed1AB2E7, 2684000000000000000000);
        _migrate(0xEa32DD28126DBBf7DEfAE685D1a89D2701058e96, 2562000000000000000000);
        _migrate(0x80986fAbCed53d1a0D5Fc0A3bEC209ce2bfAd4d1, 2562000000000000000000);
        _migrate(0xb676d03c31653d86fd463059783e119dF88e69dE, 2562000000000000000000);
        _migrate(0x49F9Db1961dA0f83E447426cA7b028c3d5893405, 2464400000000000000000);
        _migrate(0x2D7bfbd172d36995FEB8e477E52A744E83B61578, 2440000000000000000000);
        _migrate(0xd985741EC68b7d085d416f63E4362550EECB56fC, 2440000000000000000000);
        _migrate(0x2d3807680493b01A5B4f8a81Fbd23fC8607520C0, 2440000000000000000000);
        _migrate(0x79FD5103674E49e35492f085f10C26097cAdcbEf, 2440000000000000000000);
        _migrate(0xB2001c6827F908AcF72C38e9FDD98085e61E4125, 2440000000000000000000);
        _migrate(0xE9bF0cfdA0E21D2ad1EbF39117053eCC09bd8fD6, 2440000000000000000000);
        _migrate(0x7B8d15015E5B1ad0162f455b3965e7b8481C2678, 2440000000000000000000);
        _migrate(0xF6913cB689336c9aaa27BD9427cC28AA8d9272DF, 2440000000000000000000);
        _migrate(0xb169bf86b353affFAD4E677a413918C9FF80F22F, 2440000000000000000000);
        _migrate(0x190F8418Be383F4B6486Fe39918ECd16fFC47a91, 2440000000000000000000);
        _migrate(0x2f7Ab4f237586304Ba4DeD68620147FE920F204E, 2440000000000000000000);
        _migrate(0x346e02238E9a24fc5e88d28625D1CF38ff6712C2, 2440000000000000000000);
        _migrate(0x8948e76B10612d4C3360917B02EDfA45b56588a9, 2440000000000000000000);
        _migrate(0xad6EE7C40d7D80a6c404E82e77Cde5c5088E98a5, 2440000000000000000000);
        _migrate(0x4BA42b8811d5d50930a8BE400dCBf6Db3264799b, 2440000000000000000000);
        _migrate(0x89604a25FA4d3f30Fde3d767cDbc18F06226df91, 2440000000000000000000);
        _migrate(0xDb8Eb119800a162017E669Ccc5910cd65d6Ff96A, 2440000000000000000000);
        _migrate(0x0D047a6E47C74bD69dE344d030E695f244767066, 2440000000000000000000);
        _migrate(0x389b8Bd4FAc72ff9Aa5fD888a4B3283Ac4c14b28, 2440000000000000000000);
        _migrate(0x607A003232d810790120aFA706D18DDb58653014, 2440000000000000000000);
        _migrate(0x737D1bE798Efa2278FB46807b2ea3ec36397f5da, 2440000000000000000000);
        _migrate(0x9304795B5214504cfde51b5f0951EdC365b7f267, 2440000000000000000000);
        _migrate(0xc74fcc120DC57387C0Ee4972B5C39BE139375eFc, 2440000000000000000000);
        _migrate(0xaf779D1EddB59f1035480Dd377D8187C865c20dA, 2440000000000000000000);
        _migrate(0x0687FDf1617C222fc7EAf72e340e177C616ebF75, 2440000000000000000000);
        _migrate(0x45e37F6C32dF82E128565f24ef2AB9cd27d065ef, 2440000000000000000000);
        _migrate(0xd862b0E73D3f450060e663A324Aee77ffB8E086a, 2440000000000000000000);
        _migrate(0x28B8f3BC25539b0c1336373Ca5B205E9d4A4c126, 2440000000000000000000);
        _migrate(0x68413B4d04876E74b7837f688AAd2bC38eC765a0, 2440000000000000000000);
        _migrate(0xE460ccFF990D88538e45142b6153742763AEf899, 2440000000000000000000);
        _migrate(0x13faf5475DE4BecFa376F4d540C0F7831b88B903, 244000000000000000000);
    }

    function releaseConfig() public view returns(uint, uint, uint) {
        ReleaseConfig memory config = _releaseConfig;
        return (config.preSale, config.publicSale, config.publicSaleReleasePeriod);
    }

    function locked(address _holder) public view returns(uint, uint) {
        Lock memory lock = _locked[_holder];
        return (lock.preSale, lock.publicSale);
    }

    function _calcualteLocked(uint _lock, uint _releaseStart, uint _releasePeriod) private view returns(uint) {
        uint released = (_lock.mul(since(_releaseStart))) / _releasePeriod;
        if (_lock <= released) {
            return 0;
        }
        return _lock - released;
    }

    function availableBalanceOf(address _holder) public view returns(uint) {
        uint totalBalance = proxy.balanceOf(_holder);
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_holder);
        uint preSaleReleaseStart;
        uint publicSaleReleaseStart;
        uint publicSaleReleasePeriod;
        (preSaleReleaseStart, publicSaleReleaseStart, publicSaleReleasePeriod) = releaseConfig();
        preSaleLock = _calcualteLocked(preSaleLock, preSaleReleaseStart, PRESALE_RELEASE_PERIOD);
        publicSaleLock = _calcualteLocked(publicSaleLock, publicSaleReleaseStart, publicSaleReleasePeriod);
        uint stillLocked = preSaleLock.add(publicSaleLock);
        if (totalBalance <= stillLocked) {
            return 0;
        }
        return totalBalance - stillLocked;
    }

    function preSaleScheduleReleaseStart() public onlyRole('admin') {
        require(_releaseConfig.preSale == UNSET, 'Already scheduled');
        uint64 releaseStart = (block.timestamp + 14 days).toUInt64();
        _releaseConfig.preSale = releaseStart;
        emit PreSaleReleaseScheduled(releaseStart);
    }

    function publicSaleScheduleReleaseStart(uint _releaseStart, uint _releasePeriod) public onlyRole('admin') {
        require(_releaseConfig.publicSale == UNSET, 'Already scheduled');
        require(_releaseConfig.publicSaleReleasePeriod == UNSET, 'Already scheduled');
        _releaseConfig.publicSale = (_releaseStart).toUInt64();
        _releaseConfig.publicSaleReleasePeriod = (_releasePeriod).toUInt64();
        emit PublicSaleReleaseScheduled(_releaseStart, _releasePeriod);
    }

    function preSaleTransferLock(address _to, uint _value) public onlyRole('distributor') {
        address _from = _sender();
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(preSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].preSale = (preSaleLock - _value).toUInt128();
        if (_to == address(0)) {
            _burn(_from, _value);
        } else {
            _locked[_to].preSale = uint(_locked[_to].preSale).add(_value).toUInt128();
            require(super._transferWithReference(_to, _value, '', _from), 'Transfer failed');
        }
        emit PreSaleLockTransfer(_from, _to, _value);
    }

    function publicSaleTransferLock(address _to, uint _value) public onlyRole('distributor') {
        address _from = _sender();
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(publicSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].publicSale = (publicSaleLock - _value).toUInt128();
        if (_to == address(0)) {
            _burn(_from, _value);
        } else {
            _locked[_to].publicSale = uint(_locked[_to].publicSale).add(_value).toUInt128();
            require(super._transferWithReference(_to, _value, '', _from), 'Transfer failed');
        }
        emit PublicSaleLockTransfer(_from, _to, _value);
    }

    function _burn(address _from, uint _value) private {
        require(super._transferWithReference(address(this), _value, '', _from), 'Burn transfer failed');
        require(EToken2Interface(proxy.etoken2()).revokeAsset(proxy.etoken2Symbol(), _value), 'Burn failed');
    }

    function _transferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal validateAvailableBalance(_sender, _value) returns(bool) {
        return super._transferWithReference(_to, _value, _reference, _sender);
    }

    function _transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal
    validateAvailableBalance(_from, _value)
    validateAllowance(_from, _sender, _value)
    returns(bool) {
        return super._transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    function _transferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal validateAvailableBalance(_sender, _value) returns(bool) {
        return super._transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    function _transferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal
    validateAvailableBalance(_from, _value)
    validateAllowance(_from, _sender, _value)
    returns(bool) {
        return super._transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }
}