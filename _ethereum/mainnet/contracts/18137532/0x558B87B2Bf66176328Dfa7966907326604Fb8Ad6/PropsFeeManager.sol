// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControlEnumerable.sol";
import "./AggregatorV3Interface.sol";
import "./IOwnable.sol";

contract PropsFeeManager is IOwnable, AccessControlEnumerable {

    //roles
    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    address private _owner;

    //price feed
    AggregatorV3Interface internal priceFeed;

    //flat fee in dollars
    uint256 public FEE = 100; 

    //or flat fee in eth
    uint256 public ETH_WEI_FEE = 700000000000000;

    uint256 public CREATOR_SPLIT = 5000; // 50%
    uint256 public CREATOR_TIP_SPLIT = 9000; // 90%

    constructor(address priceFeedContract) {
        //Mainnet: ETH/USD 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
        priceFeed = AggregatorV3Interface(priceFeedContract);
        _owner = msg.sender; 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

     function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IAccessControl)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IAccessControl)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        if (hasRole(role, account)) {
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            super._revokeRole(role, account);
        }
    }

     /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "A");
        address _prevOwner = _owner;
        _owner = _newOwner;
        emit OwnerUpdated(_prevOwner, _newOwner);
    }

     /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    //setters & getters

    function setAggregator(address priceFeedContract) public {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        priceFeed = AggregatorV3Interface(priceFeedContract);
    }

    function setFee(uint256 newFee) public {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        FEE = newFee;
    }

    function getFeeSetting() public view returns (uint256) {
        return FEE;
    }

     function setETHWEIFee(uint256 newFee) public {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        ETH_WEI_FEE = newFee;
    }

    function getETHWEIFeeSetting() public view returns (uint256) {
        return ETH_WEI_FEE;
    }

    function setSplit(uint256 newSplit) public {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        CREATOR_SPLIT = newSplit;
    }

    function getSplitSetting() public view returns (uint256) {
        return CREATOR_SPLIT;
    }

     function setTipSplit(uint256 newSplit) public {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        CREATOR_TIP_SPLIT = newSplit;
    }

    function getTipSplitSetting() public view returns (uint256) {
        return CREATOR_TIP_SPLIT;
    }


    function getLatestPrice() public view returns (int) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
    }

    function getCurrentTotalFeeInETH() public view returns (uint256) {
        int latestPrice = getLatestPrice(); // Get the latest ETH/USD price
        require(latestPrice > 0, "Invalid price data");

        uint256 feeInWei = (uint256(FEE) * 1e18) / uint256(latestPrice) * 1000000; // Convert the fee (in USD) to its equivalent in ETH (in Wei)

        return feeInWei; //@dev should pad this response on the frontend to ensure a price change just before the user's transaction is mined doesn't cause a revert.
    }

    function getCurrentCreatorFeeInETH() public view returns (uint256) {
    return (getCurrentTotalFeeInETH() * CREATOR_SPLIT) / 10000;
}

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return hasMinRole(getRoleAdmin(_role));
    }
}