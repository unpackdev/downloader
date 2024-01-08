//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SimpleStream.sol";

/// @title Stream Factory Contract
/// @author ghostffcode
/// @notice Creates instances of SimpleStream for users
contract StreamFactory is AccessControl, Ownable {
    /// @dev user address to stream address mapping
    mapping(address => address) public userStreams;

    /// @dev keep track if user has a stream or not
    mapping(address => User) public users;

    struct User {
        bool hasStream;
    }

    /// @dev StreamAdded event to track the streams after creation
    event StreamAdded(address creator, address user, address stream);

    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");

    /// @dev modifier for the factory manager role
    modifier isPermittedFactoryManager() {
        require(
            hasRole(FACTORY_MANAGER, msg.sender),
            "Not an approved factory manager"
        );
        _;
    }

    constructor(address owner, address[] memory admins) {
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
            _setupRole(FACTORY_MANAGER, admins[i]);
        }
        transferOwnership(owner);
    }

    /// @notice Creates a new stream
    /// @param _toAddress the address of the payee
    /// @param _cap the stream max balance for the period of time
    /// @param _frequency the frequency of the stream
    /// @param _startsFull does the stream start full?
    /// @param _gtc the GTC token address
    function createStreamFor(
        address payable _toAddress,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull,
        IERC20 _gtc
    ) public isPermittedFactoryManager returns (address streamAddress) {
        User storage user = users[_toAddress];
        require(user.hasStream == false, "User already has a stream!");
        user.hasStream = true;
        // deploy a new stream contract
        SimpleStream newStream = new SimpleStream(
            _toAddress,
            _cap,
            _frequency,
            _startsFull,
            _gtc
        );

        streamAddress = address(newStream);

        // map user to new stream
        userStreams[_toAddress] = streamAddress;

        emit StreamAdded(msg.sender, _toAddress, streamAddress);
    }

    /// @notice Add a existing stream to the factory
    /// @param stream the stream contract address
    function addStreamForUser(SimpleStream stream)
        public
        isPermittedFactoryManager
    {
        User storage user = users[stream.toAddress()];
        require(user.hasStream == false, "User already has a stream!");
        address payable _toAddress = stream.toAddress();
        address streamAddress = address(stream);

        userStreams[_toAddress] = streamAddress;

        emit StreamAdded(msg.sender, _toAddress, streamAddress);
    }

    /// @notice returns a stream for a specified user
    /// @param user the user to get a stream for
    function getStreamForUser(address payable user)
        public
        view
        returns (address streamAddress)
    {
        streamAddress = userStreams[user];
    }

    /// @notice Adds a new Factory Manager
    /// @param _newFactoryManager the address of the person you are adding
    function addFactoryManager(address _newFactoryManager) public onlyOwner {
        grantRole(FACTORY_MANAGER, _newFactoryManager);
    }

    function increaseUserStreamCap(address user, uint256 increase)
        public
        isPermittedFactoryManager
    {
        SimpleStream(userStreams[user]).increaseCap(increase);
    }

    function releaseUserStream(address user) public isPermittedFactoryManager {
        SimpleStream(userStreams[user]).transferOwnership(user);
    }
}
