// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IMemberships.sol";
import "./IMembershipsFactory.sol";
import "./MembershipsProxy.sol";

/// @title MembershipsFactory
/// @notice Factory contract that can deploy Memberships proxies
/// @author Coinvise
contract MembershipsFactory is Ownable, IMembershipsFactory {
    using SafeERC20 for IERC20;

    /// @notice Emitted when trying to set `memberships` to zero address
    error InvalidMemberships();

    /// @notice Emitted when trying to set `feeTreasury` to zero address
    error InvalidFeeTreasury();

    /// @notice Emitted when a proxy is being upgraded by other than proxy owner
    error Unauthorized();

    /// @notice Emitted when performing an invalid upgrade
    /// @param currentVersion current version of Memberships proxy
    /// @param upgradeToVersion version to upgrade the proxy to
    /// @param membershipsLatestVersion latest version of Memberships implementation
    error InvalidUpgrade(uint16 currentVersion, uint16 upgradeToVersion, uint16 membershipsLatestVersion);

    /// @notice Emitted when a Memberships proxy is deployed
    /// @param membershipsProxy address of the newly deployed proxy
    /// @param owner owner of the newly deployed proxy
    /// @param implementation implementation contract used for the newly deployed proxy
    event MembershipsDeployed(address indexed membershipsProxy, address indexed owner, address indexed implementation);

    /// @notice Emitted when a Memberships implementation contract is set for a version
    /// @param version version of implementation
    /// @param implementation implementation contract address
    event MembershipsImplSet(uint16 indexed version, address indexed implementation);

    /// @notice Emitted when feeBPS is changed
    /// @param oldFeeBPS old feeBPS
    /// @param newFeeBPS new feeBPS
    event FeeBPSSet(uint16 oldFeeBPS, uint16 newFeeBPS);

    /// @notice Emitted when fee treasury is changed
    /// @param oldFeeTreasury old fee treasury address
    /// @param newFeeTreasury new fee treasury address
    event FeeTreasurySet(address indexed oldFeeTreasury, address indexed newFeeTreasury);

    /// @notice Fee in basis points
    uint16 public feeBPS;

    /// @notice treasury address to withdraw fees from Memberships
    address payable public feeTreasury;

    /// @notice Mapping to store Memberships implementations versions and addresses: version => membership impl address
    mapping(uint16 => address) internal _membershipsImpls;

    /// @notice Latest version of Memberships implementation
    uint16 public membershipsLatestVersion;

    /// @notice Sets `feeBPS`, `feeTreasury`
    /// @dev Reverts if `_memberships` param is address(0).
    ///      Reverts if `_feeTreasury` param is address(0)
    /// @param _feeBPS fee in bps
    /// @param _feeTreasury treasury address to withdraw fees from Memberships
    constructor(uint16 _feeBPS, address payable _feeTreasury) {
        if (_feeTreasury == address(0)) revert InvalidFeeTreasury();

        feeBPS = _feeBPS;
        feeTreasury = _feeTreasury;
    }

    /// @notice Set Memberships implementation contract for a version.
    ///         Also sets `membershipsLatestVersion` if setting a greater version
    /// @dev Callable only by `owner`.
    ///      Reverts if `_memberships` param is address(0).
    ///      Emits `MembershipsImplSet`
    /// @param _version version of Memberships implementation
    /// @param _memberships address of Memberships implementation contract
    function setMembershipsImplAddress(uint16 _version, address _memberships) external onlyOwner {
        if (_memberships == address(0)) revert InvalidMemberships();

        emit MembershipsImplSet(_version, _memberships);

        _membershipsImpls[_version] = _memberships;
        if (membershipsLatestVersion < _version) membershipsLatestVersion = _version;
    }

    /// @notice Set fee bps
    /// @dev Callable only by `owner`.
    ///      Emits `FeeBPSSet`
    /// @param _feeBPS fee in bps
    function setFeeBPS(uint16 _feeBPS) external onlyOwner {
        emit FeeBPSSet(feeBPS, _feeBPS);

        feeBPS = _feeBPS;
    }

    /// @notice Set fee treasury address
    /// @dev Callable only by `owner`.
    ///      Reverts if `_feeTreasury` param is address(0).
    ///      Emits `FeeTreasurySet`
    /// @param _feeTreasury treasury address to withdraw fees from Memberships
    function setFeeTreasury(address payable _feeTreasury) external onlyOwner {
        if (_feeTreasury == address(0)) revert InvalidFeeTreasury();

        emit FeeTreasurySet(feeTreasury, _feeTreasury);

        feeTreasury = _feeTreasury;
    }

    /// @notice Deploys and initializes a new Membership proxy with the latest implementation
    /// @dev Calls `deployMembershipsAtVersion(membershipsLatestVersion)`
    /// @param _owner Membership owner
    /// @param _treasury treasury address to withdraw sales funds
    /// @param _name name for Membership
    /// @param _symbol symbol for Membership
    /// @param contractURI_ contractURI for Membership
    /// @param baseURI_ baseURI for Membership
    /// @param _membership membership parameters: tokenAddress, price, validity, cap, airdropToken, airdropAmount
    /// @return address of the newly deployed proxy
    function deployMemberships(
        address _owner,
        address payable _treasury,
        string memory _name,
        string memory _symbol,
        string memory contractURI_,
        string memory baseURI_,
        IMemberships.Membership memory _membership
    ) external returns (address) {
        address membershipsProxy = deployMembershipsAtVersion(
            membershipsLatestVersion,
            _owner,
            _treasury,
            _name,
            _symbol,
            contractURI_,
            baseURI_,
            _membership
        );

        return membershipsProxy;
    }

    /// @notice Deploys and initializes a new Membership proxy with the specific implementation version
    /// @dev Only transfers airdrop tokens iff both `_membership.airdropToken` and `_membership.airdropAmount` are set.
    ///      Does not revert if they're invalid.
    ///      Reverts if implementation for `_version` is not set.
    ///      Emits `MembershipsDeployed`
    /// @param _version Memberships implementation version
    /// @param _owner Membership owner
    /// @param _treasury treasury address to withdraw sales funds
    /// @param _name name for Membership
    /// @param _symbol symbol for Membership
    /// @param contractURI_ contractURI for Membership
    /// @param baseURI_ baseURI for Membership
    /// @param _membership membership parameters: tokenAddress, price, validity, cap, airdropToken, airdropAmount
    /// @return address of the newly deployed proxy
    function deployMembershipsAtVersion(
        uint16 _version,
        address _owner,
        address payable _treasury,
        string memory _name,
        string memory _symbol,
        string memory contractURI_,
        string memory baseURI_,
        IMemberships.Membership memory _membership
    ) public returns (address) {
        address membershipsImpl = _membershipsImpls[_version];
        if (membershipsImpl == address(0)) revert InvalidMemberships();

        address membershipsProxy = address(
            new MembershipsProxy(
                _version,
                membershipsImpl,
                abi.encodeWithSelector(
                    IMemberships(membershipsImpl).initialize.selector,
                    _owner,
                    _treasury,
                    _name,
                    _symbol,
                    contractURI_,
                    baseURI_,
                    _membership
                )
            )
        );

        // Transfer airdrop tokens for all memberships
        if (_membership.airdropToken != address(0) && _membership.airdropAmount != 0) {
            IERC20(_membership.airdropToken).safeTransferFrom(
                msg.sender,
                membershipsProxy,
                _membership.airdropAmount * _membership.cap
            );
        }

        emit MembershipsDeployed(membershipsProxy, _owner, membershipsImpl);

        return membershipsProxy;
    }

    /// @notice Upgrade a proxy to latest Memberships implementation
    /// @dev Callable only by proxy owner.
    ///      Reverts if `_version <= currentVersion` or if `_version > membershipsLatestVersion`.
    ///      Reverts if membershipImpl for version is not set
    /// @param _version version to upgrade the proxy to
    /// @param _membershipsProxy address of proxy to upgrade
    function upgradeProxy(uint16 _version, address _membershipsProxy) external {
        if (msg.sender != IMemberships(_membershipsProxy).owner()) revert Unauthorized();

        uint16 currentVersion = IMemberships(_membershipsProxy).version();
        // Only allowing upgrades. So _version should be > current version but <= latest version
        if (_version <= currentVersion || _version > membershipsLatestVersion)
            revert InvalidUpgrade(currentVersion, _version, membershipsLatestVersion);

        address membershipsImpl = _membershipsImpls[_version];
        if (membershipsImpl == address(0)) revert InvalidMemberships();

        IMembershipsProxy(_membershipsProxy).upgradeMemberships(membershipsImpl);
    }

    /// @notice Get Memberships implementation address `version`
    /// @param _version version of Memberships implementation
    /// @return address of Memberships implementation contract for `version`
    function membershipsImpls(uint16 _version) public view returns (address) {
        return _membershipsImpls[_version];
    }
}
