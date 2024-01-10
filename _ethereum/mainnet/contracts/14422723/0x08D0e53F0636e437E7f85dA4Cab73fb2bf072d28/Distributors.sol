/*
    Copyright (C) 2021 Brightunion.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IDistributor.sol";

contract Distributors is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(string => address) public distributorsMap;

    bytes4 private constant IID_IDISTIBUTOR = type(IDistributor).interfaceId;

    event BuyCoverEvent(string indexed provider, IDistributor.Cover);

    event ErrorNotHandled(
        address indexed owner,
        bytes distributor,
        bytes reason
    );

    receive() external payable {
        revert("Distributors: No ETH here");
    }

    /// @dev Init the protocol
    function __Distributors_init() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function addDistributor(
        string memory distributorName,
        address distributorAddress
    ) external onlyOwner {
        distributorsMap[distributorName] = distributorAddress;
    }

    /// @dev Requires distributor address to implement the IDistributor interface OR "Bright Interface"
    modifier supportsIDistributor(string memory _distributorName) {
        IDistributor distributor = IDistributor(
            distributorsMap[_distributorName]
        );
        require(
            distributor.supportsInterface(IID_IDISTIBUTOR),
            "Address does not implement  IDistributor interface"
        );
        _;
    }

    function getDistributorAddress(string memory _distributorName)
        public
        view
        returns (address)
    {
        return distributorsMap[_distributorName];
    }

    /// @dev Gets the cover count owned by spec address
    /// @param _distributorName String Distributor name on lower case ie: nexus, bridge etc...
    /// @param _owner The Owner ethereum address
    /// @param _isActive boolean value to get Active/Unactive covers
    /// @return integer count number
    function getCoversCount(
        string memory _distributorName,
        address _owner,
        bool _isActive
    ) public view supportsIDistributor(_distributorName) returns (uint256) {
        IDistributor distributor = IDistributor(
            distributorsMap[_distributorName]
        );
        uint256 _ownersCoverCount = distributor.getCoverCount(
            _owner,
            _isActive
        );

        return _ownersCoverCount;
    }

    /// @dev Gets all the covers for spec address
    /// @param _owner Owner ethereum address
    /// @param _isActive boolean value to get Active/Unactive covers
    /// @param _limitLoop integer large number to avoid running out of gas
    /// @return IDistributor.Cover[] array of covers objects, refer to IDistributors interface
    function getCovers(
        string memory _distributorName,
        address _owner,
        bool _isActive,
        uint256 _limitLoop
    )
        public
        view
        supportsIDistributor(_distributorName)
        returns (IDistributor.Cover[] memory)
    {
        IDistributor distributor = IDistributor(
            distributorsMap[_distributorName]
        );
        uint256 _ownersCoverCount = distributor.getCoverCount(
            _owner,
            _isActive
        );

        uint256 limit = 0;
        if (_ownersCoverCount > _limitLoop) {
            limit = _limitLoop;
        } else {
            limit = _ownersCoverCount;
        }

        IDistributor.Cover[] memory userCovers = new IDistributor.Cover[](
            limit
        );

        for (uint256 _coverId = 0; _coverId < limit; _coverId++) {
            IDistributor.Cover memory cover = distributor.getCover(
                _owner,
                _coverId,
                _isActive,
                _limitLoop
            );
            userCovers[_coverId] = cover;
        }
        return userCovers;
    }

    /// @dev Gets single cover quote
    /// @param _distributorName string name of the protocol/distributor to buy from
    /// @param _sumAssured Total Sum covered
    /// @param _coverPeriod Covered period of the risk coverage
    /// @param _contractAddress Cover's reference or contract address
    /// @param _coverAsset Asset address of currency to pay with
    /// @param _nexusCoverable cover ref Address
    /// @param _data encode data
    /// @return Distributor.Cover array of Cover objects, refer to IDistributors interface
    function getQuote(
        string memory _distributorName,
        uint256 _sumAssured,
        uint256 _coverPeriod,
        address _contractAddress,
        address _coverAsset,
        address _nexusCoverable,
        bytes calldata _data
    )
        public
        view
        supportsIDistributor(_distributorName)
        returns (IDistributor.CoverQuote memory)
    {
        IDistributor distributor = IDistributor(
            distributorsMap[_distributorName]
        );

        return
            distributor.getQuote(
                _sumAssured,
                _coverPeriod,
                _contractAddress,
                _coverAsset,
                _nexusCoverable,
                _data
            );
    }
}
