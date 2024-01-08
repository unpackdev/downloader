// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

interface IGoldHunter {
    function ownerOf(uint id) external view returns (address);
    function isPirate(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
}

interface IGGold {
    function mint(address account, uint amount) external;
}

contract TreasureIsland is Ownable, IERC721Receiver {
    bool private _paused = false;

    uint16 private _randomIndex = 0;
    uint private _randomCalls = 0;
    mapping(uint => address) private _randomSource;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint16 tokenId, uint value);
    event GoldMinerClaimed(uint16 tokenId, uint earned, bool unstaked);
    event PirateClaimed(uint16 tokenId, uint earned, bool unstaked);

    IGoldHunter public goldHunter;
    IGGold public gold;

    mapping(uint256 => uint256) public goldMinerIndices;
    mapping(address => Stake[]) public goldMinerStake;

    mapping(uint256 => uint256) public pirateIndices;
    mapping(address => Stake[]) public pirateStake;
    address[] public pirateHolders;

    // Total staked tokens
    uint public totalGoldMinerStaked;
    uint public totalPirateStaked = 0;
    uint public unaccountedRewards = 0;

    // GoldMiner earn 10000 $GGOLD per day
    uint public constant DAILY_GOLD_RATE = 10000 ether;
    uint public constant MINIMUM_TIME_TO_EXIT = 2 days;
    uint public constant TAX_PERCENTAGE = 20;
    uint public constant MAXIMUM_GLOBAL_GOLD = 2400000000 ether;

    uint public totalGoldEarned;

    uint public lastClaimTimestamp;
    uint public pirateReward = 0;

    // emergency rescue to allow unstaking without any checks but without $GGOLD
    bool public rescueEnabled = false;

    constructor() {
        // Fill random source addresses
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511;
        _randomSource[3] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[4] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[5] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
        _randomSource[6] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setGoldHunter(address _goldHunter) external onlyOwner {
        goldHunter = IGoldHunter(_goldHunter);
    }

    function setGold(address _gold) external onlyOwner {
        gold = IGGold(_gold);
    }

    function getAccountGoldMiners(address user) external view returns (Stake[] memory) {
        return goldMinerStake[user];
    }

    function getAccountPirates(address user) external view returns (Stake[] memory) {
        return pirateStake[user];
    }

    function addTokensToStake(address account, uint16[] calldata tokenIds) external {
        require(account == msg.sender || msg.sender == address(goldHunter), "You do not have a permission to do that");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (msg.sender != address(goldHunter)) {
                // dont do this step if its a mint + stake
                require(goldHunter.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to address");
                goldHunter.transferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (goldHunter.isPirate(tokenIds[i])) {
                _stakePirates(account, tokenIds[i]);
            } else {
                _stakeGoldMiners(account, tokenIds[i]);
            }
        }
    }

    function _stakeGoldMiners(address account, uint16 tokenId) internal whenNotPaused _updateEarnings {
        totalGoldMinerStaked += 1;

        goldMinerIndices[tokenId] = goldMinerStake[account].length;
        goldMinerStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        }));
        emit TokenStaked(account, tokenId, block.timestamp);
    }


    function _stakePirates(address account, uint16 tokenId) internal {
        totalPirateStaked += 1;

        // If account already has some pirates no need to push it to the tracker
        if (pirateStake[account].length == 0) {
            pirateHolders.push(account);
        }

        pirateIndices[tokenId] = pirateStake[account].length;
        pirateStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(pirateReward)
            }));

        emit TokenStaked(account, tokenId, pirateReward);
    }


    function claimFromStake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!goldHunter.isPirate(tokenIds[i])) {
                owed += _claimFromMiner(tokenIds[i], unstake);
            } else {
                owed += _claimFromPirate(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        gold.mint(msg.sender, owed);
    }

    function _claimFromMiner(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = goldMinerStake[msg.sender][goldMinerIndices[tokenId]];
        require(stake.owner == msg.sender, "This NTF does not belong to address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait 2 days since last claim");

        if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
            owed = ((block.timestamp - stake.value) * DAILY_GOLD_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $GGOLD production stopped already
        } else {
            owed = ((lastClaimTimestamp - stake.value) * DAILY_GOLD_RATE) / 1 days; // stop earning additional $GGOLD if it's all been earned
        }
        if (unstake) {
            if (getSomeRandomNumber(tokenId, 100) <= 50) {
                _payTax(owed);
                owed = 0;
            }
            updateRandomIndex();
            totalGoldMinerStaked -= 1;

            Stake memory lastStake = goldMinerStake[msg.sender][goldMinerStake[msg.sender].length - 1];
            goldMinerStake[msg.sender][goldMinerIndices[tokenId]] = lastStake;
            goldMinerIndices[lastStake.tokenId] = goldMinerIndices[tokenId];
            goldMinerStake[msg.sender].pop();
            delete goldMinerIndices[tokenId];

            goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            _payTax((owed * TAX_PERCENTAGE) / 100); // Pay some $GGOLD to pirates!
            owed = (owed * (100 - TAX_PERCENTAGE)) / 100;
            
            uint80 timestamp = uint80(block.timestamp);

            goldMinerStake[msg.sender][goldMinerIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: timestamp
            }); // reset stake
        }

        emit GoldMinerClaimed(tokenId, owed, unstake);
    }

    function _claimFromPirate(uint16 tokenId, bool unstake) internal returns (uint owed) {
        require(goldHunter.ownerOf(tokenId) == address(this), "This NTF does not belong to address");

        Stake memory stake = pirateStake[msg.sender][pirateIndices[tokenId]];

        require(stake.owner == msg.sender, "This NTF does not belong to address");
        owed = (pirateReward - stake.value);

        if (unstake) {
            totalPirateStaked -= 1; // Remove Alpha from total staked

            Stake memory lastStake = pirateStake[msg.sender][pirateStake[msg.sender].length - 1];
            pirateStake[msg.sender][pirateIndices[tokenId]] = lastStake;
            pirateIndices[lastStake.tokenId] = pirateIndices[tokenId];
            pirateStake[msg.sender].pop();
            delete pirateIndices[tokenId];
            updatePirateOwnerAddressList(msg.sender);

            goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            pirateStake[msg.sender][pirateIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(pirateReward)
            }); // reset stake
        }
        emit PirateClaimed(tokenId, owed, unstake);
    }

    function updatePirateOwnerAddressList(address account) internal {
        if (pirateStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all pirates
        address lastOwner = pirateHolders[pirateHolders.length - 1];
        uint indexOfHolder = 0;
        for (uint i = 0; i < pirateHolders.length; i++) {
            if (pirateHolders[i] == account) {
                indexOfHolder = i;
                break;
            }
        }
        pirateHolders[indexOfHolder] = lastOwner;
        pirateHolders.pop();
    }

    function rescue(uint16[] calldata tokenIds) external {
        require(rescueEnabled, "Rescue disabled");
        uint16 tokenId;
        Stake memory stake;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!goldHunter.isPirate(tokenId)) {
                stake = goldMinerStake[msg.sender][goldMinerIndices[tokenId]];

                require(stake.owner == msg.sender, "This NTF does not belong to address");

                totalGoldMinerStaked -= 1;

                Stake memory lastStake = goldMinerStake[msg.sender][goldMinerStake[msg.sender].length - 1];
                goldMinerStake[msg.sender][goldMinerIndices[tokenId]] = lastStake;
                goldMinerIndices[lastStake.tokenId] = goldMinerIndices[tokenId];
                goldMinerStake[msg.sender].pop();
                delete goldMinerIndices[tokenId];

                goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");

                emit GoldMinerClaimed(tokenId, 0, true);
            } else {
                stake = pirateStake[msg.sender][pirateIndices[tokenId]];
        
                require(stake.owner == msg.sender, "This NTF does not belong to address");

                totalPirateStaked -= 1;
                
                    
                Stake memory lastStake = pirateStake[msg.sender][pirateStake[msg.sender].length - 1];
                pirateStake[msg.sender][pirateIndices[tokenId]] = lastStake;
                pirateIndices[lastStake.tokenId] = pirateIndices[tokenId];
                pirateStake[msg.sender].pop();
                delete pirateIndices[tokenId];
                updatePirateOwnerAddressList(msg.sender);
                
                goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
                
                emit PirateClaimed(tokenId, 0, true);
            }
        }
    }

    function _payTax(uint _amount) internal {
        if (totalPirateStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        pirateReward += (_amount + unaccountedRewards) / totalPirateStaked;
        unaccountedRewards = 0;
    }


    modifier _updateEarnings() {
        if (totalGoldEarned < MAXIMUM_GLOBAL_GOLD) {
            totalGoldEarned += ((block.timestamp - lastClaimTimestamp) * totalGoldMinerStaked * DAILY_GOLD_RATE) / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }


    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }


    function randomPirateOwner() external returns (address) {
        if (totalPirateStaked == 0) return address(0x0);

        uint holderIndex = getSomeRandomNumber(totalPirateStaked, pirateHolders.length);
        updateRandomIndex();

        return pirateHolders[holderIndex];
    }

    function updateRandomIndex() internal {
        _randomIndex += 1;
        _randomCalls += 1;
        if (_randomIndex > 6) _randomIndex = 0;
    }

    function getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint16(random % _limit);
    }

    function changeRandomSource(uint _id, address _address) external onlyOwner {
        _randomSource[_id] = _address;
    }

    function shuffleSeeds(uint _seed, uint _max) external onlyOwner {
        uint shuffleCount = getSomeRandomNumber(_seed, _max);
        _randomIndex = uint16(shuffleCount);
        for (uint i = 0; i < shuffleCount; i++) {
            updateRandomIndex();
        }
    }

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to this contact directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
