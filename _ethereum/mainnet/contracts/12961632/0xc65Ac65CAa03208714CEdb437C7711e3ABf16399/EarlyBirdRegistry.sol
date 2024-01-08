//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

import "./IEarlyBirdRegistry.sol";

/// @title EarlyBirdRegistry
/// @author Simon Fremaux (@dievardump)
contract EarlyBirdRegistry is IEarlyBirdRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    event ProjectCreated(
        address indexed creator,
        uint256 indexed projectId,
        uint256 endRegistration, // when the registration ends
        uint256 maxRegistration, // how many people can register
        bool open // if the project accepts Open Registration
    );

    event Registration(uint256 indexed projectId, address[] list);

    struct Project {
        bool open;
        address creator;
        uint256 endRegistration;
        uint256 maxRegistration;
    }

    // this is a counter that increments automatically when registering an Early Bird Project
    uint256 lastProjectId;

    // list of all projects
    mapping(uint256 => Project) public projects;

    // list of registered address for a project
    mapping(uint256 => EnumerableSet.AddressSet) internal _registered;

    modifier onlyProject(uint256 projectId) {
        require(exists(projectId), 'Unknown project id.');
        _;
    }

    constructor() {}

    /// @notice allows anyone to register a new project that accepts Early Birds registrations
    /// @param open if the early bird registration is open or only creator can register addresses
    /// @param endRegistration unix epoch timestamp of registration closing
    /// @param maxRegistration the max registration count
    /// @return projectId the project Id (useful if called by a contract)
    function registerProject(
        bool open,
        uint256 endRegistration,
        uint256 maxRegistration
    ) external override returns (uint256 projectId) {
        projectId = lastProjectId + 1;
        lastProjectId = projectId;

        projects[projectId] = Project({
            open: open,
            creator: msg.sender,
            endRegistration: endRegistration,
            maxRegistration: maxRegistration
        });

        emit ProjectCreated(
            msg.sender,
            projectId,
            endRegistration,
            maxRegistration,
            open
        );
    }

    /// @notice tells if a project exists
    /// @param projectId project id to check
    /// @return true if the project exists
    function exists(uint256 projectId) public view override returns (bool) {
        return projectId > 0 && projectId <= lastProjectId;
    }

    /// @notice Helper to paginate all address registered for a project
    ///         Using pagination just in case it ever happens that there are much EarlyBirds
    /// @param projectId the project id
    /// @param offset index where to start
    /// @param limit how many to grab
    /// @return list of registered addresses
    function listRegistrations(
        uint256 projectId,
        uint256 offset,
        uint256 limit
    )
        external
        view
        override
        onlyProject(projectId)
        returns (address[] memory list)
    {
        EnumerableSet.AddressSet storage registered = _registered[projectId];

        uint256 count = registered.length();

        require(offset < count, 'Offset too high');

        if (count < offset + limit) {
            limit = count - offset;
        }

        list = new address[](limit);
        for (uint256 i; i < limit; i++) {
            list[i] = registered.at(offset + i);
        }
    }

    /// @notice Helper to know how many address registered to a project
    /// @param projectId the project id
    /// @return how many people registered
    function registeredCount(uint256 projectId)
        external
        view
        override
        onlyProject(projectId)
        returns (uint256)
    {
        return _registered[projectId].length();
    }

    /// @notice Small helpers that returns in how many seconds a project registration ends
    /// @param projectId to check
    /// @return the time in second before end; 0 if ended
    function registrationEndsIn(uint256 projectId)
        public
        view
        returns (uint256)
    {
        if (projects[projectId].endRegistration <= block.timestamp) {
            return 0;
        }

        return projects[projectId].endRegistration - block.timestamp;
    }

    /// @notice Helper to check if an address is registered for a project id
    /// @param check the address to check
    /// @param projectId the project id
    /// @return if the address was registered as an early bird
    function isRegistered(address check, uint256 projectId)
        external
        view
        override
        onlyProject(projectId)
        returns (bool)
    {
        return _registered[projectId].contains(check);
    }

    /// @notice Allows the creator of a project to change registration open state
    ///         this can be usefull to first register a specific list of addresses
    ///         before making the registration public
    /// @param projectId to modify
    /// @param open if the project is open to anyone or only creator can change
    function setRegistrationOpen(uint256 projectId, bool open) external {
        require(
            msg.sender == projects[projectId].creator,
            'Not project creator.'
        );
        projects[projectId].open = open;
    }

    /// @notice Allows a user to register for an EarlyBird spot on a project
    /// @dev the project needs to be "open" for people to register directly to it
    /// @param projectId the project id to register to
    function registerTo(uint256 projectId) external onlyProject(projectId) {
        Project memory project = projects[projectId];
        require(project.open == true, 'Project not open.');

        EnumerableSet.AddressSet storage registered = _registered[projectId];
        require(
            // before end registration time
            block.timestamp <= project.endRegistration &&
                // and there is still available spots
                registered.length() + 1 <= project.maxRegistration,
            'Registration closed.'
        );

        require(!registered.contains(msg.sender), 'Already registered');

        // add user to list
        registered.add(msg.sender);

        address[] memory list = new address[](1);
        list[0] = msg.sender;

        emit Registration(projectId, list);
    }

    /// @notice Allows a project creator to add early birds in Batch
    /// @dev msg.sender must be the projectId creator
    /// @param projectId to add to
    /// @param birds all addresses to add
    function registerBatchTo(uint256 projectId, address[] memory birds)
        external
        override
    {
        Project memory project = projects[projectId];

        require(msg.sender == project.creator, 'Not project creator.');

        uint256 count = birds.length;
        EnumerableSet.AddressSet storage registered = _registered[projectId];
        // before end registration time
        require(
            block.timestamp <= project.endRegistration,
            'Registration closed.'
        );

        // and there is still enough available spots
        require(
            registered.length() + count <= project.maxRegistration,
            'Not enough spots.'
        );

        for (uint256 i; i < count; i++) {
            registered.add(birds[i]);
        }

        emit Registration(projectId, birds);
    }
}
