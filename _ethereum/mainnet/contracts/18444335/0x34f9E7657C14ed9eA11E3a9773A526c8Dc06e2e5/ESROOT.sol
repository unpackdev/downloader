// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ROOT.sol";
import "./ISmartWalletWhitelist.sol";

/**
 * @title esROOT
 * @author
 * @notice This contract enables the minting, vesting and redemption of esROOT tokens
 */
contract ESROOT is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ROOT public root;

    mapping(address => bool) public isMinter;

    mapping(address => bool) public isSender;

    /** @notice Refers to bps of total esROOT can be redeemed for ROOT */
    uint256 public instantRedemptionBP;

    /** @notice Refers to the vesting period in seconds */
    uint256 public vestPeriod;

    uint256 constant DENOMINATOR = 10000;

    /**
     * @notice Vesting struct for a given instance of user vesting amount ROOT tokens
     * @param vestor
     * @param amount
     * @param start
     */
    struct Vesting {
        uint256 total;
        uint256 claimed;
        uint256 start;
    }

    event VestingCreated(address indexed vestor, uint256 amount, uint256 start);

    event InstantRedemption(address indexed redeemer, uint256 amount);

    event VestingClaimed(address indexed claimant, uint256 amount);

    event MinterStatusSet(address indexed minter, bool status);

    event SenderStatusSet(address indexed sender, bool status);

    event ROOTMigration(address newROOT);

    /** @notice Vestings owned by a given address */
    mapping(address => Vesting[]) public vestings;

    /** @notice Lowest unvested index for a given address */
    mapping(address => uint256) public lowestUnvestedIndex;
    address public smartWalletChecker;

    /**
     * @notice constructor for esROOT
     * @param root_ Address of the ROOT token
     * @param instantRedemptionBP_ Basis point of total ROOT that can be redeemed instantly for esROOT
     * @param vestingPeriod_ Vesting period in seconds
     */
    constructor(
        address root_,
        uint256 instantRedemptionBP_,
        uint256 vestingPeriod_,
        address smartWalletChecker_
    ) ERC20("esROOT", "esROOT") {
        require(address(root_) != address(0), "Zero Address");
        require(address(smartWalletChecker_) != address(0), "Zero Address");
        root = ROOT(root_);
        instantRedemptionBP = instantRedemptionBP_;
        vestPeriod = vestingPeriod_;
        smartWalletChecker = smartWalletChecker_;
    }

    modifier onlyWhitelisted() {
        if (tx.origin != msg.sender) {
            require(
                address(smartWalletChecker) != address(0),
                "Not whitelisted"
            );
            require(
                ISmartWalletWhitelist(smartWalletChecker).check(msg.sender),
                "Not whitelisted"
            );
        }
        _;
    }

    function setSmartWalletChecker(address _checker) public onlyOwner {
        require(address(_checker) != address(0), "Zero Address");
        smartWalletChecker = _checker;
    }

    /**
     * @notice Mints esROOT tokens to the specified address
     * @param to The address to mint to
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external {
        //only allows if msg.sender is a minter
        require(isMinter[msg.sender], "esROOT: not minter");
        _mint(to, amount);
        //amount of ROOT tokens must be transferred to this contract for future redemption
        root.mint(address(this), amount);
    }

    /**
     * @notice Overrides the transfer function to only allow transfers from senders
     * @param sender token sender
     * @param recipient token recipient
     * @param amount amount of tokens to transfer
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        //Only allows if msg.sender is a sender
        require(isSender[sender], "esROOT: not sender");
        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice Sets the minter status of an address
     * @param minter address to set status of
     * @param status true if minter, false if not
     */
    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
        emit MinterStatusSet(minter, status);
    }

    /**
     * @notice Sets the sender status of an address
     * @param sender address to set status of
     * @param status true if sender, false if not
     */
    function setSender(address sender, bool status) external onlyOwner {
        isSender[sender] = status;
        emit SenderStatusSet(sender, status);
    }

    /**
     * @notice Redeems esROOT tokens for ROOT tokens, at instant redemption rate
     * @param to The address to redeem to
     * @param amount The amount to redeem
     */
    function instantRedemption(
        address to,
        uint256 amount
    ) external nonReentrant onlyWhitelisted {
        //burns the esROOT tokens
        _burn(msg.sender, amount);
        //transfers the instantly redeemable amount of ROOT tokens to the specified address
        uint256 _transferAmount = (amount * instantRedemptionBP) / DENOMINATOR;
        uint256 _burnAmount = amount - _transferAmount;
        IERC20(root).safeTransfer(to, _transferAmount);
        root.burn(_burnAmount);
        emit InstantRedemption(to, _transferAmount);
    }

    /**
     * @notice Enables vesting of esROOT tokens
     * @param to The address to vest to
     * @param amount The amount to vest
     */
    function vest(
        address to,
        uint256 amount
    ) external onlyWhitelisted nonReentrant {
        _burn(msg.sender, amount);
        vestings[to].push(Vesting(amount, 0, block.timestamp));
        emit VestingCreated(to, amount, block.timestamp);
    }

    /**
     * @notice Returns the total amount of esROOT tokens claimable by a given address
     * @param claimant The address to check
     * @return totalClaimable The total amount of ROOT tokens claimable on existing vests
     */
    function claimable(
        address claimant
    ) public view returns (uint256 totalClaimable) {
        for (
            uint256 i = lowestUnvestedIndex[claimant];
            i < vestings[claimant].length;
            i++
        ) {
            if (vestings[claimant][i].claimed == vestings[claimant][i].total)
                continue;
            else if (vestings[claimant][i].start + vestPeriod < block.timestamp)
                totalClaimable +=
                    vestings[claimant][i].total -
                    vestings[claimant][i].claimed;
            else
                totalClaimable +=
                    ((vestings[claimant][i].total *
                        (block.timestamp - vestings[claimant][i].start)) /
                        vestPeriod) -
                    vestings[claimant][i].claimed;
        }
    }

    /**
     * @notice Claims the total amount of esROOT tokens claimable by msg.sender
     */
    function claimVested() external onlyWhitelisted nonReentrant {
        uint256 totalClaimable = 0;
        for (
            uint256 i = lowestUnvestedIndex[msg.sender];
            i < vestings[msg.sender].length;
            i++
        ) {
            // if all tokens have vested, claim all outstanding and increment lowestUnvestedIndex
            if (vestings[msg.sender][i].start + vestPeriod <= block.timestamp) {
                totalClaimable +=
                    vestings[msg.sender][i].total -
                    vestings[msg.sender][i].claimed;
                vestings[msg.sender][i].claimed = vestings[msg.sender][i].total;
                lowestUnvestedIndex[msg.sender] = i + 1;
            } else {
                uint256 vestingClaimable = ((vestings[msg.sender][i].total *
                    (block.timestamp - vestings[msg.sender][i].start)) /
                    vestPeriod);
                totalClaimable +=
                    vestingClaimable -
                    vestings[msg.sender][i].claimed;
                vestings[msg.sender][i].claimed = vestingClaimable;
            }
        }

        IERC20(root).safeTransfer(msg.sender, totalClaimable);
        emit VestingClaimed(msg.sender, totalClaimable);
    }

    /**
     * @notice Returns vesting struct for a given user vest, as individual variables
     * @param claimant The address to check
     * @param index The index of the vesting to check
     * @return total The total amount claimable from this vest at maturation
     * @return claimed The amount already claimed from this vest
     * @return start The timestamp at which this vest started
     */
    function getVesting(
        address claimant,
        uint256 index
    ) external view returns (uint256 total, uint256 claimed, uint256 start) {
        total = vestings[claimant][index].total;
        claimed = vestings[claimant][index].claimed;
        start = vestings[claimant][index].start;
    }

    /**
     * @notice Returns the total number of vestings for a given user
     * @param claimant The address to check
     * @return totalVestings The total number of vestings for this user
     */
    function getTotalUserVestings(
        address claimant
    ) external view returns (uint256 totalVestings) {
        totalVestings = vestings[claimant].length;
    }

    /**
     * @notice Withdraws tokens from the contract
     * @param token address of token to withdraw
     * @param to address to withdraw to
     * @param amount amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Enables upgrade to new ROOT token contract, without disrupting vesting
     * @param root_ address of new ROOT token contract
     */
    function migrateROOT(address root_) external onlyOwner {
        uint256 oldRootBalance = root.balanceOf(address(this));
        root = ROOT(root_);
        uint256 newRootBalance = root.balanceOf(address(this));
        require(newRootBalance >= oldRootBalance, "esROOT: migration failed");
        emit ROOTMigration(root_);
    }
}
