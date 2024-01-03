import "./ENS.sol";
import "./IBaseRegistrar.sol";
import "./ERC721.sol";

interface IRemiliasRegistrar is IERC721 {
    error NotStarted();
    error Unavailable();
    error UnauthorizedOwner();
    error UnauthorizedController();

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        address indexed collection,
        uint256 nft
    );
    event NameRenewed(uint256 indexed id, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns true if the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address collection, uint256 nft) external;

    function resetOwner(uint256 id) external;

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}
