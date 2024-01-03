// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Initializable.sol";
import "./IAddressRegistry.sol";

contract APYAddressRegistry is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistry
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    event AdminChanged(address);
    event AddressRegistered(bytes32 id, address _address);

    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    function getIds() public override view returns (bytes32[] memory) {
        return _idList;
    }

    function registerAddress(bytes32 id, address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = _address;
        emit AddressRegistered(id, _address);
    }

    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address _address = addresses[i];
            registerAddress(id, _address);
        }
    }

    function getAddress(bytes32 id) public override view returns (address) {
        address _address = _idToAddress[id];
        require(_address != address(0), "Missing address");
        return _address;
    }

    function managerAddress() public view returns (address) {
        return getAddress("manager");
    }

    function chainlinkRegistryAddress() public view returns (address) {
        return getAddress("chainlinkRegistry");
    }

    function daiPoolAddress() public view returns (address) {
        return getAddress("daiPool");
    }

    function usdcPoolAddress() public view returns (address) {
        return getAddress("usdcPool");
    }

    function usdtPoolAddress() public view returns (address) {
        return getAddress("usdtPool");
    }
}
