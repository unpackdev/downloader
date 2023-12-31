pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal virtual pure returns (uint256);

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[16] private ______gap;
}

contract Ownable {
    /** events */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** member */

    address public owner;

    /** constructor */

    function initializeOwnable(address _owner) internal {
        owner = _owner;
    }

    /** modifers */

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable.onlyOwner.EID00001");
        _;
    }

    /** functions */
    
    function transferOwnership(address _owner) public onlyOwner {
        require(_owner != address(0), "Ownable.transferOwnership.EID00090");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }
}

contract Orderbase is Ownable, VersionedInitializable {
    event Insert(address indexed owner, address indexed token, uint256 id);

    struct hold_t {
        address owner;
        address token;
    }
    uint256 public size;
    //id => hold_t
    mapping(uint256 => hold_t) private _holds; //@_indexes start with 1
    //owner => token => id;
    mapping(address => mapping(address => uint256)) private _indexes;
    //token => owners
    mapping(address => address[]) private _owners;
    //owner => tokens
    mapping(address => address[]) private _tokens;

    function getRevision() internal override pure returns (uint256) {
        return uint256(0x1);
    }

    function initialize(address owner) public initializer {
        Ownable.initializeOwnable(owner);
    }

    function insert(address _owner, address _token) public returns (uint256) {
        uint256 _id = _indexes[_owner][_token];
        if (_id == 0) {
            ++size;
            _holds[size] = hold_t(_owner, _token);
            _indexes[_owner][_token] = size;
            _owners[_token].push(_owner);
            _tokens[_owner].push(_token);
            emit Insert(_owner, _token, size);
            return size;
        }
        return _id;
    }
    
    function holder(uint256 id) public view returns (address, address) {
        return (_holds[id].owner, _holds[id].token);
    }

    //csa-index
    function index(address _owner, address _token) public view returns (uint256) {
        return _indexes[_owner][_token];
    }

    function owners(
        address token,
        uint256 begin, //@begin start with 0
        uint256 end
    ) public view returns (address[] memory) {
        address[] memory sources = _owners[token];
        address[] memory values;
        (uint256 _begin, uint256 _end) = (begin, end);

        if (begin >= end) return values;
        if (begin >= sources.length) return values;
        if (_end > sources.length) {
            _end = sources.length;
        }

        values = new address[](_end - begin);
        uint256 i = 0;
        for (; _begin != _end; ++_begin) {
            values[i++] = sources[_begin];
        }
        return values;
    }

    function owners(address _token) public view returns (address[] memory) {
        return _owners[_token];
    }

    function tokens(address _owner) public view returns (address[] memory) {
        return _tokens[_owner];
    }
}