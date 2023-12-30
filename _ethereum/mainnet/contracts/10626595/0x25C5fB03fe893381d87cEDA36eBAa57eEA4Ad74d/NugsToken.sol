// File: contracts/commons/Ownable.sol

pragma solidity =0.5.10;

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

// File: contracts/commons/StorageUnit.sol

pragma solidity =0.5.10;

contract StorageUnit {
    address private owner;
    mapping(bytes32 => bytes32) private store;

    constructor() public {
        owner = msg.sender;
    }

    function write(bytes32 _key, bytes32 _value) external {
        /* solium-disable-next-line */
        require(msg.sender == owner);
        store[_key] = _value;
    }

    function read(bytes32 _key) external view returns (bytes32) {
        return store[_key];
    }
}

// File: contracts/utils/IsContract.sol

pragma solidity ^0.5.10;


library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
        /* solium-disable-next-line */
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

// File: contracts/utils/DistributedStorage.sol

pragma solidity ^0.5.10;



library DistributedStorage {
    function contractSlot(bytes32 _struct) private view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _struct,
                        keccak256(type(StorageUnit).creationCode)
                    )
                )
            )
        );
    }

    function deploy(bytes32 _struct) private {
        bytes memory slotcode = type(StorageUnit).creationCode;
        /* solium-disable-next-line */
        assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
    }

    function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
    ) internal {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        }

        /* solium-disable-next-line */
        (bool success, ) = address(store).call(
            abi.encodeWithSelector(
                store.write.selector,
                _key,
                _value
            )
        );

        require(success, "error writing storage");
    }

    function read(
        bytes32 _struct,
        bytes32 _key
    ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        }

        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(store).staticcall(
            abi.encodeWithSelector(
                store.read.selector,
                _key
            )
        );

        require(success, "error reading storage");
        return abi.decode(data, (bytes32));
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity ^0.5.10;


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/utils/Math.sol

pragma solidity ^0.5.10;


library Math {
    function orderOfMagnitude(uint256 input) internal pure returns (uint256){
        uint256 counter = uint(-1);
        uint256 temp = input;

        do {
            temp /= 10;
            counter++;
        } while (temp != 0);

        return counter;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a > _b) {
            return _a;
        } else {
            return _b;
        }
    }
}

// File: contracts/utils/GasPump.sol

pragma solidity ^0.5.10;


contract GasPump {
    bytes32 private stub;

    modifier requestGas(uint256 _factor) {
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) {
            uint256 startgas = gasleft();
            _;
            uint256 delta = startgas - gasleft();
            uint256 target = (delta * _factor) / 100;
            startgas = gasleft();
            while (startgas - gasleft() < target) {
                // Burn gas
                stub = keccak256(abi.encodePacked(stub));
            }
        } else {
            _;
        }
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity =0.5.10;


interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

// File: contracts/commons/AddressMinHeap.sol

pragma solidity =0.5.10;

/*
    @author Agustin Aguilar <agusxrun@gmail.com>
*/


library AddressMinHeap {
    using AddressMinHeap for AddressMinHeap.Heap;

    struct Heap {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Heap storage _heap) internal {
        require(_heap.entries.length == 0, "already initialized");
        _heap.entries.push(0);
    }

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
        /* solium-disable-next-line */
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
        /* solium-disable-next-line */
        assembly {
            let entryAsm := not(_entry)
            _addr := and(entryAsm, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, entryAsm)
        }
    }

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
        /* solium-disable-next-line */
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function top(Heap storage _heap) internal view returns(address, uint256) {
        if (_heap.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_heap.entries[1]);
    }

    function has(Heap storage _heap, address _addr) internal view returns (bool) {
        return _heap.index[_addr] != 0;
    }

    function size(Heap storage _heap) internal view returns (uint256) {
        return _heap.entries.length - 1;
    }

    function entry(Heap storage _heap, uint256 _i) internal view returns (address, uint256) {
        return decode(_heap.entries[_i + 1]);
    }

    // RemoveMax pops off the root element of the heap (the highest value here) and rebalances the heap
    function popTop(Heap storage _heap) internal returns(address _addr, uint256 _value) {
        // Ensure the heap exists
        uint256 heapLength = _heap.entries.length;
        require(heapLength > 1, "The heap does not exists");

        // take the root value of the heap
        (_addr, _value) = decode(_heap.entries[1]);
        _heap.index[_addr] = 0;

        if (heapLength == 2) {
            _heap.entries.length = 1;
        } else {
            // Takes the last element of the array and put it at the root
            uint256 val = _heap.entries[heapLength - 1];
            _heap.entries[1] = val;

            // Delete the last element from the array
            _heap.entries.length = heapLength - 1;

            // Start at the top
            uint256 ind = 1;

            // Bubble down
            ind = _heap.bubbleDown(ind, val);

            // Update index
            _heap.index[decodeAddress(val)] = ind;
        }
    }

    // Inserts adds in a value to our heap.
    function insert(Heap storage _heap, address _addr, uint256 _value) internal {
        require(_heap.index[_addr] == 0, "The entry already exists");

        // Add the value to the end of our array
        uint256 encoded = encode(_addr, _value);
        _heap.entries.push(encoded);

        // Start at the end of the array
        uint256 currentIndex = _heap.entries.length - 1;

        // Bubble Up
        currentIndex = _heap.bubbleUp(currentIndex, encoded);

        // Update index
        _heap.index[_addr] = currentIndex;
    }

    function update(Heap storage _heap, address _addr, uint256 _value) internal {
        uint256 ind = _heap.index[_addr];
        require(ind != 0, "The entry does not exists");

        uint256 can = encode(_addr, _value);
        uint256 val = _heap.entries[ind];
        uint256 newInd;

        if (can < val) {
            // Bubble down
            newInd = _heap.bubbleDown(ind, can);
        } else if (can > val) {
            // Bubble up
            newInd = _heap.bubbleUp(ind, can);
        } else {
            // no changes needed
            return;
        }

        // Update entry
        _heap.entries[newInd] = can;

        // Update index
        if (newInd != ind) {
            _heap.index[_addr] = newInd;
        }
    }

    function bubbleUp(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble up
        ind = _ind;
        if (ind != 1) {
            uint256 parent = _heap.entries[ind / 2];
            while (parent < _val) {
                // If the parent value is lower than our current value, we swap them
                (_heap.entries[ind / 2], _heap.entries[ind]) = (_val, parent);

                // Update moved Index
                _heap.index[decodeAddress(parent)] = ind;

                // change our current Index to go up to the parent
                ind = ind / 2;
                if (ind == 1) {
                    break;
                }

                // Update parent
                parent = _heap.entries[ind / 2];
            }
        }
    }

    function bubbleDown(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble down
        ind = _ind;

        uint256 lenght = _heap.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {
            // get the current index of the children
            uint256 j = ind * 2;

            // left child value
            uint256 leftChild = _heap.entries[j];

            // Store the value of the child
            uint256 childValue;

            if (target > j) {
                // The parent has two childs 👨‍👧‍👦

                // Load right child value
                uint256 rightChild = _heap.entries[j + 1];

                // Compare the left and right child.
                // if the rightChild is greater, then point j to it's index
                // and save the value
                if (leftChild < rightChild) {
                    childValue = rightChild;
                    j = j + 1;
                } else {
                    // The left child is greater
                    childValue = leftChild;
                }
            } else {
                // The parent has a single child 👨‍👦
                childValue = leftChild;
            }

            // Check if the child has a lower value
            if (_val > childValue) {
                break;
            }

            // else swap the value
            (_heap.entries[ind], _heap.entries[j]) = (childValue, _val);

            // Update moved Index
            _heap.index[decodeAddress(childValue)] = ind;

            // and let's keep going down the heap
            ind = j;
        }
    }
}

// File: contracts/Heap.sol

pragma solidity =0.5.10;



contract Heap is Ownable {
    using AddressMinHeap for AddressMinHeap.Heap;

    // heap
    AddressMinHeap.Heap private heap;

    // Heap events
    event JoinHeap(address indexed _address, uint256 _balance, uint256 _prevSize);
    event LeaveHeap(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 public constant TOP_SIZE = 420;

    constructor() public {
        heap.initialize();
    }

    function topSize() external pure returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) external view returns (address addr) {
        (addr, ) = heap.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return heap.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return heap.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return heap.top();
    }

    function size() external view returns (uint256) {
        return heap.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = heap.size();

        // If the heap is empty
        // join the _addr
        if (_size == 0 && _new != 0) {
            emit JoinHeap(_addr, _new, 0);
            heap.insert(_addr, _new);
            return;
        }

        // Load top value of the heap
        (, uint256 lastBal) = heap.top();

        // If our target address already is in the heap
        if (heap.has(_addr)) {
            // Update the target address value
            heap.update(_addr, _new);
            // If the new value is 0
            // always pop the heap
            // we updated the heap, so our address should be on top
            if (_new == 0) {
                heap.popTop();
                emit LeaveHeap(_addr, 0, _size);
            }
        } else {
            // IF heap is full or new balance is higher than pop heap
            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
                // If heap is full pop heap
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = heap.popTop();
                    emit LeaveHeap(_poped, _balance, _size);
                }

                // Insert new value
                heap.insert(_addr, _new);
                emit JoinHeap(_addr, _new, _size);
            }
        }
    }
}

// File: contracts/NugsToken.sol

pragma solidity =0.5.10;









interface Pauseable {
    function unpause() external;
}


contract NugsToken is Ownable, GasPump, IERC20, Pauseable {

    using DistributedStorage for bytes32;
    using SafeMath for uint256;

    // Lottery events
    event Winner(address indexed _addr, uint256 _value);

    // Managment events

    event SetWhitelistedFrom(address _addr, bool _whitelisted);
    event SetWhitelistedTo(address _addr, bool _whitelisted);
    event SetBlacklistedLottery(address _addr, bool _whitelisted);

    event SetFromAddressFee(address _addr, uint256 _fee);
    event SetToAddressFee(address _addr, uint256 _fee);

    uint256 public totalSupply = 420000000 * 10 ** 18;

    bytes32 private constant BALANCE_KEY = keccak256("balance");

    uint256 public constant DEFAULT_FEE = 200;	// 0.5%
    uint256 public constant CALLER_REWARD_FEE = 50;	// 2%

    uint256 public periodSeconds = 86400;	// seconds in 24h

    uint256 public periodOffset = (20*60+20)*60;	// 20H20 UTC == 4h20 Beijing in Summer time

    // metadata
    string public constant name = "Nugs Token";
    string public constant symbol = "NUGS";
    uint8 public constant decimals = 18;

    // custom fees for a few addresses, like badactor contracts
    mapping(address => uint256) public fromAddressFees;
    mapping(address => uint256) public toAddressFees;

    // Whitelisted addresses pay no fees, i.e. exchanges
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    // blacklisted lottery addresses do not received lottery winnings
    mapping(address => bool) public blacklistLottery;

    bool public paused = true;

    // heap
    Heap public heap;

    // internal
    bool public inited;
    uint256 public lastWinnerPeriod;

    address pauseMover;

    function init( address _to) external {
        // Only init once
        assert(!inited);
        inited = true;

        // Sanity checks
        assert(address(heap) == address(0));

        // Create Heap
        heap = new Heap();

        // Init contract variables and mint
        // entire token balance
        emit Transfer(address(0), _to, totalSupply);
        _setBalance(_to, totalSupply);

        lastWinnerPeriod = _getCurrentPeriod();
    }


    ///
    // initial token pause
    ///

    function unpause() external {
        require(msg.sender == owner || msg.sender == pauseMover, "only owner or pauser");
        paused = false;
    }

    function setPauseMover(address _addr)  external {
        require(msg.sender == owner || msg.sender == pauseMover, "only owner or pauser");
        pauseMover = _addr;
    }

    ///
    // Storage access functions
    ///

    // Getters

    function _toKey(address a) internal pure returns (bytes32) {
        return bytes32(uint256(a));
    }

    function _balanceOf(address _addr) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(BALANCE_KEY));
    }

    function _allowance(address _addr, address _spender) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("allowance", _spender))));
    }

    function _nonce(address _addr, uint256 _cat) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("nonce", _cat))));
    }

    // Setters

    function _setAllowance(address _addr, address _spender, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("allowance", _spender)), bytes32(_value));
    }

    function _setNonce(address _addr, uint256 _cat, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("nonce", _cat)), bytes32(_value));
    }

    function _setBalance(address _addr, uint256 _balance) internal {
        assert(_addr != address(0));    // should never happen
        _toKey(_addr).write(BALANCE_KEY, bytes32(_balance));
        // lottery pot (this contract) address doesnt enter lottery
        if (!blacklistLottery[_addr] && _addr != address(this))
            heap.update(_addr, _balance);
    }


    ///
    // Lottery external methods
    ///

    function isTopHolder(address _addr) external view returns (bool) {
        return heapHas(_addr);
    }

    // any user can call and earn rewards
    function doLottery() external {
        require(paused == false  || msg.sender == owner || msg.sender == pauseMover, "transfers are still paused");

        require(heapHas(msg.sender), "Only one of the 420 top holders may raid the stash!");
        uint256 thisPeriod = _getCurrentPeriod();
        // should  never be <
        require(thisPeriod > lastWinnerPeriod, "Not time to raid the stash yet!");
        lastWinnerPeriod = lastWinnerPeriod.add(1);
        _doLottery(msg.sender);
    }


    ///
    // Internal methods
    ///

    function _isWhitelistedTransfer(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function _random(address _s1, uint256 _s2, uint256 _s3, uint256 _max) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_s1, _s2, _s3)));
        return rand % (_max + 1);
    }

    function _pickWinner(address _from, uint256 _value) internal returns (address) {
        // Get order of magnitude of the tx
        uint256 magnitude = Math.orderOfMagnitude(_value);
        // Pull nonce for a given order of magnitude
        uint256 nonce = _nonce(_from, magnitude);
        _setNonce(_from, magnitude, nonce + 1);
        // pick entry from heap
        uint256 hsize = heap.size();
        require(hsize != 0, "no holders whitelisted for lottery"); // should never happen in the wild
        return heap.addressAt(_random(_from, nonce, magnitude, hsize - 1));
    }

    function _doLottery(address _from) internal {
        // Pick winner pseudo-randomly
        address selfAddress = address(this);
        uint256 lotteryAmount = _balanceOf(selfAddress);
        address winner = _pickWinner(_from, lotteryAmount);
        require(lotteryAmount != 0, "nothing to raid yet");

        // reward caller
        uint256 callerReward = lotteryAmount.divRound(CALLER_REWARD_FEE);
       _setBalance(_from, _balanceOf(_from).add(callerReward));
        emit Transfer(selfAddress, _from, callerReward);

        // Transfer balance to winner
        uint256 lotteryWinnings = lotteryAmount.sub(callerReward);
        _setBalance(winner, _balanceOf(winner).add(lotteryWinnings));
        emit Winner(winner, lotteryWinnings);
        emit Transfer(selfAddress, winner, lotteryWinnings);
    }

    function _transferFrom(address _operator, address _from, address _to, uint256 _value, bool _payFee) internal {
        require(_to != address(0), "transfers to 0x0 not allowed");
        require(paused == false  || msg.sender == owner || msg.sender == pauseMover, "transfers are still paused");

        // If transfer amount is zero
        // emit event and stop execution
        if (_value == 0) {
            emit Transfer(_from, _to, 0);
            return;
        }

        // Load sender balance
        uint256 balanceFrom = _balanceOf(_from);
        require(balanceFrom >= _value, "balance not enough");

        // Check if operator is sender
        if (_from != _operator) {
            // If not, validate allowance
            uint256 allowanceFrom = _allowance(_from, _operator);
            // If allowance is not 2 ** 256 - 1, consume allowance
            if (allowanceFrom != uint(-1)) {
                // Check allowance and save new one
                require(allowanceFrom >= _value, "allowance not enough");
                _setAllowance(_from, _operator, allowanceFrom.sub(_value));
            }
        }

        // Calculate receiver balance
        // initial receive is full value
        uint256 receiveVal = _value;
        uint256 burnAmount = 0;
        uint256 lott = 0;

        // Change sender balance
        _setBalance(_from, balanceFrom.sub(_value));

        // If the transaction is not whitelisted
        // or if sender requested to pay the fee
        // calculate fees
        if (_payFee || !_isWhitelistedTransfer(_from, _to)) {
            uint256 fee = DEFAULT_FEE;
            if (fromAddressFees[_from] != 0)
                fee = fromAddressFees[_from];
            if (toAddressFees[_to] != 0 && toAddressFees[_to] < fee) // *higher* fee
                fee = toAddressFees[_to];

            // Fee is the same for BURN and LOTT
            // If we are sending value one
            // give priority to BURN
            burnAmount = _value.divRound(fee);
            lott = _value == 1 ? 0 : burnAmount;

            // Subtract fees from receiver amount
            receiveVal = receiveVal.sub(burnAmount.add(lott));

            // Burn tokens. same as ERC20Burnable from OpenZepplin
            totalSupply = totalSupply.sub(burnAmount);
            emit Transfer(_from, address(0), burnAmount);

            // Keep lottery amount until it's time for the lottery
            address selfAddress = address(this);
            // Transfer balance to winner
            _setBalance(selfAddress, _balanceOf(selfAddress).add(lott));
            emit Transfer(_from, selfAddress, lott);
        }

        // Sanity checks
        // no tokens where created
        assert(burnAmount.add(lott).add(receiveVal) == _value);

        // Add tokens to receiver
        _setBalance(_to, _balanceOf(_to).add(receiveVal));
        emit Transfer(_from, _to, receiveVal);
    }

    ///
    // Managment
    ///

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit SetWhitelistedTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit SetWhitelistedFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function setBlacklistedLottery(address _addr, bool _blacklisted) external onlyOwner {
        emit SetBlacklistedLottery(_addr, _blacklisted);
        blacklistLottery[_addr] = _blacklisted;
        if (_blacklisted)
            heap.update(_addr, 0);	// pops address from heap, if it's there
    }

    function setToAddressFee(address _addr, uint256 _fee) external onlyOwner {
        emit SetToAddressFee(_addr, _fee);
        toAddressFees[_addr] = _fee;
    }

    function setFromAddressFee(address _addr, uint256 _fee) external onlyOwner {
        emit SetFromAddressFee(_addr, _fee);
        fromAddressFees[_addr] = _fee;
    }

    // days since epoch 1/1/1970 + offset of/to 20:20 UTC (4:20 beijing time)
    function _getCurrentPeriod() internal view returns(uint256) {
        return block.timestamp.sub(periodOffset).div(periodSeconds);
    }


    /////
    // Heap methods
    /////

    function heapHas(address _addr) internal view returns (bool) {
        return heap.indexOf(_addr) != 0;
    }

    function topSize() external view returns (uint256) {
        return heap.topSize();
    }

    function heapSize() external view returns (uint256) {
        return heap.size();
    }

    function heapEntry(uint256 _i) external view returns (address, uint256) {
        return heap.entry(_i);
    }

    function heapTop() external view returns (address, uint256) {
        return heap.top();
    }

    function heapIndex(address _addr) external view returns (uint256) {
        return heap.indexOf(_addr);
    }

    function getNonce(address _addr, uint256 _cat) external view returns (uint256) {
        return _nonce(_addr, _cat);
    }

    /////
    // ERC20
    /////

    function balanceOf(address _addr) external view returns (uint256) {
        return _balanceOf(_addr);
    }

    function allowance(address _addr, address _spender) external view returns (uint256) {
        return _allowance(_addr, _spender);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        _setAllowance(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external  returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, false);
        return true;
    }

    function transferWithFee(address _to, uint256 _value) external  returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, true);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, false);
        return true;
    }

    function transferFromWithFee(address _from, address _to, uint256 _value) external  returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, true);
        return true;
    }
}