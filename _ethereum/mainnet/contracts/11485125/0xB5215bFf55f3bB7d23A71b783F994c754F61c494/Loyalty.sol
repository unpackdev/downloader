// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ILoyalty.sol";
import "./ILodge.sol";
import "./ISlopes.sol";
import "./IAvalanche.sol";
import "./LoyaltyBase.sol";

// contract to manage all bonuses
contract Loyalty is ILoyalty, IERC1155Receiver, LoyaltyBase {
    event TrancheUpdated(uint256 _tranche, uint256 _points);
    event LoyaltyUpdated(address indexed _user, uint256 _tranche, uint256 _points);
    event BaseFeeUpdated(address indexed _user, uint256 _baseFee);
    event ProtocolFeeUpdated(address indexed _user, uint256 _protocolFee);
    event DiscountMultiplierUpdated(address indexed _user, uint256 _multiplier);
    event Deposit(address indexed _user, uint256 _id, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _id, uint256 _amount);

    struct LoyaltyInfo {
        uint256 points;
        uint256 tranche;
        uint256 boost; // current boosts, 1 = 0.1%
        uint256 staked; // id+1 of staked nft
    }

    uint256[] public tokenIds;
    uint256 public baseFee; // default 0.08% 
    uint256 public protocolFee; // default 20% of 0.8%
    uint256 public discountMultiplier; // 0.01%

    mapping(uint256 => mapping(address => uint256)) public override staked;
    mapping(uint256 => bool) public override whitelistedTokens;
    mapping (uint256 => uint256) public loyaltyTranches; // Tranche level to points required
    mapping (address => LoyaltyInfo) public userLoyalty; // Address to loyalty points accrued

    modifier Whitelisted(uint256 _id) {
        require(whitelistedTokens[_id], "This Lodge token cannot be staked");
        _;
    }

    modifier OnlyOneBoost(address _user) {
        require(
            userLoyalty[_user].boost == 0,
            "Max one boost per account"
        );
        _;
    }

    constructor(address _address) 
        public
        LoyaltyBase(_address)
    {
        tokenIds = new uint256[](0);
        baseFee = 80; // 0.08%
        protocolFee = 20000; // 20% of baseFee
        discountMultiplier = 10; // 0.01%

        _initializeWhitelist();
        _initializeLoyaltyTranches();
    }

    function _initializeWhitelist() internal {
        whitelistedTokens[0] = true;
        whitelistedTokens[1] = true;
        whitelistedTokens[2] = true;

        tokenIds.push(0);
        tokenIds.push(1);
        tokenIds.push(2);
    }

     // set the base loyalty tranches, performing more flash loans unlocks
     // greater discounts
    function _initializeLoyaltyTranches() internal {
        _setLoyaltyTranche(0, 0); // base loyalty, base fee
        _setLoyaltyTranche(1, 100); // level 1, 100 tx
        _setLoyaltyTranche(2, 500);  // level 2, 500 tx
        _setLoyaltyTranche(3, 1000); // level 3, 1k tx
        _setLoyaltyTranche(4, 5000); // level 4, 5k tx
        _setLoyaltyTranche(5, 10000); // level 5, 10k tx
        _setLoyaltyTranche(6, 50000); // level 6, 50k tx
        _setLoyaltyTranche(7, 100000); // level 7, 100k tx, initially 0.01% fee + boost
    }

    function deposit(uint256 _id, uint256 _amount)
        external
        override
    {
        _deposit(_msgSender(), _id, _amount);
    }

    function _deposit(address _address, uint256 _id, uint256 _amount) 
        internal
        Whitelisted(_id)
        NonZeroAmount(_amount)
        OnlyOneBoost(_address)
    {
        IERC1155(lodgeAddress()).safeTransferFrom(_address, address(this), _id, _amount, "");
        staked[_id][_address] += _amount;
        userLoyalty[_address].boost = ILodge(lodgeAddress()).boost(_id);
        userLoyalty[_address].staked = _id + 1;

        ISlopes(slopesAddress()).claimAllFor(_address);
        IAvalanche(avalancheAddress()).claimFor(_address);

        emit Deposit(_address, _id, _amount);
    }

    function withdraw(uint256 _id, uint256 _amount) 
        external
        override
    {
        _withdraw(_msgSender(), _id, _amount);
    }

    function _withdraw(address _address, uint256 _id, uint256 _amount) 
        internal 
    {
        require(
            staked[_id][_address] >= _amount,
            "Staked balance not high enough to withdraw this amount" 
        );
        
        IERC1155(lodgeAddress()).safeTransferFrom(address(this), _address, _id, _amount, "");
        staked[_id][_address] -= _amount;
        userLoyalty[_address].boost = 0;
        userLoyalty[_address].staked = 0;

        // claim all user rewards and update user pool shares to prevent abuse
        ISlopes(slopesAddress()).claimAllFor(_address);
        IAvalanche(avalancheAddress()).claimFor(_address);

        emit Withdraw(_address, _id, _amount);
    }

    function whitelistToken(uint256 _id)
        external
        override
        HasPatrol("ADMIN")
    {
        whitelistedTokens[_id] = true;
        tokenIds.push(_id);
    }

    function blacklistToken(uint256 _id)
        external
        override
        HasPatrol("ADMIN")
    {
        whitelistedTokens[_id] = false;
    }

    function getBoost(address _user)
        external
        override
        view
        returns (uint256)
    {
        return userLoyalty[_user].boost;
    }

    // get the total shares a user will receive when staking a given token amount
    function getTotalShares(address _user, uint256 _amount)
        external
        override
        view
        returns (uint256)
    {
        // 1 + [1 * (boost/1000)]
        return _amount.add(_amount.mul(userLoyalty[_user].boost).div(1000));
    }

    // get the total fee amount that an address will pay on a given flash loan amount
    // get base fee for user tranche, then flat discount based on boost
    function getTotalFee(address _user, uint256 _amount) 
        external 
        override
        view 
        returns (uint256)
    {
        uint256 feeMultiplier = baseFee.sub(discountMultiplier.mul(userLoyalty[_user].tranche));
        uint256 trancheFee = _amount.mul(feeMultiplier).div(100000);
        return trancheFee.sub(trancheFee.mul(userLoyalty[_user].boost).div(1000));
    }

    // protocol fee added for future use
    function getProtocolFee(uint256 _amount)
        external
        override
        view
        returns (uint256)
    {
        return _amount.mul(protocolFee).div(10000);
    }

    // update user points and tranche if needed
    function updatePoints(address _address) 
        external
        override
        OnlySlopes
    {
        userLoyalty[_address].points = userLoyalty[_address].points.add(1);
        if (userLoyalty[_address].points > loyaltyTranches[userLoyalty[_address].tranche.add(1)]) {
            userLoyalty[_address].tranche = userLoyalty[_address].tranche.add(1);
        }
    }

    function updateTranche(address _address)
        public  
    {
        if (userLoyalty[_address].points > loyaltyTranches[userLoyalty[_address].tranche + 1]) {
            userLoyalty[_address].tranche = userLoyalty[_address].tranche + 1;
        } else {
            if (userLoyalty[_address].tranche == 0) {
                return;
            }
            if (userLoyalty[_address].points < loyaltyTranches[userLoyalty[_address].tranche]) {
                userLoyalty[_address].tranche = userLoyalty[_address].tranche - 1;
            }
        }
    }

    function _getProtocolFee(uint256 _totalFee)
        internal
        view
        returns (uint256)
    {
        return _totalFee.mul(protocolFee).div(100000);
    }

    function setBaseFee(uint256 _newFee)
        external
        HasPatrol("ADMIN")
    {
        require(_newFee != baseFee, "No change");
        require(_newFee <= 90, "Base Fee must remain below 0.09%");

        baseFee = _newFee;
        emit BaseFeeUpdated(msg.sender, _newFee);
    }

    function setProtocolFee(
        uint256 _newFee
    )
        external
        HasPatrol("ADMIN")
    {
        require(_newFee != baseFee, "No change");

        protocolFee = _newFee;
        emit ProtocolFeeUpdated(msg.sender, _newFee);
    }

    function setLoyaltyTranche(
        uint256 _tranche, 
        uint256 _points
    )
        external
        HasPatrol("ADMIN")
    {
        _setLoyaltyTranche(_tranche, _points);
    }

    function _setLoyaltyTranche(
        uint256 _tranche, 
        uint256 _points
    )
        internal
    {
        loyaltyTranches[_tranche] = _points;
        emit TrancheUpdated(_tranche, _points);
    }

    function setDiscountMultiplier(uint256 _newMultiplier)
        external
        HasPatrol("ADMIN")
    {
        discountMultiplier = _newMultiplier;
        emit DiscountMultiplierUpdated(msg.sender, _newMultiplier);
    }

    function setLoyaltyPoints(
        address _address,
        uint256 _points
    )
        external
        HasPatrol("ADMIN")
    {
        userLoyalty[_address].points = _points;
        updateTranche(_address);
        emit LoyaltyUpdated(_address, userLoyalty[_address].tranche, _points);
    }

    function updateIds(uint256[] memory _ids) external HasPatrol("ADMIN") {
        tokenIds = _ids;
    }

    // https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver
    function supportsInterface(bytes4 interfaceId) 
        external
        override
        view 
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7 
            || interfaceId == 0x4e2312e0; 
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getLoyaltyStats(address _user)
        external
        view
        returns (
            bool _active, 
            bool _approved, 
            uint256[] memory _balances,
            uint256[] memory _stats
        )
    {
        _active = ISlopes(slopesAddress()).active();
        _approved = IERC1155(lodgeAddress()).isApprovedForAll(_user, address(this));
        
        address[] memory users = new address[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            users[i] = _user;
        }
        
        _balances = IERC1155(lodgeAddress()).balanceOfBatch(users, tokenIds);

        _stats = new uint256[](4);
        _stats[0] = userLoyalty[_user].points;
        _stats[1] = userLoyalty[_user].tranche;
        _stats[2] = userLoyalty[_user].staked;
        _stats[3] = userLoyalty[_user].boost;

    }
}