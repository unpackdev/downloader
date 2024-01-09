// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./IERC20.sol";

/**
 * @dev An ERC20 token for MetaTreeDAO.
 */
contract MetaTreeDAOToken is ERC20, ERC20Permit, Ownable {

    IERC20 public immutable usdtToken;
    IERC20 public immutable usdcToken;
    IERC20 public immutable daiToken;
    address public yearToken;
    address public sosToken;

    struct Proposal {
        uint256 id;
        address excutor;
        uint256 amount;
    }

    mapping(address=>bool) public claimed;
    mapping(address=>bool) public treasurySigners;
    uint256 public treasurySignerCount;
    mapping(address=>bool) public stakingSigners;
    uint256 public stakingSignerCount;

    mapping(uint256=>Proposal) public treasuryProposals;
    mapping(uint256=>Proposal) public stakingProposals;
    uint256 public treasuryProposalId;
    uint256 public stakingProposalId;

    mapping(uint256 => mapping(address => bool)) public treasuryProposalSigner;
    mapping(uint256 => uint256) public treasuryProposalExcutes;

    mapping(uint256 => mapping(address => bool)) public stakingProposalSigner;
    mapping(uint256 => uint256) public stakingProposalExcutes;

    event Claim(address indexed claimant, uint256 amount);

    // total supply 1 trillion, 50% airdrop, 20% LP, 20% DAO treasury, 10% Staking Incentive
    uint256 constant airdropSupply = 500_000_000_000e18;
    uint256 airdropSum;
    uint256 constant lpSupply = 200_000_000_000e18;
    uint256 constant treasurySupply = 200_000_000_000e18;
    uint256 treasurySum;
    uint256 constant stakingSupply = 1_000_000_000_000e18 - airdropSupply - lpSupply - treasurySupply;
    uint256 stakingSum;



    /**
     * @dev Constructor.
     */
    constructor(
        address lpAddress,
        address usdt,
        address usdc,
        address dai
        // address year,
        // address sos
    )
        ERC20("MetaTreeDAO", "TREE")
        ERC20Permit("MetaTreeDAO")
    {
        _mint(address(this), airdropSupply);
        _mint(address(this), treasurySupply);
        _mint(address(this), stakingSupply);
        _mint(lpAddress, lpSupply);
        usdtToken = IERC20(usdt);
        usdcToken = IERC20(usdc);
        daiToken = IERC20(dai);
        // yearToken = IERC20(year);
        // sosToken = IERC20(sos);
        
    }


    /**
     * @dev Claims airdropped tokens.
     */
    function claimTokens() public {
        bool canClaim = (msg.sender.balance >= 0.5e18) || (usdtToken.balanceOf(msg.sender) + usdcToken.balanceOf(msg.sender) + daiToken.balanceOf(msg.sender)) >= 1550e18;
        bool helpOther = false;
        if (yearToken != address(0) && sosToken != address(0)) {
            helpOther = (msg.sender.balance >= 0.1e18) && ((IERC20(yearToken).balanceOf(msg.sender) > 0) || (IERC20(sosToken).balanceOf(msg.sender) > 0));
        }
        require(canClaim || helpOther, "you can not claim airdrop.");
        require(!claimed[msg.sender], "MetaTreeDAOToken: Tokens already claimed.");
        claimed[msg.sender] = true;
        uint256 amount = uint256(uint160(msg.sender)) % 6 * 2_000_000e18;
        require(airdropSupply > (airdropSum + amount), "airdropSupply don't have enough tokens");
        airdropSum += amount;
        emit Claim(msg.sender, amount);
        _transfer(address(this), msg.sender, amount);
    }

    function setOtherCliamToken(address year, address sos) public onlyOwner {
        if (yearToken == address(0) && sosToken == address(0)) {
            yearToken = year;
            sosToken = sos;
        }
    }

    function addTreasurySigner(address signer) public onlyOwner {
        require(!treasurySigners[signer], "you are already treasurySigner");
        treasurySigners[signer] = true;
        treasurySignerCount++;
    }

    function addStakingSigner(address signer) public onlyOwner {
        require(!stakingSigners[signer], "you are already treasurySigner");
        stakingSigners[signer] = true;
        stakingSignerCount++;
    }

    function executeTreasury(uint256 proposalId) public {
        require(treasurySigners[msg.sender], "you are not treasurySigner");
        require(!treasuryProposalSigner[proposalId][msg.sender], "you have excuted this proposal");
        require(treasurySupply >= (treasurySum + treasuryProposals[proposalId].amount), "DAO treasury do not have enough token");
        require(proposalId <= treasuryProposalId, "proposal is null");
        treasuryProposalSigner[proposalId][msg.sender] = true;
        treasuryProposalExcutes[proposalId]++;
        if (treasurySignerCount >= 5 && (treasurySignerCount - treasuryProposalExcutes[proposalId] < 3)) {
            _transfer(address(this), treasuryProposals[proposalId].excutor, treasuryProposals[proposalId].amount);
            treasurySum += treasuryProposals[proposalId].amount;
        }

    }

    function addTreasuryProposal(address excutor, uint256 amount) public {
        require(treasurySigners[msg.sender], "you are not treasurySigner");
        treasuryProposalId++;
        treasuryProposals[treasuryProposalId] = Proposal(treasuryProposalId, excutor, amount);
    }

    function executeStaking(uint256 proposalId) public {
        require(stakingSigners[msg.sender], "you are not stakingSigner");
        require(!stakingProposalSigner[proposalId][msg.sender], "you have excuted this proposal");
        require(stakingSupply >= (stakingSum + stakingProposals[proposalId].amount), "Staking do not have enough token");
        require(proposalId <= stakingProposalId, "proposal is null");
        stakingProposalSigner[proposalId][msg.sender] = true;
        stakingProposalExcutes[proposalId]++;
        if (stakingSignerCount >= 5 && (stakingSignerCount - stakingProposalExcutes[proposalId] < 3)) {
            _transfer(address(this), stakingProposals[proposalId].excutor, stakingProposals[proposalId].amount);
            stakingSum += stakingProposals[proposalId].amount;
        }

    }

    function addStakingProposal(address excutor, uint256 amount) public {
        require(stakingSigners[msg.sender], "you are not stakingSigner");
        stakingProposalId++;
        stakingProposals[stakingProposalId] = Proposal(stakingProposalId, excutor, amount);
    }

}
