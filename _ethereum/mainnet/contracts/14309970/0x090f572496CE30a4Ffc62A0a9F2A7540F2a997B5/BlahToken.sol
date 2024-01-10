// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $                                                                      $
// $ $$\       $$\           $$\       $$\       $$\           $$\        $
// $ $$ |      $$ |          $$ |      $$ |      $$ |          $$ |       $
// $ $$$$$$$\  $$ | $$$$$$\  $$$$$$$\  $$$$$$$\  $$ | $$$$$$\  $$$$$$$\   $
// $ $$  __$$\ $$ | \____$$\ $$  __$$\ $$  __$$\ $$ | \____$$\ $$  __$$\  $
// $ $$ |  $$ |$$ | $$$$$$$ |$$ |  $$ |$$ |  $$ |$$ | $$$$$$$ |$$ |  $$ | $
// $ $$ |  $$ |$$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |$$  __$$ |$$ |  $$ | $
// $ $$$$$$$  |$$ |\$$$$$$$ |$$ |  $$ |$$$$$$$  |$$ |\$$$$$$$ |$$ |  $$ | $
// $ \_______/ \__| \_______|\__|  \__|\_______/ \__| \_______|\__|  \__| $
// $                                                                      $
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./MerkleProof.sol";

contract BlahToken is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Ownable,
    Pausable,
    ERC20Permit,
    ERC20Votes
{
    bytes32 public immutable merkleRoot =
        0xf8f17d0e2fc3dd421a8c3dbe07c638234b03270e0c6cefbe45424a6e610e71e8;

    mapping(address => bool) public hasClaimed;
    error AlreadyClaimed();
    error NotInMerkle();

    bool public tokenAllocationMade = false;
    bool public isClaimOpen = false;
    uint256 public totalClaimed = 0;

    uint256 public constant MILLION_TOKENS = (10**6) * (10**18);

    // TOTAL SUPPLY = 300 * MILLION_TOKENS
    uint256 public constant AIRDROP_ALLOCATION = 90 * MILLION_TOKENS;
    uint256 public constant NFT_STAKING_ALLOCATION = 45 * MILLION_TOKENS;
    uint256 public constant TOKEN_STAKING_ALLOCATION = 60 * MILLION_TOKENS;
    uint256 public constant LP_INCENTIVE_ALLOCATION = 15 * MILLION_TOKENS;
    uint256 public constant TREASURY_ALLOCATION = 30 * MILLION_TOKENS;
    uint256 public constant NFT_SALE_ALLOCATION = 60 * MILLION_TOKENS;

    bool public nftStakingAllocated = false;
    bool public tokenStakingAllocated = false;
    bool public lpIncentiveAllocated = false;
    bool public treasuryAllocated = false;
    bool public nftSaleAllocated = false;

    mapping(uint256 => uint256) public multiplier;

    event Claim(address indexed to, uint256 amount);

    constructor() ERC20("BlahToken", "BLAH") ERC20Permit("BlahToken") {
        multiplier[200 * (10**18)] = 350 * (10**18);
        multiplier[350 * (10**18)] = 525 * (10**18);
        multiplier[600 * (10**18)] = 810 * (10**18);
        multiplier[900 * (10**18)] = 1125 * (10**18);
        multiplier[1350 * (10**18)] = 1620 * (10**18);
        multiplier[2600 * (10**18)] = 2860 * (10**18);
        multiplier[3400 * (10**18)] = 3740 * (10**18);
        multiplier[5800 * (10**18)] = 5800 * (10**18);
        multiplier[11000 * (10**18)] = 11000 * (10**18);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function allocateNFTStaking(address nftStaking) public onlyOwner {
        require(!nftStakingAllocated);
        _mint(nftStaking, NFT_STAKING_ALLOCATION);
        nftStakingAllocated = true;
    }

    function allocateStaking(address tokenStaking) public onlyOwner {
        require(!tokenStakingAllocated);
        _mint(tokenStaking, TOKEN_STAKING_ALLOCATION);
        tokenStakingAllocated = true;
    }

    function allocateLP(address lpIncentive) public onlyOwner {
        require(!lpIncentiveAllocated);
        _mint(lpIncentive, LP_INCENTIVE_ALLOCATION);
        lpIncentiveAllocated = true;
    }

    function allocateTreasury(address treasury) public onlyOwner {
        require(!treasuryAllocated);
        _mint(treasury, TREASURY_ALLOCATION);
        treasuryAllocated = true;
    }

    function allocateNFTSale(address nftSale) public onlyOwner {
        require(!nftSaleAllocated);
        _mint(nftSale, NFT_SALE_ALLOCATION);
        nftSaleAllocated = true;
    }

    function toggleClaim() public onlyOwner {
        isClaimOpen = !isClaimOpen;
    }

    function allocateUnclaimed(address treasuryAddress) public onlyOwner {
        _mint(treasuryAddress, AIRDROP_ALLOCATION - totalClaimed);
    }

    function getUnclaimed() public view returns (uint256) {
        return (AIRDROP_ALLOCATION - totalClaimed);
    }

    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(isClaimOpen, "Claiming process is not open");
        require(
            totalClaimed + amount <= AIRDROP_ALLOCATION,
            "Requesting more than allocated"
        );

        if (hasClaimed[to]) revert AlreadyClaimed();
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);

        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[to] = true;
        uint256 amountAfterMultplier = multiplier[amount];
        totalClaimed = totalClaimed + amountAfterMultplier;
        _mint(to, amountAfterMultplier);

        emit Claim(to, amountAfterMultplier);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
