// SPDX-License-Identifier: MIT

/*
              /@,                                                                                             
            @@@@@@@                                                                                           
           @@@@@@@@                         @@@@@                                                             
 ,@@@@@@@@@@*#@@@     @@@@@@%             (@@@@@@                              @@@@@@@          @@@@@@  @@@@. 
@@@@@@@@@            &@@@@@@@            @@@@@@@                            @@@@@( ,@@@@&      @@@@@@@@@@@@@@@
 @@@@@@@     @@@@@@@@@@@@@@@            @@@@@@@    &@@@@/  %@@@@@@@@@@    &@@@@      @@@@#    @@@@@@     *@@@@
  &@       @@@@@@@@                    @@@@@@@@ #@@@@@@  &@@@@     @@@@@  @@@@@(     @@@@@   @@@@@@@@   @@@@@@
  &@       #@@@@@@     .@@            @@@@@@@@@@@@@@@   (@@@@#     ,@@@@  @@@@@@@@@@@@@@@  .@@@@@@@@@@@@@@@@  
 @@@@@@              @@@@@@@#        @@@@@@@@@@@@@@     @@@@@@@( &@@@@@@   @@@@@@@@@@@@&   @@@@@@@@@@@        
@@@@@@@@            @@@@@@@@(       @@@@@@@&@@@@@@&      @@@@@@@@@@@@@@       %@@@@@      @@@@@@@@            
  @@@@@@   %@@@@@@@@#   @@         %@@@@@     @@@@@        @@@@@@@@@@                    @@@@@@@              
          @@@@@@@@                  .@%        @@@@/                                        &*                
           .@@@@@                                                                                             
*/

pragma solidity 0.8.12;

import "./Merkle.sol";
import "./KoopCore.sol";
import "./OwnableUpgradeable.sol";

/// @author tae-jin.eth
/// @author danielho.eth
/// @title KoopMembership.sol
/**
    @notice Implements KoopCore.sol, the Koop NFT membership contract with a single admin address
 */
contract KoopMembership is KoopCore, OwnableUpgradeable {
    using Strings for uint256;

    constructor(address _proxyAdmin) KoopCore(_proxyAdmin) {}

    /// @notice intitialization function. Will initialze ERC721 storage
    function __KoopMembership_init(
        string calldata _name,
        string calldata _symbol,
        address _initialOwner,
        address _factoryAddress,
        uint96 _royaltyFee
    ) external initializer {
        /// @dev transfer ownership to _initialOwner because msg.sender in this context is the factory contract
        __Ownable_init();
        transferOwnership(_initialOwner);
        __KoopCore_init(_name, _symbol, _factoryAddress, _royaltyFee);
    }

    /** 
        @notice sets the merkle root for the allowlist. Can be used to set an initial
        allowList or update the allowList.  If set to `0x00`, no allowlist will be enforced.
    */
    /// @param _allowlistMerkleRoot merkle root used for allowlist
    function setAllowlistMerkleRoot(
        uint256 _tierId,
        bytes32 _allowlistMerkleRoot
    ) onlyOwner external nonReentrant {
        _setAllowlistMerkleRoot(_tierId, _allowlistMerkleRoot);
    }

    function setMintLimit(
        uint256 _tierId,
        uint256 _mintLimit
    ) onlyOwner external nonReentrant {
        _setMintLimit(_tierId, _mintLimit);
    }

    /// @notice starts a member badge crowdfund. Only called once
    /// @param _tierPrices list of prices for each corresponding tier
    /// @param _tierLimits list of supply limits for each corresponding tier
    /// @param _blockTransfers flag for whether or not to block transfers of member badges
    function launchMemberBadgeCrowdfund(
        uint256[] calldata _tierPrices,
        uint256[] calldata _tierLimits,
        bytes32[] calldata _allowlistMerkleRoots,
        uint256[] calldata _mintLimits,
        string calldata _baseURI,
        bool _blockTransfers

    ) onlyOwner external nonReentrant {
        _launchMemberBadgeCrowdfund(
            _tierPrices, 
            _tierLimits, 
            _allowlistMerkleRoots, 
            _mintLimits, 
            _baseURI, 
            _blockTransfers
        );
    }

    /// @notice adds new member badge tiers. Will not overwrite existing tiers.
    /// @param _tierPrices new tier prices
    /// @param _tierLimits new tier supply limits
    function addMemberBadgeTiers(
        uint256[] calldata _tierPrices,
        uint256[] calldata _tierLimits,
        bytes32[] calldata _allowlistMerkleRoots,
        uint256[] calldata _mintLimits,
        string calldata _baseURI
    ) onlyOwner external nonReentrant {
        _addMemberBadgeTiers(_tierPrices, _tierLimits, _allowlistMerkleRoots, _mintLimits, _baseURI);
    }

    function updateRoyaltyFee(
        uint96 _royaltyFee
    ) onlyOwner external nonReentrant {
        _updateRoyaltyFee(_royaltyFee);
    }

    /// @notice sets flag to block or allow member badge transfers
    /// @param _blockTransfers blocks transfers if set to true, allows transfers if set to false
    function blockMemberBadgeTransfers(bool _blockTransfers) onlyOwner external nonReentrant {
        _blockMemberBadgeTransfers(_blockTransfers);
    }

    /// @notice used to withdraw funds from the contract
    /// @param _destination the destination of the funds
    /// @param _amount amount of funds to withdraw
    function transferETH(
        address _destination,
        uint256 _amount
    ) onlyOwner external nonReentrant {
        _transferETH(_destination, _amount);
    }

    /// @notice used to upgrade the Koop to a new logic contract
    function upgradeKoop(
        address _newLogic,
        bytes calldata _data
    ) onlyOwner external nonReentrant {
        _upgradeKoop(_newLogic, _data);
    }
}