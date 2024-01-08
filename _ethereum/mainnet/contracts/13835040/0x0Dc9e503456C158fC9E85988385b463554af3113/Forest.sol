// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IMetaMoose {
    function ownerOf(uint id) external view returns (address);
    function isHunter(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
    function totalSupply() external view returns (uint);
}

interface IBatt {
    function mint(address account, uint amount) external;
}

interface IRandomNumGenerator {
    function getRandomNumber(uint _seed, uint _limit) external view returns (uint16);
}

contract Forest is Ownable, IERC721Receiver, ReentrancyGuard {

    struct Stake {
        uint16 tokenId;
        uint value;
    }

    IMetaMoose public metaMoose;
    IBatt public batt;
    IRandomNumGenerator randomGen;

    mapping(uint256 => uint256) public harvesterIndices;
    mapping(address => Stake[]) public harvesterStake;

    mapping(uint256 => uint256) public hunterIndices;
    mapping(address => Stake[]) public hunterStake;
    address[] public hunterHolders;

    uint public totalHarvesterStaked;
    uint public totalHunterStaked;

    uint public constant MINIMUM_TIME_TO_EXIT = 5 days;
    uint public constant TAX_PERCENTAGE = 20;
    uint public constant TAX_PERCENTAGE_UNSTAKE = 40;

    uint public totalBattClaimed;
    uint public stakingEndTimestamp;
    uint public unaccountedRewards;
    uint public hunterReward;

    bool private _paused = false;
    bool public rescueEnabled = false;

    event TokenStaked(address owner, uint16 tokenId, uint value);
    event HarvesterClaimed(uint16 tokenId, uint earned, bool unstaked);
    event HunterClaimed(uint16 tokenId, uint earned, bool unstaked);

    constructor() {}

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }


    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    function setContracts(IMetaMoose _metaMoose, IBatt _batt, IRandomNumGenerator _randomGen) external onlyOwner {
        metaMoose = IMetaMoose(_metaMoose);
        batt = IBatt(_batt);
        randomGen = IRandomNumGenerator(_randomGen);
    }

    function setStakingEndTimestamp(uint _stakingEndTimestamp) external onlyOwner {
        stakingEndTimestamp = _stakingEndTimestamp;
    }


    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function getDailyBattRate() public view returns (uint) {
        if (metaMoose.totalSupply() <= 8888) {
            return 10000 ether;
        } else if (metaMoose.totalSupply() <= 15554) {
            return 12000 ether;
        } else {
            return 15000 ether;
        }
    }

    function getAccountHarvesters(address user) external view returns (Stake[] memory) {
        return harvesterStake[user];
    }

    function getAccountHunters(address user) external view returns (Stake[] memory) {
        return hunterStake[user];
    }


    function addTokensToStake(address account, uint16[] calldata tokenIds) external whenNotPaused {
        require(account == msg.sender || msg.sender == address(metaMoose), "You do not have a permission to do that");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (msg.sender != address(metaMoose)) {
                // dont do this step if its a mint + stake
                require(metaMoose.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to address");
                metaMoose.transferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (metaMoose.isHunter(tokenIds[i])) {
                _stakeHunters(account, tokenIds[i]);
            } else {
                _stakeHarvesters(account, tokenIds[i]);
            }
        }
    }

    function _stakeHarvesters(address account, uint16 tokenId) internal {
        totalHarvesterStaked += 1;

        harvesterIndices[tokenId] = harvesterStake[account].length;
        harvesterStake[account].push(Stake({
            tokenId: uint16(tokenId),
            value: block.timestamp
        }));
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _stakeHunters(address account, uint16 tokenId) internal {
        totalHunterStaked += 1;

        // If account already has some hunters no need to push it to the tracker
        if (hunterStake[account].length == 0) {
            hunterHolders.push(account);
        }

        hunterIndices[tokenId] = hunterStake[account].length;
        hunterStake[account].push(Stake({
            tokenId: uint16(tokenId),
            value: hunterReward
        }));

        emit TokenStaked(account, tokenId, hunterReward);
    }

    function claimFromStake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant {
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!metaMoose.isHunter(tokenIds[i])) {
                owed += _claimFromHarvester(tokenIds[i], unstake);
            } else {
                owed += _claimFromHunter(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        batt.mint(msg.sender, owed);
        totalBattClaimed += owed;
    }

    function _claimFromHarvester(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = harvesterStake[msg.sender][harvesterIndices[tokenId]];
        require(stake.tokenId == tokenId, "This NTF does not belong to address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait more since last claim");

        if (stake.value >= stakingEndTimestamp) {
            owed = 0;
        } else if (block.timestamp < stakingEndTimestamp) {
            owed = ((block.timestamp - stake.value) * getDailyBattRate()) / 1 days;
        } else {
            owed = ((stakingEndTimestamp - stake.value) * getDailyBattRate()) / 1 days;
        }
        if (unstake) {
            uint tax = owed * TAX_PERCENTAGE_UNSTAKE / 100; // pay 40% tax
            _payTax(tax);
            owed = owed - tax;

            totalHarvesterStaked -= 1;

            Stake memory lastStake = harvesterStake[msg.sender][harvesterStake[msg.sender].length - 1];
            harvesterStake[msg.sender][harvesterIndices[tokenId]] = lastStake;
            harvesterIndices[lastStake.tokenId] = harvesterIndices[tokenId];
            harvesterStake[msg.sender].pop();
            delete harvesterIndices[tokenId];

            metaMoose.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            _payTax((owed * TAX_PERCENTAGE) / 100); // Pay some $BATT to hunters!
            owed = (owed * (100 - TAX_PERCENTAGE)) / 100;

            uint80 timestamp = uint80(block.timestamp);

            harvesterStake[msg.sender][harvesterIndices[tokenId]] = Stake({
                tokenId: uint16(tokenId),
                value: timestamp
            }); // reset stake
        }

        emit HarvesterClaimed(tokenId, owed, unstake);
    }

    function _claimFromHunter(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = hunterStake[msg.sender][hunterIndices[tokenId]];
        require(stake.tokenId == tokenId, "This NTF does not belong to address");
        owed = (hunterReward - stake.value);

        if (unstake) {
            totalHunterStaked -= 1; // Remove Alpha from total staked

            Stake memory lastStake = hunterStake[msg.sender][hunterStake[msg.sender].length - 1];
            hunterStake[msg.sender][hunterIndices[tokenId]] = lastStake;
            hunterIndices[lastStake.tokenId] = hunterIndices[tokenId];
            hunterStake[msg.sender].pop();
            delete hunterIndices[tokenId];
            updateHunterOwnerAddressList(msg.sender);

            metaMoose.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            hunterStake[msg.sender][hunterIndices[tokenId]] = Stake({
                tokenId: uint16(tokenId),
                value: hunterReward
            }); // reset stake
        }
        emit HunterClaimed(tokenId, owed, unstake);
    }

    function updateHunterOwnerAddressList(address account) internal {
        if (hunterStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all hunters
        address lastOwner = hunterHolders[hunterHolders.length - 1];
        uint indexOfHolder = 0;
        for (uint i = 0; i < hunterHolders.length; i++) {
            if (hunterHolders[i] == account) {
                indexOfHolder = i;
                break;
            }
        }
        hunterHolders[indexOfHolder] = lastOwner;
        hunterHolders.pop();
    }

    function rescue(uint16[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "Rescue disabled");
        uint16 tokenId;
        Stake memory stake;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!metaMoose.isHunter(tokenId)) {
                stake = harvesterStake[msg.sender][harvesterIndices[tokenId]];

                require(stake.tokenId == tokenId, "This NTF does not belong to address");

                totalHarvesterStaked -= 1;

                Stake memory lastStake = harvesterStake[msg.sender][harvesterStake[msg.sender].length - 1];
                harvesterStake[msg.sender][harvesterIndices[tokenId]] = lastStake;
                harvesterIndices[lastStake.tokenId] = harvesterIndices[tokenId];
                harvesterStake[msg.sender].pop();
                delete harvesterIndices[tokenId];

                metaMoose.safeTransferFrom(address(this), msg.sender, tokenId, "");

                emit HarvesterClaimed(tokenId, 0, true);
            } else {
                stake = hunterStake[msg.sender][hunterIndices[tokenId]];

                require(stake.tokenId == tokenId, "This NTF does not belong to address");

                totalHunterStaked -= 1;

                Stake memory lastStake = hunterStake[msg.sender][hunterStake[msg.sender].length - 1];
                hunterStake[msg.sender][hunterIndices[tokenId]] = lastStake;
                hunterIndices[lastStake.tokenId] = hunterIndices[tokenId];
                hunterStake[msg.sender].pop();
                delete hunterIndices[tokenId];
                updateHunterOwnerAddressList(msg.sender);

                metaMoose.safeTransferFrom(address(this), msg.sender, tokenId, "");

                emit HunterClaimed(tokenId, 0, true);
            }
        }
    }

    function _payTax(uint _amount) internal {
        if (totalHunterStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        hunterReward += (_amount + unaccountedRewards) / totalHunterStaked;
        unaccountedRewards = 0;
    }

    function randomHunterOwner(uint256 seed) external view returns (address) {
        if (totalHunterStaked == 0) return address(0x0);

        uint holderIndex = randomGen.getRandomNumber(totalHarvesterStaked +  totalHunterStaked + seed, hunterHolders.length);

        return hunterHolders[holderIndex];
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