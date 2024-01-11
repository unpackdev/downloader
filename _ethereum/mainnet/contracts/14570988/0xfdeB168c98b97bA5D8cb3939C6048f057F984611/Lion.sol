// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract Lion is ERC20, Ownable {
    using SafeMath for uint;

    // Seconds amount in one day
    uint private constant SECONDS_IN_A_DAY = 86400;

    // Maximum token supply
    uint public constant MAX_TOKEN_SUPPLY = 30 * (10 ** 6) * (10 ** 18);

    // Maximum Team token supply
    uint public constant MAX_TEAM_SUPPLY = 6 * (10 ** 6) * (10 ** 18);

    // Maximum Airdrops token supply
    uint public constant MAX_AIRDROPS_SUPPLY = 9 * (10 ** 6) * (10 ** 18);

    // Maximum Future community contributions token supply
    uint public constant MAX_FUTURE_COMUNITY_CONTRIBUTIONS_SUPPLY = 3 * (10 ** 6) * (10 ** 18);

    // Maximum Tresury token supply
    uint public constant MAX_TRESURY_SUPPLY = 9 * (10 ** 6) * (10 ** 18);

    // Maximum Staking token supply
    uint public constant MAX_STAKING_SUPPLY = 3 * (10 ** 6) * (10 ** 18);

    // Amount of token staking per one day
    uint public constant STAKING_PER_DAY = 0.30080435 * (10 ** 18);

    uint private _totalTeamSupply;

    uint private _totalAirdropsSupply;

    uint private _totalFutureCommunityContributionsSupply;

    uint private _totalTresurySupply;

    uint private _totalStakingSupply;

    // Staking start date
    uint private _stakingStart;

    // Airdrop end date
    uint public _airDropEndTimestamp;

    address private _nftAddress;

    // SE token indices
    mapping (uint => bool) public SE_TOKENS;

    mapping(uint => uint) private _lastClaim;

    mapping(address => bool) public _airdropClaimed;

    bytes32 public _merkleRoot;

    event StartStaking(uint _date);

    constructor() ERC20("$LION Token", "$LION") {
        uint16[36] memory seTokens = [
            1321, 3660, 6359, 3236, 7902, 8960, 7380, 7512, 8865, 1767, 4183, 5655, 402,
            3091, 8752, 2186, 6390, 5954, 2892, 8840, 2008, 4146, 484, 5448, 8379, 94,
            1799, 1641, 3026, 3198, 1988, 6500, 6584, 8409, 5988, 6257
        ];

        for (uint i = 0; i < seTokens.length; i++) {
            SE_TOKENS[seTokens[i]] = true;
        }

        _airDropEndTimestamp = block.timestamp + 1 * 365 * SECONDS_IN_A_DAY;
    }

    /**
     * @dev Function set the merkel root
     *
     * @param merkleRoot ERC20s amount to mint
    */
    function setMerkelRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    /**
     * @dev Function mints the amount of Team ERC20s and sends them to the address
     *
     * @param to address where to mint the ERC20s
     *
     * @param amount ERC20s amount to mint
    */
    function mintTeam(address to, uint amount) external onlyOwner {
        require(_totalTeamSupply + amount <= MAX_TEAM_SUPPLY, "Team token amount is exceeded");

        _mint(to, amount);

        _totalTeamSupply += amount;
    }

    /**
     * @dev Function mints the amount of Future community contributions ERC20s and sends them to the address
     *
     * @param to address where to mint the ERC20s
     *
     * @param amount ERC20s amount to mint
    */
    function mintFutureCommunityContributions(address to, uint amount) external onlyOwner {
        require(_totalFutureCommunityContributionsSupply + amount <= MAX_FUTURE_COMUNITY_CONTRIBUTIONS_SUPPLY, "Future community contributions token amount is exceeded");

        _mint(to, amount);

        _totalFutureCommunityContributionsSupply += amount;
    }

    /**
     * @dev Function mints the amount of Tresury ERC20s and sends them to the address
     *
     * @param to address where to mint the ERC20s
     *
     * @param amount ERC20s amount to mint
    */
    function mintTresury(address to, uint amount) external onlyOwner {
        require(_totalTresurySupply + amount <= MAX_TRESURY_SUPPLY, "Tresury token amount is exceeded");

        _mint(to, amount);

        _totalTresurySupply += amount;
    }

    /**
     * @dev function to get the last reward claim timesamp
     *
     * @param tokenIndex index of the token to get the last reward claim timesamp
    */
    function lastClaim(uint tokenIndex) public view returns (uint) {
        require(_nftAddress != address(0), "Token contract does not exist");
        require(tokenIndex < IERC721Enumerable(_nftAddress).totalSupply(), "Token is not minted");
        require(IERC721(_nftAddress).ownerOf(tokenIndex) != address(0), "Token has no owner or does not exist");

        return _lastClaim[tokenIndex] != 0 ? _lastClaim[tokenIndex] : _stakingStart;
    }

    /**
     * @dev function to accumulate the reward of token holding by token index
     *
     * @param tokenIndex index of the token to accumulate the reward
    */
    function accumulated(uint tokenIndex) public view returns (uint) {
        require(_nftAddress != address(0), "Token contract does not exist");
        require(block.timestamp > _stakingStart, "Staking has not started");
        require(tokenIndex < IERC721Enumerable(_nftAddress).totalSupply(), "NFT is not minted");
        require(IERC721(_nftAddress).ownerOf(tokenIndex) != address(0), "NFT has no owner or does not exist");

        uint lastClaimed = lastClaim(tokenIndex);

        if (lastClaimed >= stakingEndTimestamp()) return 0;

        uint accumulationPeriod = block.timestamp < stakingEndTimestamp() ? block.timestamp : stakingEndTimestamp();
        uint totalAccumulated = accumulationPeriod.sub(lastClaimed).div(SECONDS_IN_A_DAY).mul(STAKING_PER_DAY);

        if (SE_TOKENS[tokenIndex]) {
            totalAccumulated = totalAccumulated.mul(4);
        }

        return totalAccumulated;
    }

    /**
     * @dev function to set the address for NFT contract
     *
     * @param nftAddress address of the nft contract
    */
    function setNftAddress(address nftAddress) external onlyOwner {
        require(nftAddress != address(0), "Nft contract address is not valid");

        _nftAddress = nftAddress;
    }

    /**
     * @dev function starts the staking
    */
    function startStaking() external onlyOwner {
        require(_stakingStart == 0, "Staking already started");

        _stakingStart = block.timestamp;

        emit StartStaking(block.timestamp);
    }

    /**
     * @dev function to get the end staking time
     *
     * @return end staking timestamp
    */
    function stakingEndTimestamp() public view  returns (uint) {
        require(_stakingStart != 0, "Staking is not started yet");

        return _stakingStart + 3 * 365 * SECONDS_IN_A_DAY;
    }

    /**
     * @dev function to claim the reward for tokens holding
     *
     * @param tokenIndices array of token indices to claim the reward
    */
    function claim(uint[] memory tokenIndices) external {
        require(block.timestamp > _stakingStart, "Staking has not started yet");

        uint totalClaimAmount = 0;

        for (uint i = 0; i < tokenIndices.length; i++) {
            uint tokenIndex = tokenIndices[i];

            require(_nftAddress != address(0), "Token contract does not exist");
            require(tokenIndex < IERC721Enumerable(_nftAddress).totalSupply(), "NFT is not minted");
            require(IERC721(_nftAddress).ownerOf(tokenIndex) == _msgSender(), "Sender is not the owner");

            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndex != tokenIndices[j], "Duplicate token index");
            }

            uint claimAmount = accumulated(tokenIndex);

            if (claimAmount != 0) {
                require(_totalStakingSupply + claimAmount <= MAX_STAKING_SUPPLY, "Staking token amount is exceeded");

                totalClaimAmount = totalClaimAmount.add(claimAmount);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimAmount != 0, "No reward accumulated");

        _mint(_msgSender(), totalClaimAmount);

        _totalStakingSupply += totalClaimAmount;
    }

    /**
     * @dev Function mints the amount of not minted ERC20s airdrop after the airdrop ended
     *
     * @param to address where to mint the ERC20s
     *
     * @param amount ERC20s amount to mint
    */
    function mintUnclaimedAridrop(address to, uint amount) external onlyOwner {
        require(block.timestamp > _airDropEndTimestamp, "Airdrop not ended");
        require(_totalAirdropsSupply + amount <= MAX_AIRDROPS_SUPPLY, "Airdrop supply amount is exceeded");

        _mint(to, amount);

        _totalAirdropsSupply += amount;
    }

    /**
     * @dev Function mints the airdrop by checking the elegibility of address and amount using Markel Proof
     *
     * @param to address where to mint the ERC20s
     *
     * @param amount ERC20s amount to mint
     *
     * @param proof merkel proof
    */
    function airdropClaim(address to, uint256 amount, bytes32[] calldata proof) external {
        require(block.timestamp < _airDropEndTimestamp, "Airdrop ended");
        require(_totalAirdropsSupply + amount <= MAX_AIRDROPS_SUPPLY, "Airdrops token amount is exceeded");
        require(_merkleRoot != 0, "Merkel root not set. No whitelisted addresses. ");
        require(!_airdropClaimed[to], "Already claimed");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, _merkleRoot, leaf);
        require(isValidLeaf, "Address not in the whitelist");

        // Set address to claimed
        _airdropClaimed[to] = true;

        // Mint tokens to address
        _mint(to, amount);

        _totalAirdropsSupply += amount;
    }

}
