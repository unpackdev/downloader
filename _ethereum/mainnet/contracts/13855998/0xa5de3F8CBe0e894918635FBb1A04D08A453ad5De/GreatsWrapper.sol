pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract GreatsWrapper is Ownable, ReentrancyGuard, IERC721Receiver {

    // Constants
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant ELIGIBLE_FOR_CLAIM = 353;
    uint256 public constant FREE_CLAIMS_PER_ORIGINAL = 4;
    uint256 public constant MAX_REDEMPTION_NUMBER = 200;
    uint256 public constant PRICE = 6 * (10 ** 17);
    address public immutable WALLET;
    address public immutable GREATS;

    // Public Variables
    uint256 public redemptionNumber;
    uint256 public claimedMints;
    uint256 public paidMints; // Includes bonus mints as well

    mapping(uint256 => bool) public claimed;
    mapping(uint256 => bool) public isRedeemedAlready;

    // Events

    event Mint(address minter, uint256 tokenId);
    event Redemption(address initiator, uint256 burntTokenId, uint256 newTokenId);

    constructor(address _greats, address _wallet) {
        GREATS = _greats;
        WALLET = _wallet;
    }

    // External Functions

    /**
     * @notice Mint a Greats NFT either by paying 'PRICE' Ether or free if the sender owns a token ID part of the claim allowance 
     * @dev Uses block variables as a source of randomness (Although theoretically gameable, chosen as a pragmatic solution given the economic incentives)
     */
    function mint(uint256 originalTokenNumber, uint256 numberToMint) external payable nonReentrant {
        require(msg.sender == tx.origin, "Minter cannot be a contract");

        if (originalTokenNumber == 9999) {
            require(numberToMint > 0 && numberToMint <= 20, "Cannot mint 0 and cannot mint more than 20 at once");
            require(msg.value == PRICE * numberToMint, "Send the correct price amount");

            paidMints += numberToMint;
        } else {
            require(!claimed[originalTokenNumber], "Already claimed");
            require(IERC721Enumerable(GREATS).ownerOf(originalTokenNumber) == msg.sender, "Not the owner");
            require(numberToMint == FREE_CLAIMS_PER_ORIGINAL, "All 4 must be claimed at once");
            require(originalTokenNumber < 335 || (originalTokenNumber > 4589 && originalTokenNumber < 4608), "Ineligible token ID");
            
            claimedMints++;
            claimed[originalTokenNumber] = true;
        }

        for (uint256 i = 0; i < numberToMint; i++) {
            uint256 seed = uint256(
                keccak256(abi.encodePacked(
                    msg.sender, block.number, block.difficulty, block.timestamp, paidMints, claimedMints, i
                ))
            );

            _mint(msg.sender, seed);

            if (originalTokenNumber == 9999 && _doesGetBonusMint(seed)) {
                _mint(msg.sender, seed);
                paidMints++;
            } 
        }
    }

    /**
     * @notice Reroll function
     * @dev Prevents a token obtained through reroll to not be rerolled again to avoid potential spamming
    */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory) external override nonReentrant returns(bytes4) {
        require(from == tx.origin && operator == from, "Minter cannot be a contract");

        require(redemptionNumber < MAX_REDEMPTION_NUMBER, "Redemption period ended");
        require(!isRedeemedAlready[tokenId], "Token ID already redeemed");

        redemptionNumber++;
        IERC721Enumerable(GREATS).transferFrom(address(this), DEAD_ADDRESS, tokenId);
        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, block.number, block.difficulty, block.timestamp, redemptionNumber)));
        uint256 transferredTokenId = _mint(from, seed);
        isRedeemedAlready[transferredTokenId] = true;

        emit Redemption(from, tokenId, transferredTokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Withdraw Ether from the contract (Callable by the owner)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    // Internal Functions

    /**
     * @dev Transfers a random token ID from 'WALLET' address to 'to' address
     * Returns the token ID that has been transferred
    */
    function _mint(address to, uint256 seed) internal returns (uint256) {
        uint256 balance = IERC721Enumerable(GREATS).balanceOf(WALLET);

        require(balance > 0, "The minting wallet does not have enough balance");

        uint256 tokenIndexInEnumerable = seed % balance;
        uint256 tokenId = IERC721Enumerable(GREATS).tokenOfOwnerByIndex(WALLET, tokenIndexInEnumerable);

        IERC721Enumerable(GREATS).transferFrom(WALLET, to, tokenId);
        require((ELIGIBLE_FOR_CLAIM - claimedMints) * FREE_CLAIMS_PER_ORIGINAL <= balance, "Exceeded");

        emit Mint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Given a seed, checks if a bonus mint is endowed based on tier based probabilities
     * 30%, 20% and 10% chances for a bonus mint on each paid mint until 100, 200 and 300 paid mints respectively
    */
    function _doesGetBonusMint(uint256 seed) internal view returns (bool) {
        uint256 roll = seed % 10;

        uint256 odds = 0;
        if (paidMints < 100) {
            odds = 3;
        } else if (paidMints < 200) {
            odds = 2;
        } else if (paidMints < 300) {
            odds = 1;
        }
        return roll < odds;
    }
}
