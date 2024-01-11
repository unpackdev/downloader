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
import "./ProxyFactoryUpgrade.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC2981Upgradeable.sol";

/// @author tae-jin.eth
/// @author danielho.eth
/// @title Core koop logic contract
/**
    @notice Contains functionality for NFT membership badge crowdfunds as well as a meta-function to call 
    other external contracts to buy/sell NFTs, trade on token exchanges, and use other dapps.
 */
contract KoopCore is Merkle, ERC721URIStorageUpgradeable, ERC2981Upgradeable, ReentrancyGuard {
    using Strings for uint256;

    event AllowlistMerkleRootSet(uint256 tierId, bytes32 merkleRoot);
    event MintLimitSet(uint256 tierId, uint256 mintLimit);
    event CrowdfundLaunch(uint256 tierCount, bool transfersBlocked);
    event MemberBadgeTierAdd(uint256 tierId, uint256 mintPrice, uint256 supply, uint256 mintLimit);
    event MemberBadgeTransfersBlock(bool transfersBlocked);
    event MemberBadgeMint(address recipient, uint256 amount, uint256 tierIndex, uint256[] tokenIds);
    event TransferETH(address recipient, uint256 amount);

    /// @dev Points to address of the proxy factory set once during initialization
    address public factory;

    /// @dev Points to address of the proxy factory admin
    address public immutable proxyAdmin;

    /// @notice Used to track membership tiers
    struct MemberBadgeTier {
        uint256 id;                     // unique identifier for this tier (also maps directly to the index of this tier in the memberBadgeTiers array)
        uint256 price;                  // mint price
        uint256 startingId;             // initial tokenId
        uint256 endingId;               // final allocated tokenId
        uint256 currentId;              // the next tokenId to be minted for this tier
        bytes32 allowlistMerkleRoot;
        uint256 mintLimit;
    }

    /// @notice Tracks all membershipTiers
    MemberBadgeTier[] public memberBadgeTiers;

    mapping (bytes32 => uint256) public addressAndTierIndexToMinted;
    
    /// @notice Flag to prevent or allow transfers of member badges
    bool public transfersBlocked = false;

    /// @notice base URI for metadata location
    string public baseURI;

    /// @param _proxyAdmin address of proxy factory admin
    constructor(address _proxyAdmin) {
        proxyAdmin = _proxyAdmin;
    }

    /// @notice Initialization function
    function __KoopCore_init(
        string calldata _name,
        string calldata _symbol,
        address _factoryAddress,
        uint96 _royaltyFee
    ) public initializer {
        __ERC721URIStorage_init();
        __ERC721_init(_name, _symbol);
        __ERC2981_init();
        factory = _factoryAddress;
        _setDefaultRoyalty(address(this), _royaltyFee);
    }

    /** 
        @notice sets the merkle root for the allowlist of a specified member badge tier.  If set to `0x00`, no allowlist will be enforced.
    */
    /// @param _tierId tier id to update
    /// @param _allowlistMerkleRoot new merkle root used for allowlist
    function _setAllowlistMerkleRoot(
        uint256 _tierId,
        bytes32 _allowlistMerkleRoot
    ) 
        internal 
    {
        require(_tierId < memberBadgeTiers.length, "KoopCore::_setAllowlistMerkleRoot(): Cannot set allowlist root for a tier that does not exist");
        memberBadgeTiers[_tierId].allowlistMerkleRoot = _allowlistMerkleRoot;
        emit AllowlistMerkleRootSet(_tierId, _allowlistMerkleRoot);
    }

    /**
        @notice updates the mint limit for the specified tier ID.  Set to MAX_INT for no limit
     */
    /// @param _tierId tier id to update
    /// @param _mintLimit new mint limit to be set
    function _setMintLimit(
        uint256 _tierId,
        uint256 _mintLimit
    ) 
        internal
    {
        require(_tierId < memberBadgeTiers.length, "KoopCore::_setMintLimit(): Cannot set mint limit for a tier that does not exist");
        require(_mintLimit > 0, "KoopCore::_setMintLimit(): Mint limit must be greater than 0");
        memberBadgeTiers[_tierId].mintLimit = _mintLimit;
        emit MintLimitSet(_tierId, _mintLimit);
    }

    /// @notice Kicks off a membership NFT crowdfund.  Corresponding data should all have the same index in each array
    /// @param _tierPrices new tier prices
    /// @param _tierLimits new tier supply limits
    /// @param _allowlistMerkleRoots merkle roots for each tier.  0x00 if no allowlist set for specific tier
    /// @param _mintLimits maximum number of tokens an address can mint per tier.  Can be set to MAX_INT for no limit
    function _launchMemberBadgeCrowdfund(
        uint256[] calldata _tierPrices, 
        uint256[] calldata _tierLimits,
        bytes32[] calldata _allowlistMerkleRoots,
        uint256[] calldata _mintLimits,
        string calldata _baseURI,
        bool _blockTransfers
    ) 
        internal 
    {
        require(
            memberBadgeTiers.length == 0, 
            "Koop::_launchMemberBadgeCrowdfund(): crowdfund has already been launched for this Koop"
        );

        uint256 length = _tierPrices.length;
        require(_tierLimits.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");
        require(_allowlistMerkleRoots.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");
        require(_mintLimits.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");


        for(uint256 i = 0; i < length; i++) {
            _createMemberBadgeTier(_tierPrices[i], _tierLimits[i], _allowlistMerkleRoots[i], _mintLimits[i]);
        }
        transfersBlocked = _blockTransfers;

        /// @dev set baseURI to point to metadata
        baseURI = _baseURI;
        emit CrowdfundLaunch(length, _blockTransfers);
    }

    /// @notice adds new member badge tiers. Will not overwrite existing tiers.
    /// @param _tierPrices new tier prices
    /// @param _tierLimits new tier supply limits
    /// @param _allowlistMerkleRoots merkle roots for each tier.  0x00 if no allowlist set for specific tier
    /// @param _mintLimits maximum number of tokens an address can mint per tier.  Can be set to MAX_INT for no limit
    function _addMemberBadgeTiers(
        uint256[] calldata _tierPrices,
        uint256[] calldata _tierLimits,
        bytes32[] calldata _allowlistMerkleRoots,
        uint256[] calldata _mintLimits,
        string calldata _baseURI
    )
        internal
    {
        uint256 length = _tierPrices.length;
        require(_tierLimits.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");
        require(_allowlistMerkleRoots.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");
        require(_mintLimits.length == length, "Koop::_launchMemberBadgeCrowdfund(): all input arrays must be same length");

        for(uint256 i = 0; i < length; i++) {
            _createMemberBadgeTier(_tierPrices[i], _tierLimits[i], _allowlistMerkleRoots[i], _mintLimits[i]);
        }

        /// @dev update baseURI for new metadata
        baseURI = _baseURI;
    }

    function _createMemberBadgeTier(
        uint256 _tierPrice,
        uint256 _tierLimit,
        bytes32 _allowlistMerkleRoot,
        uint256 _mintLimit
    ) internal {
        uint256 startingId = memberBadgeTiers.length == 0 ? 0 : memberBadgeTiers[memberBadgeTiers.length - 1].endingId + 1;
        uint256 endingId = startingId + _tierLimit - 1;

        require(_tierLimit > 0, "KoopCore::_createMemberBadgeTier(): _tierLimit must be greater than 0");

        require(startingId + _tierLimit <= type(uint256).max, "KoopCore::_createMemberBadgeTier(): _tierLimit too high, allocated ids would exceed MAX_INT");

        /// @dev Mint limit must be greater than 0.  For no limit, set to MAX_INT
        require(_mintLimit > 0, "KoopCore::_createMemberBadgeTier(): _mintLimit must be greater than 0");

        uint256 currentTierId = memberBadgeTiers.length;

        /// @dev Insert tier into list
        memberBadgeTiers.push(MemberBadgeTier(currentTierId, _tierPrice, startingId, endingId, startingId, _allowlistMerkleRoot, _mintLimit));

        emit MemberBadgeTierAdd(currentTierId, _tierPrice, _tierLimit, _mintLimit);

        /// @dev increment currentTierId to next tier to be allocated
        currentTierId++;
    }

    function _updateRoyaltyFee(uint96 _royaltyFee) internal {
        _setDefaultRoyalty(address(this), _royaltyFee);
    }

    /// @notice sets flag to block or allow member badge transfers
    /// @param _blockTransfers blocks transfers if set to true, allows transfers if set to false
    function _blockMemberBadgeTransfers(bool _blockTransfers)
        internal
    {
        transfersBlocked = _blockTransfers;
        emit MemberBadgeTransfersBlock(transfersBlocked);
    }

    /** 
        @notice mints an NFT member badge based on provided tier index and sent value.  
        If allowlist is being enforced, must include a merkle proof to prove access.
        Enforces mint limit and updates number of tokens minted per id per member tier.
    */ 
    /// @dev will only mint a badge if msg.value == the price of the tier requested
    /// @param _tierId index of tier user is requesting to purchase
    /// @param _mintCount number of tokens to be minted for this specific tier
    /// @param _merkleProof generated proof for merkle tree used to prove msg.sender can mint a token from this tier
    function mintMemberBadge(uint256 _tierId, uint256 _mintCount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(memberBadgeTiers.length > 0, "Koop::mintMemberBadge(): a crowdfund has not begun yet");
        require(_tierId < memberBadgeTiers.length, "Koop::mintMemberBadge(): requested tier ID does not exist");
        require(_mintCount > 0, "Koop::mintMemberBadge(): must mint at least 1 token");

        MemberBadgeTier memory tier = memberBadgeTiers[_tierId];
        bytes32 addressAndTierIndexHash = keccak256(abi.encodePacked(msg.sender,_tierId));

        require(tier.currentId <= tier.endingId, "Koop::mintMemberBadge(): no more member badges available at this tier");
        require(tier.price * _mintCount == msg.value, "Koop::mintMemberBadge(): incorrect amount sent to contract for requested member badge tier");
        require(
            addressAndTierIndexToMinted[addressAndTierIndexHash] + _mintCount <= tier.mintLimit, 
            "Koop::mintMemberBadge(): User cannot mint the requested number of this member tier"
        );

        if(tier.allowlistMerkleRoot != bytes32(0x00)) {
            require(
                verifyProof(tier.allowlistMerkleRoot, keccak256(abi.encodePacked(msg.sender)), _merkleProof), 
                "Koop::mintMemberBadge(): address is not on allowlist"
            );
        }
        uint256 mintId = tier.currentId;
        memberBadgeTiers[_tierId].currentId += _mintCount;
        addressAndTierIndexToMinted[addressAndTierIndexHash] += _mintCount;        
        uint256[] memory mintedIds = new uint256[](_mintCount);

        for(uint256 i = 0; i < _mintCount; i++) {
            mintedIds[i] = mintId;
            _safeMint(msg.sender, mintId);
            mintId++;
        }
        
        emit MemberBadgeMint(msg.sender, msg.value, _tierId, mintedIds);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Koop::tokenURI(): this tokenId has not been minted yet");

        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    /// @notice used to withdraw funds from the contract
    /// @param _destination the destination of the funds
    /// @param _amount amount of funds to withdraw
    function _transferETH(
        address _destination,
        uint256 _amount
    ) internal {
        (bool success, ) = _destination.call{value: _amount}("");
        require(success, "Koop::_transferETH(): could not transfer ETH from contract");
        emit TransferETH(_destination, _amount);
    }

    /// @dev hook called before a token is transferred.  Used to enforce transfer blocking.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);

        /// @dev ensure transfers are not blocked if transferring (_to != 0x00 && _from != 0x00)
        require(_from == address(0) || _to == address(0) || !transfersBlocked, "Koop::_beforeTokenTransfer(): transfers are blocked for this token");
    }

    function _upgradeKoop(
        address _newLogic, 
        bytes calldata _data
    ) internal {
        ProxyFactoryUpgrade factoryContract = ProxyFactoryUpgrade(factory);
        factoryContract.upgradeKoop(_newLogic, _data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}