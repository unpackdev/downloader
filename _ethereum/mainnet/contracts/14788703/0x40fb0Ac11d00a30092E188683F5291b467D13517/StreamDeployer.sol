//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Stream.sol";

/// @title The Stream Deployer Contract for Orgs
/// @author nowonder, jaxcoder, qedk, supriyaamisshra
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract StreamDeployer is Ownable {

    /// @dev emitted when a new org is created.
    event OrganizationDeployed(
        address indexed orgAddress,
        address indexed ownerAddress,
        string organizationName
    );

    address[] public organizations;

    constructor (address _owner) {
        transferOwnership(_owner);
    }

    /// @dev deploys a stream factory contract for a specified organization.
    /// @param _orgName the name of the organization
    /// @param _owner the owner address for the org
    /// @param _addresses any addresses you want to have a stream on deploy
    /// @param _caps the caps for the addresses
    /// @param _frequency the frequency for the addresses
    /// @param _startsFull the bool for each address to start full or not
    /// @param _tokenAddress the stream token address for the org
    /// @param _name the stream name for the org
    function deployOrganization(
        string memory _orgName,
        string memory _orgLogoURI,
        string memory _orgDescription,
        address _owner,
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        string[] memory _name,
        IERC20 _tokenAddress
    ) external {
        MultiStream deployedOrganization = new MultiStream(
            _orgName,
            _orgLogoURI,
            _orgDescription,
            _owner,
            _addresses,
            _caps,
            _frequency,
            _startsFull,
            _name,
            address(_tokenAddress)
        );
        
        organizations.push(address(deployedOrganization));

        emit OrganizationDeployed(
            address(deployedOrganization),
            _owner,
            _orgName
        );

    }

    /// @dev gets a page of organizations
    /// @param _page page number
    /// @param _resultsPerPage how many to return per page
    function getOrganizations(
        uint256 _page,
        uint256 _resultsPerPage
    )
        external
        view
        returns (address[] memory)
    {
        uint256 _orgIndex = _resultsPerPage * _page - _resultsPerPage;

        if (
            organizations.length == 0 ||
            _orgIndex > organizations.length - 1
        ) {
            return new address[](0);
        }

        address[] memory _orgs = new address[](_resultsPerPage);
        uint256 _returnCounter = 0;
        
        for (
            _orgIndex;
            _orgIndex < _resultsPerPage * _page;
            _orgIndex++
        ) {
            if (_orgIndex <= organizations.length - 1) {
                _orgs[_returnCounter] = organizations[_orgIndex];
            } else {
                _orgs[_returnCounter] = address(0);
            }
            _returnCounter++;
        }
        return _orgs;
    }

}
