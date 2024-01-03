pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath96.sol";
import "./SafeMath32.sol";

// Stake a package from one NFT and some amount of $KINGs to "farm" more $KINGs.
// If $KING airdrops for NFT holders happen, rewards will go to stake holders.
contract RoyalDecks is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeERC20 for IERC20;

    // The $KING amount to return on stake withdrawal is calculated as:
    // `amountDue = Stake.amountStaked * TermSheet.kingFactor/1e+6` (1)

    // On top of amount (1), airdrop $KING rewards may be distributed
    // between NFTs holders. The contract collects airdrops for users.
    // Any time, pended airdrop $KING amount entitled to a stake holder:
    // `airdrop = accAirKingPerNft[nft] - accAirKingBias[stakeId]`  (2)

    struct Stake {
        uint96 amountStaked;   // $KING amount staked on `startTime`
        uint96 amountDue;      // $KING amount due on `unlockTime`
        uint32 startTime;      // UNIX-time the tokens get staked on
        uint32 unlockTime;     // UNIX-time the tokens get locked until
    }

    struct TermSheet {
        bool enabled;          // If staking is enabled
        address nft;           // ERC-721 contract of the NFT to stake
        uint96 minAmount;      // Min $KING amount to stake (with the NFT)
        uint96 kingFactor;     // Multiplier, scaled by 1e+6 (see (1) above)
        uint16 lockHours;      // Staking period in hours
    }

    // All stakes of a user
    struct UserStakes {
        // Set of (unique) stake IDs (see `encodeStakeId` function)
        uint256[] ids;
        // Mapping from stake ID to stake data
        mapping(uint256 => Stake) data;
    }

    bool public emergencyWithdrawEnabled = false;

    // Latest block when airdrops rewards was "collected"
    uint32 lastAirBlock;

    // Amounts in $KING
    uint96 public kingDue;
    uint96 public kingReserves;

    // The $KING token contract
    address public king;

    // Info on each TermSheet
    TermSheet[] internal termSheets;

    // Addresses and "airdrop weights" of NFT contracts (stored as uint256)
    uint256[] internal airPools;
    uint256 constant internal MAX_AIR_POOLS_QTY = 12; // to limit gas

    // Mapping from user account to user stakes
    mapping(address => UserStakes) internal stakes;

    // Mapping from NFT address to accumulated airdrop rewards - see (2) above
    mapping(address => uint256) internal accAirKingPerNft;

    // Mapping from stake ID to "reward bias" for the stake - see (2) above
    mapping(uint256 => uint256) internal accAirKingBias;

    event Deposit(
        address indexed user,
        uint256 stakeId,       // ID of the NFT
        uint256 amountStaked,  // $KING amount staked
        uint256 amountDue,     // $KING amount to be returned
        uint256 unlockTime     // UNIX-time when the stake is unlocked
    );

    event Withdraw(
        address indexed user,
        uint256 stakeId        // ID of the NFT
    );

    event Emergency(bool enabled);
    event EmergencyWithdraw(
        address indexed user,
        uint256 stakeId        // ID of the NFT
    );

    event NewTermSheet(
        uint256 indexed termsId,
        address indexed nft,   // Address of the ERC-721 contract
        uint256 minAmount,     // Min $KING amount to stake
        uint256 lockHours,     // Staking period in hours
        uint256 kingFactor     // See (1) above
    );

    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);

    // $KING added to or removed from stakes repayment reserves
    event Reserved(uint256 amount);
    event Removed(uint256 amount);

    // $KING amount collected as an airdrop reward
    event Airdrop(uint256 amount);

    constructor(address _king) public {
        king = _king;
    }

    // Stake ID uniquely identifies a stake
    // (`stakeHours` excessive for stakes identification but needed for the UI)
    function encodeStakeId(
        address nft,           // NFT contract address
        uint256 nftId,         // Token ID (limited to 48 bits)
        uint256 startTime,     // UNIX time (limited to 32 bits)
        uint256 stakeHours     // Stake duration (limited to 16 bits)
    ) public pure returns (uint256) {
        require(nftId < 2**48, "RDeck::nftId_EXCEEDS_48_BITS");
        require(startTime < 2**32, "RDeck::nftId_EXCEEDS_32_BITS");
        require(stakeHours < 2**16, "RDeck::stakeHours_EXCEEDS_16_BITS");
        return _encodeStakeId(nft, nftId, startTime, stakeHours);
    }

    function decodeStakeId(uint256 stakeId)
        public
        pure
        returns (
            address nft,
            uint256 nftId,
            uint256 startTime,
            uint256 stakeHours
        )
    {
        nft = address(stakeId >> 96);
        nftId = (stakeId >> 48) & (2**48 - 1);
        startTime = (stakeId >> 16) & (2**32 - 1);
        stakeHours = stakeId & (2**16 - 1);
    }

    function stakeIds(address user) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserStakes storage userStakes = stakes[user];
        return userStakes.ids;
    }

    function stakeData(
        address user,
        uint256 stakeId
    ) external view returns (Stake memory)
    {
        return stakes[_nonZeroAddr(user)].data[stakeId];
    }

    function pendedAirdrop(
        uint256 stakeId
    ) external view returns (uint256 kingAmount) {
        kingAmount = 0;
        (address nft, , , ) = decodeStakeId(stakeId);
        if (nft != address(0)) {
            uint256 accAir = accAirKingPerNft[nft];
            if (accAir > 1) {
                uint256 bias = accAirKingBias[stakeId];
                if (accAir > bias) kingAmount = accAir.sub(bias);
            }
        }
    }

    function termSheet(uint256 termsId) external view returns (TermSheet memory) {
        return termSheets[_validTermsID(termsId)];
    }

    function termsLength() external view returns (uint256) {
        return termSheets.length;
    }

    // Deposit 1 NFT and `kingAmount` of $KING
    function deposit(
        uint256 termsId,       // term sheet ID
        uint256 nftId,         // ID of NFT to stake
        uint256 kingAmount     // $KING amount to stake
    ) public nonReentrant {
        TermSheet memory terms = termSheets[_validTermsID(termsId)];
        require(terms.enabled, "deposit: terms disabled");

        uint96 amountStaked = SafeMath96.fromUint(kingAmount);
        require(amountStaked >= terms.minAmount, "deposit: too small amount");

        uint96 amountDue = SafeMath96.fromUint(
            kingAmount.mul(uint256(terms.kingFactor)).div(1e6)
        );
        uint96 _totalDue = kingDue.add(amountDue);
        uint96 _newReserves = kingReserves.add(amountStaked);
        require(_newReserves >= _totalDue, "deposit: too low reserves");

        uint256 stakeId = _encodeStakeId(
            terms.nft,
            nftId,
            now,
            terms.lockHours
        );

        IERC20(king).safeTransferFrom(msg.sender, address(this), amountStaked);
        IERC721(terms.nft).safeTransferFrom(
            msg.sender,
            address(this),
            nftId,
            _NFT_PASS
        );

        kingDue = _totalDue;
        kingReserves = _newReserves;

        uint32 startTime = SafeMath32.fromUint(now);
        uint32 unlockTime = startTime.add(uint32(terms.lockHours) * 3600);
        _addUserStake(
            stakes[msg.sender],
            stakeId,
            Stake(
                amountStaked,
                amountDue,
                startTime,
                SafeMath32.fromUint(unlockTime)
            )
        );

        uint256 accAir = accAirKingPerNft[terms.nft];
        if (accAir > 1) accAirKingBias[stakeId] = accAir;

        emit Deposit(msg.sender, stakeId, kingAmount, amountDue, unlockTime);
    }

    // Withdraw staked 1 NFT and entire $KING token amount due
    function withdraw(uint256 stakeId) public nonReentrant {
        _withdraw(stakeId, false);
        emit Withdraw(msg.sender, stakeId);
    }

    // Withdraw staked 1 NFT and staked $KING token amount, w/o any rewards
    // !!! All possible rewards entitled be lost. Use in emergency only !!!
    function emergencyWithdraw(uint256 stakeId) public nonReentrant {
        _withdraw(stakeId, true);
        emit EmergencyWithdraw(msg.sender, stakeId);
    }

    // Account for $KING amount the contact has got as airdrops for NFTs staked
    // !!! Be cautious of high gas cost
    function collectAirdrops() external nonReentrant {
        if (block.number <= lastAirBlock) return;
        lastAirBlock = SafeMath32.fromUint(block.number);

        // $KING balance exceeding `kingReserves` treated as airdrop rewards
        uint256 reward;
        {
            uint256 _kingReserves = kingReserves;
            uint256 kingBalance = IERC20(king).balanceOf(address(this));
            if (kingBalance <= _kingReserves) return;
            reward = kingBalance.sub(_kingReserves);
            kingReserves = SafeMath96.fromUint(_kingReserves.add(reward));
            kingDue = kingDue.add(uint96(reward));
        }

        // First, compute "weights" for rewards distribution
        address[MAX_AIR_POOLS_QTY] memory nfts;
        uint256[MAX_AIR_POOLS_QTY] memory weights;
        uint256 totalWeight;
        uint256 qty = airPools.length;
        uint256 k = 0;
        for (uint256 i = 0; i < qty; i++) {
            (address nft, uint256 weight) = _unpackAirPoolData(airPools[i]);
            uint256 nftQty = IERC721(nft).balanceOf(address(this));
            if (nftQty == 0 || weight == 0) continue;
            nfts[k] = nft;
            weights[k] = weight;
            k++;
            totalWeight = totalWeight.add(nftQty.mul(weight));
        }

        // Then account for rewards in pools
        for (uint i = 0; i <= k; i++) {
            address nft = nfts[i];
            accAirKingPerNft[nft] = accAirKingPerNft[nft].add(
                reward.mul(weights[i]).div(totalWeight) // can't be zero
            );
        }
        emit Airdrop(reward);
    }

    function addTerms(TermSheet[] memory _termSheets) public onlyOwner {
        for (uint256 i = 0; i < _termSheets.length; i++) {
            _addTermSheet(_termSheets[i]);
        }
    }

    function enableTerms(uint256 termsId) external onlyOwner {
        termSheets[_validTermsID(termsId)].enabled = true;
        emit TermsEnabled(termsId);
    }

    function disableTerms(uint256 termsId) external onlyOwner {
        termSheets[_validTermsID(termsId)].enabled = false;
        emit TermsDisabled(termsId);
    }

    function enableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawEnabled = true;
        emit Emergency(true);
    }

    function disableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawEnabled = false;
        emit Emergency(false);
    }

    function addAirdropPools(
        address[] memory nftAddresses,
        uint8[] memory nftWeights
    ) public onlyOwner {
        uint length = nftAddresses.length;
        require(length == nftWeights.length, "RDeck:INVALID_ARRAY_LENGTH");
        for (uint256 i = 0; i < length; i++) {
            require(
                airPools.length < MAX_AIR_POOLS_QTY,
                "RDeck:MAX_AIR_POOLS_QTY"
            );
            uint8 w = nftWeights[i];
            require(w != 0, "RDeck:INVALID_AIR_WEIGHT");
            address a = nftAddresses[i];
            _revertZeroAddress(a);
            require(accAirKingPerNft[a] == 0, "RDeck:AIR_POOL_EXISTS");
            accAirKingPerNft[a] == 1;
            airPools.push(_packAirPoolData(a, w));
        }
    }

    // Caution: it may kill pended airdrop rewards
    function removeAirdropPool(
        address nft,
        uint8 weight
    ) external onlyOwner {
        require(accAirKingPerNft[nft] != 0, "RDeck:UNKNOWN_AIR_POOL");
        accAirKingPerNft[nft] = 0;
        _removeArrayElement(airPools, _packAirPoolData(nft, weight));
    }

    function addKingReserves(address from, uint256 amount) external onlyOwner {
        IERC20(king).safeTransferFrom(from, address(this), amount);
        kingReserves = kingReserves.add(SafeMath96.fromUint(amount));
        emit Reserved(amount);
    }

    function removeKingReserves(uint256 amount) external onlyOwner {
        uint96 _newReserves = kingReserves.sub(SafeMath96.fromUint(amount));
        require(_newReserves >= kingDue, "RDeck:TOO_LOW_RESERVES");

        kingReserves = _newReserves;
        IERC20(king).safeTransfer(owner(), amount);
        emit Removed(amount);
    }

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Equals to `bytes4(keccak256("RoyalDecks"))`
    bytes private constant _NFT_PASS = abi.encodePacked(bytes4(0x8adbe135));

    // Implementation of the ERC721 Receiver
    function onERC721Received(address, address, uint256, bytes calldata data)
        external
        returns (bytes4)
    {
        // Only accept transfers with _NFT_PASS passed as `data`
        return (data.length == 4 && data[0] == 0x8a && data[3] == 0x35)
            ? _ERC721_RECEIVED
            : bytes4(0);
    }

    function _withdraw(uint256 stakeId, bool isEmergency) internal {
        require(
            !isEmergency || emergencyWithdrawEnabled,
            "withdraw: emergency disabled"
        );

        (address nft, uint256 nftId, , ) = decodeStakeId(stakeId);

        UserStakes storage userStakes = stakes[msg.sender];
        Stake memory stake = userStakes.data[stakeId];
        require(
            isEmergency || now >= stake.unlockTime,
            "withdraw: stake is locked"
        );

        uint96 amountDue = stake.amountDue;
        require(amountDue != 0, "withdraw: unknown or returned stake");

        { // Pended airdrop rewards
            uint256 accAir = accAirKingPerNft[nft];
            if (accAir > 1) {
                uint256 bias = accAirKingBias[stakeId];
                if (accAir > bias) amountDue = amountDue.add(
                    SafeMath96.fromUint(accAir.sub(bias))
                );
            }
        }

        uint96 amountToUser = isEmergency ? stake.amountStaked : amountDue;

        _removeUserStake(userStakes, stakeId);
        kingDue = kingDue.sub(amountDue);
        kingReserves = kingReserves.sub(amountDue);

        IERC20(king).safeTransfer(msg.sender, uint256(amountToUser));
        IERC721(nft).safeTransferFrom(address(this), msg.sender, nftId);
    }

    function _addTermSheet(TermSheet memory tS) internal {
        _revertZeroAddress(tS.nft);
        require(
            (tS.minAmount != 0) && (tS.lockHours != 0) && (tS.kingFactor != 0),
            "RDeck::add:INVALID_ZERO_PARAM"
        );
        require(_isMissingTerms(tS), "RDeck::add:TERMS_DUPLICATED");
        termSheets.push(tS);

        emit NewTermSheet(
            termSheets.length - 1,
            tS.nft,
            tS.minAmount,
            tS.lockHours,
            tS.kingFactor
        );
        if (tS.enabled) emit TermsEnabled(termSheets.length);
    }

    function _safeKingTransfer(address _to, uint256 _amount) internal {
        uint256 kingBal = IERC20(king).balanceOf(address(this));
        IERC20(king).safeTransfer(_to, _amount > kingBal ? kingBal : _amount);
    }

    // Returns `true` if the term sheet has NOT been yet added.
    function _isMissingTerms(TermSheet memory newSheet)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < termSheets.length; i++) {
            TermSheet memory sheet = termSheets[i];
            if (
                sheet.nft == newSheet.nft &&
                sheet.minAmount == newSheet.minAmount &&
                sheet.lockHours == newSheet.lockHours &&
                sheet.kingFactor == newSheet.kingFactor
            ) {
                return false;
            }
        }
        return true;
    }

    function _addUserStake(
        UserStakes storage userStakes,
        uint256 stakeId,
        Stake memory stake
    ) internal {
        require(
            userStakes.data[stakeId].amountDue == 0,
            "RDeck:DUPLICATED_STAKE_ID"
        );
        userStakes.data[stakeId] = stake;
        userStakes.ids.push(stakeId);
    }

    function _removeUserStake(UserStakes storage userStakes, uint256 stakeId)
        internal
    {
        require(
            userStakes.data[stakeId].amountDue != 0,
            "RDeck:INVALID_STAKE_ID"
        );
        userStakes.data[stakeId].amountDue = 0;
        _removeArrayElement(userStakes.ids, stakeId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _encodeStakeId(
        address nft,
        uint256 nftId,
        uint256 startTime,
        uint256 stakeHours
    ) internal pure returns (uint256) {
        require(nftId < 2**48, "RDeck::nftId_EXCEEDS_48_BITS");
        return uint256(nft) << 96 | nftId << 48 | startTime << 16 | stakeHours;
    }

    function _packAirPoolData(
        address nft,
        uint8 weight
    ) internal pure returns(uint256) {
        return (uint256(nft) << 8) | uint256(weight);
    }

    function _unpackAirPoolData(
        uint256 packed
    ) internal pure returns(address nft, uint8 weight)
    {
        return (address(packed >> 8), uint8(packed & 7));
    }

    function _revertZeroAddress(address _address) internal pure {
        require(_address != address(0), "RDeck::ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(termsId < termSheets.length, "RDeck::INVALID_TERMS_ID");
        return termsId;
    }
}
