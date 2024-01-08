//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";

import "./AccessControlEnumerableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./ContextUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./console.sol";

contract Controller is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    event OrganizationCreated(uint256 organization, Organization attributes);
    event OrganizationModified(uint256 organization, Organization attributes);
    event OrganizationRemoved(uint256 organization);

    event SeatGranted(uint256 indexed organization, Seat seat);
    event SeatModified(uint256 indexed organization, Seat seat);
    event SeatRevoked(uint256 indexed organization, address wallet);

    event OrganizationAdminGranted(
        uint256 indexed organization,
        address wallet
    );
    event OrganizationAdminRevoked(
        uint256 indexed organization,
        address wallet
    );

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Organization {
        string name;
        uint256 seats;
        bool active;
    }

    struct Seat {
        string name;
        address wallet;
        string metadata;
        bool admin;
    }

    CountersUpgradeable.Counter private _organizationIds;

    bytes32 public constant MONEGRAPH_ROLE = keccak256("MONEGRAPH_ROLE");

    mapping(uint256 => Organization) private organizations;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet)
        private organizationUsers;
    mapping(address => uint256) private seats;

    modifier organizationExists(address wallet) {
        uint256 id = seats[wallet];
        require(id != 0, "Wallet does not belong to an organization");
        require(
            organizations[id].active,
            "Invalid organization identifier passed"
        );
        _;
    }

    modifier isOrganizationAdmin(address wallet) {
        uint256 id = seats[wallet];

        require(id != 0, "Wallet is not assigned to an organization");
        require(
            hasRole(
                keccak256(abi.encodePacked("org.", uint2str(id), ".admin")),
                wallet
            ),
            "Wallet is not an organization admin"
        );

        _;
    }

    function initialize() public virtual initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MONEGRAPH_ROLE, _msgSender());

        _organizationIds.increment();
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function addOrganization(Organization memory organization, Seat memory seat)
        external
        onlyRole(MONEGRAPH_ROLE)
    {
        require(organization.seats > 0, "Invalid seat number");

        require(
            seats[seat.wallet] == 0,
            "Wallet already belongs to an organization"
        );

        uint256 orgId = _organizationIds.current();

        organization.active = true;

        organizations[orgId] = organization;
        seats[seat.wallet] = orgId;
        organizationUsers[orgId].add(seat.wallet);

        seat.admin = true;

        bytes32 adminRole = keccak256(
            abi.encodePacked("org.", uint2str(orgId), ".admin")
        );

        _setRoleAdmin(adminRole, adminRole);
        _setupRole(adminRole, seat.wallet);

        emit OrganizationCreated(orgId, organization);

        emit SeatGranted(orgId, seat);

        emit OrganizationAdminGranted(orgId, seat.wallet);

        _organizationIds.increment();
    }

    function removeOrganization(uint256 id) external onlyRole(MONEGRAPH_ROLE) {
        organizations[id].active = false;

        emit OrganizationRemoved(id);
    }

    function modifyOrganization(uint256 id, Organization memory edited)
        external
        onlyRole(MONEGRAPH_ROLE)
    {
        Organization storage organization = organizations[id];

        require(organization.seats > 0, "Invalid organization identifier");

        require(edited.seats > 0, "Invalid seat number");

        require(
            organizationUsers[id].length() <= edited.seats,
            "Seat change would be less than currently occupied"
        );

        organization.seats = edited.seats;
        organization.active = edited.active;
        organization.name = edited.name;

        organizations[id] = organization;

        emit OrganizationModified(id, organization);
    }

    function addOrganizationAdmin(address wallet)
        public
        organizationExists(_msgSender())
        organizationExists(wallet)
        isOrganizationAdmin(_msgSender())
    {
        uint256 id = seats[wallet];
        bytes32 adminRole = keccak256(
            abi.encodePacked("org.", uint2str(id), ".admin")
        );
        grantRole(adminRole, wallet);
        emit OrganizationAdminGranted(id, wallet);
    }

    function removeOrganizationAdmin(address wallet)
        public
        organizationExists(_msgSender())
        isOrganizationAdmin(_msgSender())
    {
        uint256 id = seats[wallet];
        bytes32 adminRole = keccak256(
            abi.encodePacked("org.", uint2str(id), ".admin")
        );
        revokeRole(adminRole, wallet);
        emit OrganizationAdminRevoked(id, wallet);
    }

    function addSeat(Seat memory seat)
        external
        organizationExists(_msgSender())
        isOrganizationAdmin(_msgSender())
    {
        uint256 id = seats[_msgSender()];
        uint256 userOrg = seats[seat.wallet];

        Organization storage organization = organizations[id];
        Organization memory userOrganization = organizations[userOrg];

        require(
            userOrg == 0 || userOrganization.active == false,
            "Wallet already belongs to an organization"
        );

        require(
            organization.seats >= organizationUsers[id].length() + 1,
            "Organization has exhausted available seats"
        );

        organizationUsers[id].add(seat.wallet);
        seats[seat.wallet] = id;

        emit SeatGranted(id, seat);

        if (seat.admin) {
            addOrganizationAdmin(seat.wallet);
        } else {
            removeOrganizationAdmin(seat.wallet);
        }
    }

    function modifySeat(Seat memory seat)
        external
        organizationExists(_msgSender())
    {
        uint256 id = seats[_msgSender()];
        uint256 seatId = seats[seat.wallet];
        bytes32 adminRole = keccak256(
            abi.encodePacked("org.", uint2str(id), ".admin")
        );
        bool isAdmin = hasRole(adminRole, seat.wallet);

        require(id == seatId, "Attempting to modify an unowned seat");

        emit SeatModified(id, seat);

        if (isAdmin == true && seat.admin == false) {
            removeOrganizationAdmin(seat.wallet);
        } else if (isAdmin == false && seat.admin == true) {
            addOrganizationAdmin(seat.wallet);
        }
    }

    function removeSeat(address wallet)
        external
        organizationExists(_msgSender())
        isOrganizationAdmin(_msgSender())
    {
        uint256 id = seats[_msgSender()];
        bytes32 adminRole = keccak256(
            abi.encodePacked("org.", uint2str(id), ".admin")
        );

        require(
            organizationUsers[id].contains(wallet),
            "This wallet is not associated with a seat"
        );

        require(
            organizationUsers[id].length() > 0,
            "Removing this seat would leave the organization without any seats"
        );

        if (hasRole(adminRole, wallet)) {
            require(
                getRoleMemberCount(adminRole) > 1,
                "Removing this seat would leave the organization without any admins"
            );

            removeOrganizationAdmin(wallet);
        }

        organizationUsers[id].remove(wallet);
        seats[wallet] = 0;

        emit SeatRevoked(id, wallet);
    }

    function getOrganization(address wallet)
        external
        view
        returns (Organization memory)
    {
        return organizations[seats[wallet]];
    }

    function hasSeat(address wallet) public view returns (bool) {
        return seats[wallet] != 0;
    }

    function canCreateCollections(address wallet) external view returns (bool) {
        return hasSeat(wallet);
    }

    function canCreateAuctions(address wallet) external view returns (bool) {
        return hasSeat(wallet);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
