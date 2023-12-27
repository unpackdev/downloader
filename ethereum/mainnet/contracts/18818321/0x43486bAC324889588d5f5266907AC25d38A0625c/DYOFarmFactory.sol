// SPDX-License-Identifier: MIT

// DYOFarm:
// Create custom reward pools to incentivize stakers of any ERC20!
// https://twitter.com/DYOFarm
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";

import "./DYOFarm.sol";

interface IDYOFarmFactory {
    function emergencyRecoveryAddress() external view returns (address);
    function feeAddress() external view returns (address);
    function getNitroPoolFee(address nitroPoolAddress, address ownerAddress) external view returns (uint256);
    function setNitroPoolOwner(address previousOwner, address newOwner) external;
}

contract DYOFarmFactory is Ownable, IDYOFarmFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _nitroPools; // all nitro pools
    mapping(address => EnumerableSet.AddressSet) internal _ownerNitroPools; // nitro pools per owner

    uint256 public constant MAX_DEFAULT_FEE = 500; // (1%) max authorized default fee
    uint256 public defaultFee; // default fee for nitro pools (*1e2)
    address public override feeAddress; // to receive fees when defaultFee is set
    EnumerableSet.AddressSet internal _exemptedAddresses; // owners or nitro addresses exempted from default fee

    address public override emergencyRecoveryAddress; // to recover rewards from emergency closed nitro pools

    constructor(address emergencyRecoveryAddress_, address feeAddress_) {
        require(emergencyRecoveryAddress_ != address(0) && feeAddress_ != address(0), "invalid");

        emergencyRecoveryAddress = emergencyRecoveryAddress_;
        feeAddress = feeAddress_;
    }

    event CreateNitroPool(address nitroAddress);
    event SetDefaultFee(uint256 fee);
    event SetFeeAddress(address feeAddress);
    event SetEmergencyRecoveryAddress(address emergencyRecoveryAddress);
    event SetExemptedAddress(address exemptedAddress, bool isExempted);
    event SetNitroPoolOwner(address previousOwner, address newOwner);

    modifier nitroPoolExists(address nitroPoolAddress) {
        require(_nitroPools.contains(nitroPoolAddress), "unknown nitroPool");
        _;
    }

    /**
     * @dev Returns the number of nitroPools
     */
    function nitroPoolsLength() external view returns (uint256) {
        return _nitroPools.length();
    }

    /**
     * @dev Returns a nitroPool from its "index"
     */
    function getNitroPool(uint256 index) external view returns (address) {
        return _nitroPools.at(index);
    }

    /**
     * @dev Returns the number of nitroPools owned by "userAddress"
     */
    function ownerNitroPoolsLength(address userAddress) external view returns (uint256) {
        return _ownerNitroPools[userAddress].length();
    }

    /**
     * @dev Returns a nitroPool owned by "userAddress" from its "index"
     */
    function getOwnerNitroPool(address userAddress, uint256 index) external view returns (address) {
        return _ownerNitroPools[userAddress].at(index);
    }

    /**
     * @dev Returns the number of exemptedAddresses
     */
    function exemptedAddressesLength() external view returns (uint256) {
        return _exemptedAddresses.length();
    }

    /**
     * @dev Returns an exemptedAddress from its "index"
     */
    function getExemptedAddress(uint256 index) external view returns (address) {
        return _exemptedAddresses.at(index);
    }

    /**
     * @dev Returns if a given address is in exemptedAddresses
     */
    function isExemptedAddress(address checkedAddress) external view returns (bool) {
        return _exemptedAddresses.contains(checkedAddress);
    }

    /**
     * @dev Returns the fee for "nitroPoolAddress" address
     */
    function getNitroPoolFee(address nitroPoolAddress, address ownerAddress) external view override returns (uint256) {
        if (_exemptedAddresses.contains(nitroPoolAddress) || _exemptedAddresses.contains(ownerAddress)) {
            return 0;
        }
        return defaultFee;
    }

    /**
     * @dev Deploys a new Nitro Pool
     */
    function createNitroPool(IERC20 depositToken, IERC20 rewardsToken1, DYOFarm.Settings calldata settings)
        external
        virtual
        returns (address nitroPool)
    {
        // Initialize new nitro pool
        nitroPool = address(new DYOFarm(msg.sender, depositToken, rewardsToken1, settings));

        // Add new nitro
        _nitroPools.add(nitroPool);
        _ownerNitroPools[msg.sender].add(nitroPool);

        emit CreateNitroPool(nitroPool);
    }

    /**
     * @dev Transfers a Nitro Pool's ownership
     *
     * Must only be called by the DYOFarm.sol contract
     */
    function setNitroPoolOwner(address previousOwner, address newOwner) external override nitroPoolExists(msg.sender) {
        require(_ownerNitroPools[previousOwner].remove(msg.sender), "invalid owner");
        _ownerNitroPools[newOwner].add(msg.sender);

        emit SetNitroPoolOwner(previousOwner, newOwner);
    }

    /**
     * @dev Set nitroPools default fee (when adding rewards)
     *
     * Must only be called by the owner
     */
    function setDefaultFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_DEFAULT_FEE, "invalid amount");

        defaultFee = newFee;
        emit SetDefaultFee(newFee);
    }

    /**
     * @dev Set fee address
     *
     * Must only be called by the owner
     */
    function setFeeAddress(address feeAddress_) external onlyOwner {
        require(feeAddress_ != address(0), "zero address");

        feeAddress = feeAddress_;
        emit SetFeeAddress(feeAddress_);
    }

    /**
     * @dev Add or remove exemptedAddresses
     *
     * Must only be called by the owner
     */
    function setExemptedAddress(address exemptedAddress, bool isExempted) external onlyOwner {
        require(exemptedAddress != address(0), "zero address");

        if (isExempted) _exemptedAddresses.add(exemptedAddress);
        else _exemptedAddresses.remove(exemptedAddress);

        emit SetExemptedAddress(exemptedAddress, isExempted);
    }

    /**
     * @dev Set emergencyRecoveryAddress
     *
     * Must only be called by the owner
     */
    function setEmergencyRecoveryAddress(address emergencyRecoveryAddress_) external onlyOwner {
        require(emergencyRecoveryAddress_ != address(0), "zero address");

        emergencyRecoveryAddress = emergencyRecoveryAddress_;
        emit SetEmergencyRecoveryAddress(emergencyRecoveryAddress_);
    }

    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}
