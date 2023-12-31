// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYieldManager {
    function getAffiliate(address client) external view returns (address);
    function setAffiliate(address client, address sponsor) external;
}

contract RefSetter {
    IYieldManager public yieldManager;
    address public owner;

    event NewYieldManager(address yieldManager);
    event NewOwner(address owner);
    event AffiliateSet(address sponsor, address client);

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    constructor(address _yieldManager) {
        owner = msg.sender;
        yieldManager = IYieldManager(_yieldManager);
    }

    function setYieldManager(IYieldManager _yieldManager) public onlyOwner {
        yieldManager = _yieldManager;
        emit NewYieldManager(address(yieldManager));
    }

    function getAffiliate(address client) public view returns (address) {
        return yieldManager.getAffiliate(client);
    }

    function setAffiliate(address sponsor) external {
        require(yieldManager.getAffiliate(sponsor) == address(0), "sponsor already set");
        require(sponsor != address(0), "sponsor cant be zero address");

        yieldManager.setAffiliate(msg.sender, sponsor);
        emit AffiliateSet(sponsor, msg.sender);
    }

    function newOwner(address newOwner_) external {
        require(msg.sender == owner, "Only factory owner");
        require(newOwner_ != address(0), "No zero address for newOwner");

        owner = newOwner_;
        emit NewOwner(owner);
    }
}
