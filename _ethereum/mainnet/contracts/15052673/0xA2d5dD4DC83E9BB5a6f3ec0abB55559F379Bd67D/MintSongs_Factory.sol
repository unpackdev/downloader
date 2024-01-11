// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ETH_ERC721.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract MintSongs_Factory is Initializable, OwnableUpgradeable {
    address public zoraERC721TransferHelper;
    address public zoraReserveAuctionFindersEth;
    UpgradeableBeacon public beacon;

    event ContractCreated(
        address indexed creator,
        address indexed contractAddress,
        string name,
        string symbol,
        string contractType
    );

    // always be initialized
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _zoraERC721TransferHelper,
        address _zoraReserveAuctionFindersEth,
        address _current721Imp
    ) public initializer {
        __Ownable_init();
        zoraERC721TransferHelper = _zoraERC721TransferHelper;
        zoraReserveAuctionFindersEth = _zoraReserveAuctionFindersEth;
        beacon = new UpgradeableBeacon(_current721Imp);
        beacon.transferOwnership(msg.sender);
    }

    function createContract(string memory _name, string memory _symbol)
        public
        returns (address clone)
    {
        clone = address(new BeaconProxy(address(beacon), ""));
        ETH_ERC721(clone).initialize(
            _name,
            _symbol,
            0, // whitelistRoot
            zoraERC721TransferHelper,
            zoraReserveAuctionFindersEth
        );
        ETH_ERC721(clone).transferOwnership(msg.sender);

        emit ContractCreated(msg.sender, clone, _name, _symbol, "ERC721");
    }
}
