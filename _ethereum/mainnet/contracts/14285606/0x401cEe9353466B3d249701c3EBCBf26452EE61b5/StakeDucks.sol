// DuckFrens (www.duckfrens.com) - Staking Contract

// MMMMMMMMMMMMMMMMMMMMMMMMMM`MMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0O0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK0OxxOOOO00KKNWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMNKOO0KXXXXXXXK000K0KNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNKOOKXXXXXXXXXXXXXXNXK0KNMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMN0OOKXXXXXXXXXXXXXXXXXNNN0OXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMXkdOXXXXXXXXXXXXXXXXXXXXXNN0OXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXkdOKXXXXXXXNNNNXXXXXXXXXXXXXkkNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWOdOKXXXXXKkddkOKNNXXXXXXXXX0dodkXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMKxkKXXXXX0d;;oxld0XXXXXXXXXXkclxd0MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXxdkKXXXXXk:,;ooc:dKXXXXXXXXXOc;;cOWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXddOKXXXXXk:,,,,,;dKXX0OOkxxxdl:cdO0XWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXdoOKXXXXX0xlcccldOKkdoolllooooooodokNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNkdk0KXXXXXK0OO0KKOdooddoooodddddxxlxNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0kkOKXXXXXXXXXXXxlllooddddddxkkkkkKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKxoxOKXXXXXXXXXKOxdllllllllloxkKWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0OkxxdxxxkkO0KXKKKK0OkxdollloOXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0OOKK0OOkkxdddxxxddddddddddxkkkkKNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWKkk0KKXXKK00OOOOkkkkkkkkkkkOOOOOOOO0KWMMMMMMMMMMMMMMM
// MMMMMMMMMMN00K000xxOO0KXXXXXXKKK00000000000000000KKNXO0WMMMMMMMMMMMMMM
// MMMMMMMMMMKdoolcldkOKKKKKKXXXXXXKKKKXXXXXXXXXXXXXXKKXXO0WMMMMMMMMMMMMM
// MMMMMMMMMMXxxkoccdkO0KK00KXKKKKOk0KXXXXXXXXXXXXXXXXKO0kONMMMMMMMMMMMMM
// MMMMMMMMMMWOdkkolodxkOOO0Oxkkkxk0XXXXXXXXXXXXXXXXXXX0ddONMMMMMMMMMMMMM
// MMMMMMMMMMMNOxxxxdoooodxxxdxkO0KKKXXXXXXXXXXXXXXXXXKOkKNMMMMMMMMMMMMMM
// MMMMMMMMMMMMWXOxxkOxdxO0KKKXXXXOx0XXXXXXXXXXXXXXXXKO0NMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXOkxold0XXXXXXX0ddk0KKXXXXXXXXXXXK00KWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWX0xlxOKXXXX0dlooxxkOO0O000OOkO0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWKkdxOO0OO0K0OOOOOxlllllllxNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWWN0oclookXMMMMMMMMNOlclllo0NNNNWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNOxolooloxOOXWMMMMMN0dlcclclxkddkOKWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWkccccloc:odlxNMMMMWOlcccc;;cddlcoodKMMMMMMMMMMMMMMMM

// A fork of Head DAO with bonuses, and more flexibility

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

interface IBread {
    function authorisedMint(address account, uint256 amount) external;

    function overTotalSupply() external view returns (bool);
}

contract StakeDucks is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    // Contract Addresses
    address public immutable erc721Address;
    address public erc20Address;

    // Daily Emission Rate
    uint256 public rate;

    // Level
    uint256 public levelUpCostPerLevel = 500 * 1e18;
    mapping(uint256 => uint256) public level;

    // Bonuses
    uint256[3] public stakeBonuses = [10, 25, 100];

    // Deposit Tracking
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositTimes;

    // Events
    event Deposit(address addr, uint256[] tokenIds);
    event Withdraw(address addr, uint256[] tokenIds);
    event RewardClaim(address addr, uint256 rewardTotal);

    constructor(
        address _erc721Address,
        address _erc20Address,
        uint256 _rate
    ) {
        erc721Address = _erc721Address;
        erc20Address = _erc20Address;
        rate = _rate;
    }

    /**
     * Track deposits of an account
     */
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

    /**
     * Calculates the staking bonus after an elapsed number of seconds
     */
    function _calculateStakeBonus(uint256 secondsElapsed)
        private
        view
        returns (uint256)
    {
        if (secondsElapsed >= 7776000) {
            return stakeBonuses[2];
        } else if (secondsElapsed >= 2592000) {
            return stakeBonuses[1];
        } else if (secondsElapsed >= 1209600) {
            return stakeBonuses[0];
        }
        return 0;
    }

    /**
     * Allows contract owner to control the staking bonus
     */
    function setStakeBonus(uint256 _index, uint256 _bonus) external onlyOwner {
        require(_index >= 0 && _index < 3, "Invalid Index");
        stakeBonuses[_index] = _bonus;
    }

    /**
     * Allows contract owner to adjust the daily emission rate (in WEI)
     */
    function setDailyRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    /**
     * Calculates the rewards for specific tokens under an address
     */
    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            // chance of an arthmetic underflow/overflow super dooper unlikely
            // deposit times will always be below or equal to the current block time
            unchecked {
                uint256 tokenId = tokenIds[i];
                uint256 blocksSinceStake = block.timestamp -
                    _depositTimes[account][tokenId];
                rewards[i] =
                    ((_deposits[account].contains(tokenId) ? 1 : 0) *
                        (rate * blocksSinceStake) *
                        (_calculateStakeBonus(blocksSinceStake) + 100)) /
                    8640000;
            }
        }
        return rewards;
    }

    /**
     * Claim the rewards for the tokens
     */
    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            // unlikely to overflow again, not deposited will be zero
            unchecked {
                reward += rewards[i];
            }
            _depositTimes[msg.sender][tokenIds[i]] = block.timestamp;
        }

        // if we are within the total supply of $BREAD, then it will create an emission
        if (reward > 0 && !IBread(erc20Address).overTotalSupply()) {
            IBread(erc20Address).authorisedMint(msg.sender, reward);
            emit RewardClaim(msg.sender, reward);
        }
    }

    /**
     * Deposit a Duck into the contract
     */
    function deposit(uint256[] calldata tokenIds) external {
        require(msg.sender != erc721Address, "Invalid address");
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
        emit Deposit(msg.sender, tokenIds);
    }

    /**
     * Withdraw a Duck from the contract
     */
    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Token not deposited"
            );
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
        emit Withdraw(msg.sender, tokenIds);
    }

    /**
     * Level up your Duck!
     */
    function levelUp(uint256[] calldata tokenIds) external {
        uint256 totalCost;

        for (uint256 i; i < tokenIds.length; i++) {
            // going to need to have spent a lot of bread to even attempt an overflow
            unchecked {
                totalCost += (level[tokenIds[i]] + 1) * levelUpCostPerLevel;
            }
        }

        IERC20(erc20Address).transferFrom(msg.sender, address(this), totalCost);

        for (uint256 i; i < tokenIds.length; i++) {
            unchecked {
                level[tokenIds[i]] += 1;
            }
        }
    }

    /**
     * Allows contract owner to set the level up cost (in $BREAD - wei amount)
     */
    function setLevelUpCost(uint256 _newCost) external onlyOwner {
        levelUpCostPerLevel = _newCost;
    }

    /**
     * Allows contract owner to withdraw the $BREAD from the contract
     */
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
        IERC20(erc20Address).transfer(msg.sender, tokenSupply);
    }

    /**
     * Allows contract owner to modify the ERC20 token
     */
    function setErc20Address(address _tokenAddress) external onlyOwner {
        erc20Address = _tokenAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
