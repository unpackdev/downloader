// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./AccessControl.sol";

contract TraditionalBeacon is UpgradeableBeacon, AccessControl {
    event NewBeacon(address beaconAddress);

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public controller;
    address private monegraphAddress = 0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9;

    struct Beneficiary {
        uint8 percentage;
        address payable wallet;
    }

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

    function setMonegraphAddress(address _monegraphAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(_monegraphAddress != address(0), "Monegraph Address cannot be set to Black Hole address");

      monegraphAddress = _monegraphAddress;
    }

    function setController(address _controller)
        external
        onlyRole(getRoleAdmin(CREATOR_ROLE))
    {
        controller = _controller;
    }

    function createAuction(
        Beneficiary[] memory _beneficiaries,
        string memory _metadata,
        uint256 _buyNowPrice,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _quantity
    ) external canDeploy {
        bool monegraphFound = false;

        uint8 total = 0;

        for (uint i=0; i<_beneficiaries.length; i++) {
           address payable wallet = _beneficiaries[i].wallet;

           require(wallet != address(0), "Black Hole wallet cannot be a beneficiary");
           require(_beneficiaries[i].percentage > 0, "Zero value beneficiary distribution");

           if (wallet == monegraphAddress) {
               monegraphFound = true;
           }

           total += _beneficiaries[i].percentage;
        }

        require(monegraphFound, "BuyNowBeacon: Auction created without Monegraph split defined");
        require(total == 100, "BuyNowBeacon: Beneficiary allocation must equal 100%");

        bytes memory data = abi.encodeWithSignature(
            "initialize((uint8,address)[],string,uint256,uint256,uint256,uint256)",
            _beneficiaries,
            _metadata,
            _buyNowPrice,
            _startTime,
            _endTime,
            _quantity
        );

        BeaconProxy auctionBeaconProxy = new BeaconProxy(address(this), data);
        address auctionAddress = address(auctionBeaconProxy);

        emit NewBeacon(auctionAddress);
    }
}
