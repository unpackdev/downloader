// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./AccessControl.sol";

contract TraditionalBeacon is UpgradeableBeacon, AccessControl {
    event NewBeacon(address beaconAddress);

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public controller;

    constructor(address _implementationAddress, address _controller)
        UpgradeableBeacon(_implementationAddress)
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

        require(canCreate, "TraditionalBeacon: Permissions Failed");
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
        uint256 _buyNowPrice,
        uint256 _startTime,
        uint256 _endTime
    ) public canDeploy {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,string,uint256,uint256,uint256)",
            _beneficiary,
            _metadata,
            _buyNowPrice,
            _startTime,
            _endTime
        );

        BeaconProxy auctionBeaconProxy = new BeaconProxy(address(this), data);
        address auctionAddress = address(auctionBeaconProxy);

        emit NewBeacon(auctionAddress);
    }
}
