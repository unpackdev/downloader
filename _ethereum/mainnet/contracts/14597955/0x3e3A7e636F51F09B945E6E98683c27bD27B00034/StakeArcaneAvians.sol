// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./IFLAP.sol";

contract StakeArcaneAvians is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public ERC20_CONTRACT = 0xCF01093204F77cC52Ba4C53f5f042D23E8dB46D8;
    address public ERC721_CONTRACT = 0xD65C946eDB5B84021323ab9726d3a2a0D1ee4aE8;
    uint256 public EXPIRATION; //expiry block number (avg 15s per block)
    /// owner => #NFTsStaked
    mapping (address => uint256) public tokensStakedByUser;
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;
    mapping (uint256 => uint256) public tokenRarity;
    uint256[2] public rewardRate;   
    bool started;
    
    uint256 public Bonus = 1 ether;

    bool public BonusActivated = true;

    constructor() {
        EXPIRATION = block.number + 100000000000000;
        // number of tokens Per day
        rewardRate = [6, 9];
        started = false;
    }

    function setRate(uint256 _rarity, uint256 _rate) public onlyOwner() {
        rewardRate[_rarity] = _rate;
    }

    function setRarity(uint256 _tokenId, uint256 _rarity) public onlyOwner() {
        tokenRarity[_tokenId] = _rarity;
    }

    function setBatchRarity(uint256[] memory _tokenIds, uint256 _rarity) public onlyOwner() {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            tokenRarity[tokenId] = _rarity;
        }
    }

    function setExpiration(uint256 _expiration) public onlyOwner() {
        EXPIRATION = _expiration;
    }

    
    function toggleStart(bool _state) public onlyOwner() {
        started = _state;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner() {
        ERC20_CONTRACT = _tokenAddress;
    }

        function setCollectionAddress(address _CollectionAddress) public onlyOwner() {
        ERC721_CONTRACT = _CollectionAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

        function BonusReward(address owner) public view returns (uint256 bonus){
        if (BonusActivated == false) {
            return 0;
        }
        if(tokensStakedByUser[owner] == 1) {
            return 0;
        }

        if(tokensStakedByUser[owner] == 2) {
            return Bonus;
        }
         if(tokensStakedByUser[owner] == 3) {
            return Bonus + 1 ether;
        }
        if(tokensStakedByUser[owner] == 4) {
            return Bonus + 2 ether;
        }
         if(tokensStakedByUser[owner] == 5) {
            return Bonus + 3 ether;
        }
         if(tokensStakedByUser[owner] == 6) {
            return Bonus + 4 ether;
        }
         if(tokensStakedByUser[owner] == 7) {
            return Bonus + 5 ether;
        }
         if(tokensStakedByUser[owner] == 8) {
            return Bonus + 6 ether;
        }
         if(tokensStakedByUser[owner] == 9) {
            return Bonus + 7 ether;
        }
         if(tokensStakedByUser[owner] == 10) {
            return Bonus + 8 ether;
        }
         if(tokensStakedByUser[owner] > 10) {
            return Bonus + 10 ether;
        }
    }

    function findRate(uint256 tokenId)
        public
        view
        returns (uint256 rate) 
    {
        uint256 rarity = tokenRarity[tokenId];
        uint256 perDay = rewardRate[rarity];
        
        // 6000 blocks per day
        // perDay / 6000 = reward per block

        rate = (perDay * 1e18) / 6000;
        
        return rate;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 rate = findRate(tokenId);
            rewards[i] =
                rate *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (Math.min(block.number, EXPIRATION) -
                    depositBlocks[account][tokenId]);
        }
    }

    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 curblock = Math.min(block.number, EXPIRATION);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositBlocks[msg.sender][tokenIds[i]] = curblock;
        }
        uint256 RewardBonus = reward + BonusReward(_msgSender());

        if (reward > 0) {
            IFLAP(ERC20_CONTRACT).whitelist_mint(msg.sender, RewardBonus);
        }
    }

    function deposit(uint256[] calldata tokenIds) external {
        require(started, 'StakeSeals: Staking contract not started yet');

        claimRewards(tokenIds);
        

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
            tokensStakedByUser[_msgSender()] += 1;
        }
    }

    function admin_deposit(uint256[] calldata tokenIds) onlyOwner() external {
        claimRewards(tokenIds);
        

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'StakeSeals: Token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);
            tokensStakedByUser[_msgSender()] -= 1;

            IERC721(ERC721_CONTRACT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }

        function ActivateBonus(bool _state) public onlyOwner{
        BonusActivated = _state;
    }


        function setBonus(uint256 _new) public onlyOwner{
        Bonus = _new;
    }
}