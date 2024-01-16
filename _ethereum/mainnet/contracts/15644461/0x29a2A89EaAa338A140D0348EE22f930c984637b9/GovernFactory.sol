// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC1967Proxy.sol";
import "./OwnableUpgradeable.sol";

import "./IGovern.sol";

contract GovernFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    address public governImplementation;
    mapping(address => mapping(string => address)) public governMap;

    event CreateGovern(
        string name,
        address govern,
        address caller,
        address voteToken
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        address _governImplementation
    ) public initializer {
        __Ownable_init();

        require(_governImplementation != address(0), "Govern implementation must not be null");
        governImplementation = _governImplementation;
    }

    function createGovern(
        string calldata name,
        uint duration,
        uint quorum,
        uint passThreshold,
        address voteToken
    ) external {
        require(governMap[msg.sender][name] == address(0), "error");

        ERC1967Proxy _govern = new ERC1967Proxy(governImplementation, "");
        
        IGovern(payable(address(_govern))).initialize(
            msg.sender,
            name,
            duration,
            quorum,
            passThreshold,
            voteToken
        );

        governMap[msg.sender][name] = address(_govern);

        emit CreateGovern(
            name,
            address(_govern),
            msg.sender,
            voteToken
        );
    }

    function setGovernImplementation(
        address _governImplementation
    ) public onlyOwner {
        require(_governImplementation != address(0), "governImpl is null");
        governImplementation = _governImplementation;
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}

    uint256[50] private __gap;
}