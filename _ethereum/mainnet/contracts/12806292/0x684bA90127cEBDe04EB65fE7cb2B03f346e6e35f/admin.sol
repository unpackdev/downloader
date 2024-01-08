pragma solidity 0.7.6;

import "./IHypervisor.sol";
import "./IERC20.sol";

contract Admin {
    /* user events */
    event OwnerTransferPrepared(address hypervisor, address newOwner, address admin, uint256 timestamp);
    event OwnerTransferFullfilled(address hypervisor, address newOwner, address admin, uint256 timestamp);

    address public admin;
    address public advisor;

    struct OwnershipData {
        address newOwner;
        uint256 lastUpdatedTime;
    }

    mapping(address => OwnershipData) hypervisorOwner;

    modifier onlyAdvisor {
        require(msg.sender == advisor, "only advisor");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _advisor) {
        admin = _admin;
        advisor = _advisor;
    }

    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external onlyAdvisor {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, swapQuantity);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function transferAdvisor(address newAdvisor) external onlyAdmin {
        advisor = newAdvisor;
    }

    function prepareHVOwnertransfer(address _hypervisor, address newOwner) external onlyAdmin {
        require(newOwner != address(0), "newOwner must not be zero");
        hypervisorOwner[_hypervisor] = OwnershipData(newOwner, block.timestamp + 86400);
        emit OwnerTransferPrepared(_hypervisor, newOwner, admin, block.timestamp);
    }

    function fullfillHVOwnertransfer(address _hypervisor, address newOwner) external onlyAdmin {
        OwnershipData storage data = hypervisorOwner[_hypervisor];
        require(data.newOwner == newOwner && data.lastUpdatedTime != 0 && data.lastUpdatedTime < block.timestamp);
        IHypervisor(_hypervisor).transferOwnership(newOwner);
        delete hypervisorOwner[_hypervisor];
        emit OwnerTransferFullfilled(_hypervisor, newOwner, admin, block.timestamp);
    }

    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

}
