import "./OwnableUpgradeable.sol";
import "./Initializable.sol";


contract FriendTechBridgeBase is OwnableUpgradeable {
    address public constant CROSS_CHAIN_PORTAL = 0x49048044D57e1C92A77f79988d21Fa8fAF74E97e;
    address public constant BASE_RECEIVER = 0x076605D40328237f1fe75BFE5Bf3B3771f6626D9;
    uint64 public constant GAS_LIMIT = 2_000_000;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
    }
}