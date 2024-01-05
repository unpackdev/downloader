//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IVesting.sol";
import "./IAirdrop.sol";

contract VestingAirdrop is Ownable, IAirdrop {
    IERC20 public token;
    
    bytes32 public root;
    IVesting public vesting;
    uint256 public vestingAmount;
    uint256 public vestingDuration;
    uint256 public vestingCliff;

    mapping (address => bool) public claimed;

    event Claim(address _recipient, uint256 amount);

    constructor(
        address _token,
        address _owner,
        bytes32 _root,
        address _vesting,
        uint256 _vestingAmount,
        uint256 _vestingCliff,
        uint256 _vestingDuration)
    public {
        token = IERC20(_token);
        root = _root;
        vesting = IVesting(_vesting);
        vestingAmount = _vestingAmount;
        vestingCliff = _vestingCliff;
        vestingDuration = _vestingDuration;
        transferOwnership(_owner);
    }

    /**
     * @notice Modifies the underlying set for the Merkle tree. It is an error
     *          to call this function with an incorrect size or root hash.
     * @param _root The new Merkle root hash
     * @dev Only the owner of the contract can modify the Merkle set.
     *
     */
    function setMerkleSet(
        bytes32 _root
    ) external override onlyOwner() {
        root = _root;
    }

    /**
     * @notice Deposits tokens into the airdrop contract
     * @param amount The quantity of ERC20 tokens to deposit
     *
     */
    function deposit(uint256 amount) external override {
        /* bounds check deposit amount */
        require(amount > 0, "ADP: Zero deposit");

        /* transfer tokens to airdrop contract */
        bool transferResult = token.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        /* handle failure */
        require(transferResult, "ADP: ERC20 transfer failed");
    }

    /**
     * @notice Withdraws the allocated quantity of tokens to the caller
     * @param proof The proof of membership of the Merkle tree
     * @param amount The number of tokens the caller is claiming
     * @dev Marks caller as claimed if proof checking succeeds and emits the
     *      `Claim` event.
     *
     */
    function withdraw(
        bytes32[] calldata proof,
        uint256 amount
    ) external override {
        /* check for multiple claims */
        require(!claimed[msg.sender], "ADP: Already claimed");

        /* check the caller's Merkle proof */
        bool proofResult = checkProof(proof, hash(msg.sender, amount));

        /* handle proof checking failure */
        require(proofResult, "ADP: Invalid proof");

        /* mark caller as claimed */
        claimed[msg.sender] = true;

        /* transfer tokens from airdrop contract to caller */
        bool transferResult = token.transfer(msg.sender, amount);

        /* handle failure */
        require(transferResult, "ADP: ERC20 transfer failed");

        /* Send tokens to vesting */
        token.transfer(address(vesting), vestingAmount);

        /* Set vesting for the user */
        vesting.setVestingSchedule(
            msg.sender,
            vestingAmount,
            false,
            vestingCliff,
            vestingDuration
        );

        /* emit appropriate event */
        emit Claim(msg.sender, amount);
    }

    /**
     * @notice Withdraws all tokens currently held by the airdrop contract
     * @dev Only the owner of the airdrop contract can call this method
     *
     */
    function bail() external override onlyOwner() {
        /* retrieve current token balance of the airdrop contract */
        uint256 tokenBalance = token.balanceOf(address(this));

        /* transfer all tokens in the airdrop contract to the owner */
        bool transferResult = token.transfer(msg.sender, tokenBalance);

        require(transferResult, "ADP: ERC20 transfer failed");
    }

    function cancelVestingSchedule(address account, uint256 scheduleId) external onlyOwner() {
        vesting.cancelVesting(account, scheduleId);
    }

    function withdrawFromVesting(uint256 amount) external onlyOwner() {
        vesting.withdraw(amount);
    }

    /**
    * @notice helper function for anyone to validate if a given proof is valid given a claimer and amount 
    */
    function validClaim(bytes32[] calldata proof, address claimer, uint amount) public view returns(bool) {
        return checkProof(proof, hash(claimer, amount));
    }

    /**
     * @notice Verifies a membership proof using another leaf node of the Merkle
     *          tree
     * @param proof The Merkle hash of the relevant data block
     * @param claimantHash The Merkle hash the caller is looking to prove is a
     *          member of the Merkle set
     *
     */
    function checkProof(
        bytes32[] calldata proof,
        bytes32 claimantHash
    ) internal view returns (bool) {
        bytes32 currElem = 0;
        bytes32 currHash = claimantHash;

        for(uint256 i=0;i<proof.length;i++) {
            currElem = proof[i];

            /* alternate what order we concatenate in */
            if (currElem < currHash) {
                currHash = keccak256(abi.encodePacked(currHash, currElem));
            } else {
                currHash = keccak256(abi.encodePacked(currElem, currHash));
            }
        }
        
        return currHash == root;
    }

    function logBase2(uint256 n) internal pure returns (uint256) {
        uint256 res = 0;

        if (n >= 2**128) { n >>= 128; res += 128; }
        if (n >= 2**64) { n >>= 64; res += 64; }
        if (n >= 2**32) { n >>= 32; res += 32; }
        if (n >= 2**16) { n >>= 16; res += 16; }
        if (n >= 2**8) { n >>= 8; res += 8; }
        if (n >= 2**4) { n >>= 4; res += 4; }
        if (n >= 2**2) { n >>= 2; res += 2; }
        if (n >= 2**1) { /* n >>= 1; */ res += 1; }

        return res;
    }

    /**
     * @notice Generates the Merkle hash given address and amount
     * @param recipient The address of the recipient
     * @param amount The quantity of tokens the recipient is entitled to
     * @return The Merkle hash of the leaf node needed to prove membership
     *
     */
    function hash(
        address recipient,
        uint256 amount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient, amount));
    }
}

