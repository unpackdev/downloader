// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./StakingDaoTokenLock.sol";

/**
 * @dev StakingDao ERC20 token.
 */
contract StakingDaoToken is ERC20, Ownable {
    using SafeMath for uint256;

    bytes32 constant public merkleRoot = 0x26f919154dd86a71099a71a20293430da6264dbf2da2f9cdea575c7abdde0e1d;

    mapping(address => bool) private claimed;

    event Claimed(address indexed claimant, uint256 amount);
    event Swept(uint256 amount);

    // total supply 1 trillion, 50% airdrop, 5% contributor vested, remainder to timelock, 20% dao fund, %15 staking incentive, 10% lp incentive
    uint256 constant MAX_SUPPLY = 1_000_000_000_000e18;

    uint256 constant airdropSupply = MAX_SUPPLY / 100 * 50;
    uint256 constant devSupply = MAX_SUPPLY / 100 * 5;
    uint256 constant daoSupply = MAX_SUPPLY / 100 * 20;
    uint256 constant lpIncentiveSupply = MAX_SUPPLY / 100 * 10;
    uint256 constant stakingIncentiveSupply = MAX_SUPPLY / 100 * 15;

    address constant StakingIncentive = 0xDc0529435D4aC1EFfFD963c765A271D01E3d5F24;
    address constant Dao = 0x71036fDE24af5ae3FaaB43E8B5d3C097EDD6041d;
    address constant LpIncentive = 0x5C67064893AD521E5aEC6bfbA9E8C5A50719aE23;
    

    bool public vestStarted = false;

    uint256 public constant claimPeriodEnds = 1657454400; // 7 10, 2022

    /**
     * @dev Constructor.
     */
    constructor(
    )
        ERC20("Staking DAO", "POS")
    {
        _mint(address(this), airdropSupply);
        _mint(address(this), devSupply);
        _mint(StakingIncentive, stakingIncentiveSupply);
        _mint(Dao, daoSupply);
        _mint(LpIncentive, lpIncentiveSupply);
    }

    function startVest(address tokenLockAddress) external onlyOwner {
        require(!vestStarted, "Staking Dao: Vest has already started.");
        vestStarted = true;
        _approve(address(this), tokenLockAddress, devSupply);

        StakingDaoTokenLock(tokenLockAddress).lock(0x691Fb594F725C867dABaFE28A795aCf7e351CCAd, MAX_SUPPLY / 10000 * 200);

        StakingDaoTokenLock(tokenLockAddress).lock(0x9BbF760e37177b69BCADF21894C7b282B2D90eD3, MAX_SUPPLY / 10000 * 30);
        StakingDaoTokenLock(tokenLockAddress).lock(0x746a6b9191dDbaAFeF4BB7Fb869B2f85291Ade1d, MAX_SUPPLY / 10000 * 20);
        StakingDaoTokenLock(tokenLockAddress).lock(0x2B13D7a6A6ABEd16Bf041af6970d7bfbAEf89AE5, MAX_SUPPLY / 10000 * 20);
        StakingDaoTokenLock(tokenLockAddress).lock(0xBD1b1657D66021Ee8C88dC78D4516C0195FFe9f3, MAX_SUPPLY / 10000 * 20);
        StakingDaoTokenLock(tokenLockAddress).lock(0x13868175781F63556Cd2C8cC4A3690843772c2C7, MAX_SUPPLY / 10000 * 20);
        StakingDaoTokenLock(tokenLockAddress).lock(0xF08047571D2eB1635CCDeDBf3d656ec0631adD15, MAX_SUPPLY / 10000 * 20);
        StakingDaoTokenLock(tokenLockAddress).lock(0x903175c3Ea356D06dC31bc59D27947429a5A6dd5, MAX_SUPPLY / 10000 * 15);

        StakingDaoTokenLock(tokenLockAddress).lock(0x17Ca77Ec9DC0234EeD9A58E2F05E3C163C3Ab176, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0xaa24328f08943Af467B5c61C31Fdc321a6F5Fb99, MAX_SUPPLY / 10000 * 5);
        StakingDaoTokenLock(tokenLockAddress).lock(0xd6D69d14a783E3573Eda6572df9C3EE830563218, MAX_SUPPLY / 10000 * 5);
        StakingDaoTokenLock(tokenLockAddress).lock(0xe042f1C8535481dD1A9702dea692De247b6d8d73, MAX_SUPPLY / 10000 * 5);
        StakingDaoTokenLock(tokenLockAddress).lock(0x166499514963cB44A414108d6F8572756f8B06A9, MAX_SUPPLY / 10000 * 5);

        StakingDaoTokenLock(tokenLockAddress).lock(0xf189Ccd5FFACb1815d3935eC9DFd1d76398FBB41, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x6557386307161330db42a27fFC190784c29cf503, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0xc28a35B5F2BFDDc6cB1623a0552A333f283cfdE5, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x98199e7107451473e5aF629E585Cd20e5F2a75C0, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x2d48c6432CC4000A55de200341a8E65a1cAfa400, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x87416fF791A8379FE7DE960831BEe3352b4dbb0D, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0xB9B691A11b641d3900f067448468aBc2Eb81eb8e, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x81ecE5B8e7C464Aa5C6297ef05aE1d9eeBe59627, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0xC3498F4Aa663422a403c0543049f7e725c775b2A, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x6BC757849658C8724ea165d74a6DAADb8fFD51dd, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0xf0af9b380F35a98FCE68C62C1ae5B4d2aC4d8eE1, MAX_SUPPLY / 10000 * 10);
        StakingDaoTokenLock(tokenLockAddress).lock(0x42E5566F2C79Df8815FEb7C3Afe06B2741C196cA, MAX_SUPPLY / 10000 * 5);
        StakingDaoTokenLock(tokenLockAddress).lock(0x3aBD421B0eF3a462CdB9A4D51b9E45D282bc2F80, MAX_SUPPLY / 10000 * 10);
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Staking Dao: Valid proof required.");
        require(!claimed[msg.sender], "Staking Dao: Tokens already claimed.");
        claimed[msg.sender] = true;

        _transfer(address(this), msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /**
     * @dev Allows anyone to sweep unclaimed tokens after the claim period ends to DAO fund.
     */
    function sweep() external {
        require(block.timestamp > claimPeriodEnds, "Staking Dao: Claim period not yet ended");
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No balance to sweep");
        _transfer(address(this), Dao, balance);

        emit Swept(balance);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(address account) public view returns (bool) {
        return claimed[account];
    }
}