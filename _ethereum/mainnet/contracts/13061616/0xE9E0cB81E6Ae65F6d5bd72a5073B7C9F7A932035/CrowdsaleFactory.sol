// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Crowdsale.sol";
import "./Pool.sol";
import "./IFarm.sol";

contract CrowdsaleFactory is Ownable {
    Crowdsale[] public crowdsales;
    bytes32 public constant COLLECTION_ROLE =
        bytes32(keccak256("COLLECTION_ROLE"));

    event CrowdsaleCreated(address owner, address deployedAt);

    IFarm private _farm;

    function createCrowdsale(Pool memory _pool)
        public
        virtual
        onlyOwner
        returns (Crowdsale)
    {
        Crowdsale _crowdsale = new Crowdsale();

        _crowdsale.initialize(_pool);

        _crowdsale.transferOwnership(msg.sender);
        crowdsales.push(_crowdsale);
        emit CrowdsaleCreated(msg.sender, address(_crowdsale));

        _farm.grantRole(COLLECTION_ROLE, address(_crowdsale));
        return _crowdsale;
    }

    function crowdsalesCount() public view returns (uint256) {
        return crowdsales.length;
    }

    function setFarmAddress(address farm) external onlyOwner {
        _farm = IFarm(farm);
    }
}
