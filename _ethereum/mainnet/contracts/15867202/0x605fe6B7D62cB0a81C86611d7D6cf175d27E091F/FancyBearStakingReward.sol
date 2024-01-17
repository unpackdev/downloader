// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControlEnumerable.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./IHoneyToken.sol";
import "./IFancyBears.sol";
import "./IFancyBearStaking.sol";
import "./IHive.sol";

contract FancyBearStakingReward is AccessControlEnumerable {
    
    using SafeERC20 for IHoneyToken;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    enum ClaimingStatus {
        Off,
        Active
    }

    struct HoneyReward {
        uint256 honeyAmount;
        bool set;
    }

    IHoneyToken public honeyContract;
    IFancyBears public fancyBearsContract;
    IFancyBearStaking public fancyBearStakingContract;
    IHive public hiveContract;

    ClaimingStatus public claimingStatus;
    uint256 public maxHoneyRewardAmount;

    EnumerableSet.AddressSet private approvedCollections;

    mapping(address => HoneyReward) private honeyRewardsForWallets;
    mapping(address => mapping(uint256 => HoneyReward)) private honeyRewardsForHive;

    event ClaimedToWallet(address indexed _to, uint256 _honeyAmount);
    event ClaimedToHive(address indexed _collection, uint256 indexed _tokenId, uint256 _honeyAmount);

    constructor(
        IHoneyToken _honeyContractAddress, 
        IFancyBears _fancyBearsContractAddress, 
        IFancyBearStaking _fancyBearStakingContract, 
        IHive _hiveContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        honeyContract = _honeyContractAddress;
        fancyBearsContract = _fancyBearsContractAddress;
        fancyBearStakingContract = _fancyBearStakingContract;
        hiveContract = _hiveContract;
        claimingStatus = ClaimingStatus.Active;
        maxHoneyRewardAmount = 2000000 ether;
        approvedCollections.add(address(_fancyBearsContractAddress));
    }

    function setClaimingStatus(ClaimingStatus _claimingStatus)
        public
        onlyRole(MANAGER_ROLE)
    {
        claimingStatus = _claimingStatus;
    }

    function setMaxHoneyRewardAmount(uint256 _amount) public onlyRole(MANAGER_ROLE) {
        maxHoneyRewardAmount = _amount;
    }

    function approveCollection(address _collection) public onlyRole(MANAGER_ROLE) {
        require(_collection != address(0), 'approveCollection: attempt to set a null address!');
        approvedCollections.add(_collection);
    }

    function denyCollection(address _collection) public onlyRole(MANAGER_ROLE) {
        approvedCollections.remove(_collection);
    }

    function getApprovedCollection() public view returns (address[] memory) {
        return approvedCollections.values();
    }

    function isCollectionApproved(address _address) public view returns (bool) {
        return approvedCollections.contains(_address);
    }

    // Wallet -----

    function getHoneyRewardForWallet(address _wallet) public view returns (uint256) {
        return honeyRewardsForWallets[_wallet].honeyAmount;
    }

    function addHoneyRewardsForWallets(
        address[] calldata _wallets,
        uint256[] calldata _honeyAmounts
    ) public onlyRole(MANAGER_ROLE) {
        
        require(
            _wallets.length == _honeyAmounts.length,
            "addHoneyRewardsForWallet: the length of the input arrays must be the same."
        );

        uint256 loopLength = _wallets.length;

        for (uint256 i; i < loopLength; i++) {

            require(
                _honeyAmounts[i] != 0 && _honeyAmounts[i] <= maxHoneyRewardAmount,
                "addHoneyRewardsForWallets: amount to reward must be greater than zero and lower than maxHoneyRewardAmount."
            );

            if(honeyRewardsForWallets[_wallets[i]].set) {                
                honeyRewardsForWallets[_wallets[i]].honeyAmount += _honeyAmounts[i];
            } else {
                honeyRewardsForWallets[_wallets[i]] = HoneyReward({
                    honeyAmount: _honeyAmounts[i],
                    set: true
                });
            }

        }

    }

    function removeHoneyRewardForWallet(address _wallet) public onlyRole(MANAGER_ROLE) {
        require(honeyRewardsForWallets[_wallet].set, "removeHoneyRewardForWallet: reward not set.");
        delete(honeyRewardsForWallets[_wallet]);   
    }


    function claimHoneyRewardToWallet() external {

        require(claimingStatus == ClaimingStatus.Active, "claimHoneyRewardToWallet: claiming is off!");
        require(honeyRewardsForWallets[msg.sender].set, "claimHoneyRewardToWallet: reward not set.");

        uint256 honeyAmount = honeyRewardsForWallets[msg.sender].honeyAmount;

        delete(honeyRewardsForWallets[msg.sender]);

        emit ClaimedToWallet(msg.sender, honeyAmount);

        honeyContract.safeTransfer(msg.sender, honeyAmount);

    }

    // Hive -----

    function getHoneyRewardsForHive(
        address _collection,
        uint256[] calldata _tokenIds
    ) public view returns (uint256[] memory) {

        uint256 loopLength = _tokenIds.length;
        uint256[] memory honeyAmounts = new uint256[](loopLength);

        for(uint256 i; i < loopLength; i++) {
             honeyAmounts[i] = honeyRewardsForHive[_collection][_tokenIds[i]].honeyAmount;
        }
        
        return honeyAmounts;

    }

    function addHoneyRewardsForHive(
        address _collection,
        uint256[] calldata _tokenIds,
        uint256[] calldata _honeyAmounts
    ) public onlyRole(MANAGER_ROLE) {

        require(
            isCollectionApproved(_collection),
            "addHoneyRewardsForHive: collection not approved."
        );

        uint256 loopLength = _tokenIds.length;

        require(
             loopLength == _honeyAmounts.length,
            "addHoneyRewardsForHive: the length of the input arrays must be the same."
        );

        for (uint256 i; i < loopLength; i++) {

            require(
                _honeyAmounts[i] != 0 && _honeyAmounts[i] <= maxHoneyRewardAmount,
                "addHoneyRewardsForHive: amount to reward must be greater than zero and lower than maxHoneyRewardAmount."
            );

            if(honeyRewardsForHive[_collection][_tokenIds[i]].set) {                
                honeyRewardsForHive[_collection][_tokenIds[i]].honeyAmount += _honeyAmounts[i];
            } else {
                honeyRewardsForHive[_collection][_tokenIds[i]] = HoneyReward({
                    honeyAmount: _honeyAmounts[i],
                    set: true
                });
            }

        }

    }

    function removeHoneyRewardForHive(
         address _collection,
         uint256[] memory _tokenIds

    ) public onlyRole(MANAGER_ROLE) {
        
        uint256 loopLength = _tokenIds.length;

        for (uint256 i; i < loopLength; i++) {
            require(honeyRewardsForHive[_collection][_tokenIds[i]].set, "removeHoneyRewardsForHive: reward not set.");
            delete(honeyRewardsForHive[_collection][_tokenIds[i]]);
        }

    }

    function claimHoneyRewardToHive(address _collection, uint256[] memory _tokenIds) external {

        require(claimingStatus == ClaimingStatus.Active, "claimHoneyRewardToHive: claiming is off!");

        require(
            isCollectionApproved(_collection),
            "addHoneyRewardsForHive: collection not approved."
        );

        bool fancyBearStakingValidationRequired;

        if(_collection == address(fancyBearsContract)){
            fancyBearStakingValidationRequired = true;
        } 

        uint256 loopLength = _tokenIds.length;
        address[] memory collections = new address[](loopLength);
        uint256[] memory amounts = new uint256[](loopLength);
        uint256 totalHoneyAmounts;

        for (uint256 i; i < loopLength; i++) {

          if(fancyBearStakingValidationRequired) {            
            require(
                fancyBearsContract.ownerOf(_tokenIds[i]) == msg.sender || fancyBearStakingContract.getOwnerOf(_tokenIds[i]) == msg.sender,
                "claimHoneyRewardToHive: FancyBear, the sender is not the owner of the token and the token is not staked too."
            );
          } else {
            require(
                IERC721(_collection).ownerOf(_tokenIds[i]) == msg.sender,
                "claimHoneyRewardToHive: the sender is not the owner of the token in given collection."
            );
          } 

          require(honeyRewardsForHive[_collection][_tokenIds[i]].set, "claimHoneyRewardToHive: reward not set.");

          collections[i] = _collection;
          amounts[i] = honeyRewardsForHive[_collection][_tokenIds[i]].honeyAmount;
          totalHoneyAmounts += amounts[i];

          emit ClaimedToHive(_collection, _tokenIds[i], amounts[i]);

          delete(honeyRewardsForHive[_collection][_tokenIds[i]]);

        }
        
        honeyContract.approve(address(hiveContract), totalHoneyAmounts);
        hiveContract.depositHoneyToTokenIdsOfCollections(collections, _tokenIds, amounts);

    }

}
