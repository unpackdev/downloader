//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "./CudosAccessControls.sol";

contract AddressMapper  {
    // @notice Contract that defines access controls for the CUDO ecosystem
    CudosAccessControls public accessControls;

    // @notice defines whether a user can set their mapping
    bool public userActionsPaused;

    // @notice defines mapping between ETH address and CUDO address
    mapping(address => string) public cudosAddress;

    event UserActionsPausedToggled(bool isPaused);
    event AddressMapped(address indexed ethAddress, string cudosAddress);

    modifier onlyUnpaused() {
        require(userActionsPaused == false, "Paused");
        _;
    }

    constructor(CudosAccessControls _accessControls) {
        accessControls = _accessControls;
    }

    // Set mapping between ETH address and CUDOS address
    function setAddress(string memory _cudoAddress) external onlyUnpaused {
        cudosAddress[msg.sender] = _cudoAddress;

        emit AddressMapped(msg.sender, _cudoAddress);
    }

    // *****
    // Admin
    // *****

    function updateUserActionsPaused(bool _isPaused) external {
        require(accessControls.hasAdminRole(msg.sender), "Only admin");

        userActionsPaused = _isPaused;

        emit UserActionsPausedToggled(_isPaused);
    }
}
