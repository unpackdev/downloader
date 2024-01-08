// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./MagicLampERC721.sol";

interface SuperMagic {
    function compose(address owner) external returns (bool);
    function bet(address owner) external returns (bool);
}

/**
 * @title MagicLamps NFT contract
 * @dev Extends MagicLampERC721 Non-Fungible Token Standard basic implementation
 */
contract MagicLamps is MagicLampERC721 {
    using SafeMath for uint256;
    using Address for address;

    // Public variables
    address public superMagicContract;

    // This is SHA256 hash of the provenance record of all MagicLamp artworks
    // It is derived by hashing every individual NFT's picture, and then concatenating all those hash, deriving yet another SHA256 from that.
    string public MAGICLAMPS_PROVENANCE = "";

    uint256 public constant SALE_START_TIMESTAMP = 1631372400;
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (7 days);
    uint256 public constant MAX_MAGICLAMP_SUPPLY = 10000;
    uint256 public MAGICLAMP_MINT_COUNT_LIMIT = 30;
    uint256 public curTicketId;
    mapping(address => uint256) public publicNumOfUser;
    mapping(address => uint256) public totalClaimed;

    uint256 public constant REFERRAL_REWARD_PERCENT = 1000; // 10%
    uint256 public constant LIQUIDITY_FUND_PERCENT = 1000;  // 10%

    bool public saleIsActive = false;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public mintPrice = 30000000000000000; // 0.03 ETH
    uint256 public aldnReward = 10000000000000000000; // (10% of ALDN totalSupply) / 10000

    // Mapping from token ID to puzzle
    mapping (uint256 => uint256) public puzzles;

    // Referral management
    uint256 public totalReferralRewardAmount;
    uint256 public distributedReferralRewardAmount;
    mapping(address => uint256) public referralRewards;
    mapping(address => mapping(address => bool)) public referralStatus;

    address public liquidityFundAddress = 0x9C73aAdcFb1ee7314d2Ac96150073F88b47E0A32;
    address public devAddress = 0xB689bA113effd47d38CfF88A682465945bd80829;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Events
    event DistributeReferralRewards(uint256 indexed magicLampIndex, uint256 amount);
    event EarnReferralReward(address indexed account, uint256 amount);
    event WithdrawFund(uint256 liquidityFund, uint256 treasuryFund);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address aladdin, address genie) MagicLampERC721(name_, symbol_) {
        aladdinToken = aladdin;
        genieToken = genie;

        // register the supported interfaces to conform to MagiclampsERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function reserveNfts(address _to, uint256 _numberOfTokens) external onlyOwner {
        uint256 supply = totalSupply();
        require(_to != address(0), "Invalid address to reserve.");
        require(supply == curTicketId, "Ticket id and supply not matched.");
        uint256 i;
        
        for (i = 0; i < _numberOfTokens; i++) {
            _safeMint(_to, supply + i);
        }

        curTicketId = curTicketId.add(_numberOfTokens);
    }

    function getUserClaimableTicketCount(address user) public view returns (uint256) {
        return publicNumOfUser[user].sub(totalClaimed[user]);
    }

    function claimLamps() external {
        uint256 numbersOfTickets = getUserClaimableTicketCount(_msgSender());
        IERC20(aladdinToken).transfer(_msgSender(), aldnReward.mul(numbersOfTickets));

        for(uint256 i = 0; i < numbersOfTickets; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            puzzles[mintIndex] = getRandomNumber(type(uint256).min, type(uint256).max.sub(1));
            _safeMint(_msgSender(), mintIndex);
        }

        totalClaimed[_msgSender()] = numbersOfTickets.add(totalClaimed[_msgSender()]);
    }

    function mintMagicLamp(uint256 numberOfTokens, address referrer) external payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens <= MAGICLAMP_MINT_COUNT_LIMIT, "Exceeds mint count limit");
        require(curTicketId.add(numberOfTokens) <= MAX_MAGICLAMP_SUPPLY, "Exceeds max supply");
        require(numberOfTokens > 0, "Must mint at least one token");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        publicNumOfUser[_msgSender()] = numberOfTokens.add(publicNumOfUser[_msgSender()]);
        curTicketId = curTicketId.add(numberOfTokens);

        if (referrer != address(0) && referrer != _msgSender()) {
            _rewardReferral(referrer, _msgSender(), msg.value);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (curTicketId == MAX_MAGICLAMP_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    function setSuperMagicContractAddress(address contractAddress) public onlyOwner {
        superMagicContract = contractAddress;
    }

    /**
     * Set price to mint a MagicLamps.
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMintCountLimit(uint256 count) external onlyOwner {
        MAGICLAMP_MINT_COUNT_LIMIT = count;
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    /**
     * Set ALDN reward amount to mint a MagicLamp.
     */
    function setALDNReward(uint256 _aldnReward) external onlyOwner {
        aldnReward = _aldnReward;
    }

    function bet(uint256 useTokenId1) public {
        require(superMagicContract != address(0), "SuperMagic contract address need be set");

        address from = msg.sender;
        require(ownerOf(useTokenId1) == from, "ERC721: use of token1 that is not own");

        _burn(useTokenId1);
        // safeTransferFrom(from, superMagicContract, useTokenId1);

        SuperMagic superMagic = SuperMagic(superMagicContract);
        bool result = superMagic.bet(from);
        require(result, "SuperMagic compose failed");
    }

    function compose(uint256 useTokenId1, uint256 useTokenId2, uint256 useTokenId3) public {
        require(superMagicContract != address(0), "SuperMagic contract address need be set");

        address from = msg.sender;
        require(ownerOf(useTokenId1) == from, "ERC721: use of token1 that is not own");
        require(ownerOf(useTokenId2) == from, "ERC721: use of token2 that is not own");
        require(ownerOf(useTokenId3) == from, "ERC721: use of token3 that is not own");

        _burn(useTokenId1);
        _burn(useTokenId2);
        _burn(useTokenId3);
        // safeTransferFrom(from, superMagicContract, useTokenId1);
        // safeTransferFrom(from, superMagicContract, useTokenId2);
        // safeTransferFrom(from, superMagicContract, useTokenId3);

        SuperMagic superMagic = SuperMagic(superMagicContract);
        bool result = superMagic.compose(from);
        require(result, "SuperMagic compose failed");
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        MAGICLAMPS_PROVENANCE = _provenanceHash;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public virtual {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_MAGICLAMP_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_MAGICLAMP_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Withdraws liquidity and treasury fund.
     */
    function withdrawFund() public onlyOwner {
        uint256 fund = address(this).balance.sub(totalReferralRewardAmount).add(distributedReferralRewardAmount);
        uint256 liquidityFund = _percent(fund, LIQUIDITY_FUND_PERCENT);
        payable(liquidityFundAddress).transfer(liquidityFund);
        uint256 treasuryFund = fund.sub(liquidityFund);
        uint256 devFund = treasuryFund.mul(30).div(100);
        payable(devAddress).transfer(devFund);
        payable(msg.sender).transfer(treasuryFund.sub(devFund));

        emit WithdrawFund(liquidityFund, treasuryFund);
    }

    /**
     * @dev Withdraws ALDN to treasury if ALDN after sale ended
     */
    function withdrawFreeToken(address token) public onlyOwner {	
        if (token == aladdinToken) {	
            require(totalSupply() >= MAX_MAGICLAMP_SUPPLY, "Sale has not ended");	
        }	
        	
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));	
    }

    function _rewardReferral(address referrer, address referee, uint256 referralAmount) internal {
        uint256 referrerBalance = MagicLampERC721.balanceOf(referrer);
        bool status = referralStatus[referrer][referee];
        uint256 rewardAmount = _percent(referralAmount, REFERRAL_REWARD_PERCENT);

        if (referrerBalance != 0 && rewardAmount != 0 && !status) {
            referralRewards[referrer] = referralRewards[referrer].add(rewardAmount);
            totalReferralRewardAmount = totalReferralRewardAmount.add(rewardAmount);
            emit EarnReferralReward(referrer, rewardAmount);
            referralRewards[referee] = referralRewards[referee].add(rewardAmount);
            totalReferralRewardAmount = totalReferralRewardAmount.add(rewardAmount);
            emit EarnReferralReward(referee, rewardAmount);
            referralStatus[referrer][referee] = true;
        }
    }

    function distributeReferralRewards(uint256 startMagicLampId, uint256 endMagicLampId) external onlyOwner {
        require(block.timestamp > SALE_START_TIMESTAMP, "Sale has not started");
        require(startMagicLampId < totalSupply(), "Index is out of range");

        if (endMagicLampId >= totalSupply()) {
            endMagicLampId = totalSupply().sub(1);
        }
        
        for (uint256 i = startMagicLampId; i <= endMagicLampId; i++) {
            address owner = ownerOf(i);
            uint256 amount = referralRewards[owner];
            if (amount > 0) {
                magicLampWallet.depositETH{ value: amount }(address(this), i, amount);                
                distributedReferralRewardAmount = distributedReferralRewardAmount.add(amount);
                delete referralRewards[owner];
                emit DistributeReferralRewards(i, amount);
            }
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    function emergencyWithdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}
