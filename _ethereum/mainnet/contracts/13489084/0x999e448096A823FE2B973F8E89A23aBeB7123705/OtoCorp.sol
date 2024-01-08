// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ISeries.sol";
import "./Clones.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract OtoCorp is Ownable {

    ISeries public seriesSource;
    address public registry;
    mapping(address=>address[]) internal seriesOfMembers;

    event NewSeriesCreated(address _contract, address _owner, string _name);

    constructor(ISeries _source) {
        seriesSource = _source;
    }

    function createSeries(string memory seriesName) external onlyRegistry virtual {
        createSeriesWithOwner(msg.sender, seriesName);
    }

    function createSeriesWithOwner(address owner, string memory seriesName) public onlyRegistry virtual {
        ISeries newContract = ISeries(Clones.clone(address(seriesSource)));
        ISeries(newContract).initialize(owner, seriesName);
        seriesOfMembers[owner].push(address(newContract));
        emit NewSeriesCreated(address(newContract), owner, seriesName);
    }

    function updateRegistry(address _newRegistry) external onlyOwner {
        registry = _newRegistry;
    }

    function updateSeriesSource(address _newSource) external onlyOwner {
        seriesSource = ISeries(_newSource);
    }

    function mySeries() public view returns (address[] memory) {
        return seriesOfMembers[msg.sender];
    }

    /**
     * @dev Throws if called by any account other than the registry in case registry is defined.
     */
    modifier onlyRegistry() {
        require(registry == address(0x0) || registry == msg.sender, "Registry: caller is not the registry");
        _;
    }

}