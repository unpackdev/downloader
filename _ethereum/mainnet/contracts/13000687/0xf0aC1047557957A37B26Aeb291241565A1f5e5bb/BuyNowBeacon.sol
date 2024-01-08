// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./AccessControl.sol";

contract BuyNowBeacon is UpgradeableBeacon, AccessControl {
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    event NewBeacon(address beaconAddress);

    address public controller;

    constructor(address _buyNowAddress, address _controller)
        UpgradeableBeacon(_buyNowAddress)
    {
        address sender = _msgSender();

        controller = _controller;

        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(CREATOR_ROLE, sender);
    }

    modifier canDeploy() {
        address addr = _msgSender();
        bool canCreate = hasRole(DEFAULT_ADMIN_ROLE, addr) ||
            hasRole(CREATOR_ROLE, addr);

        if (false == canCreate && controller != address(0)) {
            (bool success, bytes memory result) = controller.call(
                abi.encodeWithSignature("canCreateAuctions(address)", addr)
            );

            require(success, "Controller reverted");

            canCreate = abi.decode(result, (bool));
        }

        require(canCreate, "BuyNowBeacon: Permissions Failed");
        _;
    }

    function setController(address _controller)
        public
        onlyRole(getRoleAdmin(CREATOR_ROLE))
    {
        controller = _controller;
    }

    function createAuction(
        address payable _beneficiary,
        string memory _metadata,
        uint256 _buyNowPrice
    ) public canDeploy {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,string,uint256)",
            _beneficiary,
            _metadata,
            _buyNowPrice
        );

        BeaconProxy auctionBeaconProxy = new BeaconProxy(address(this), data);
        address auctionAddress = address(auctionBeaconProxy);

        emit NewBeacon(auctionAddress);
    }
}
