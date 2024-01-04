
pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Safe112.sol";
import "./Operator.sol";
import "./ContractGuard.sol";
import "./IHCAsset.sol";

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public share;

    uint256 private _totalSupply;
    uint256 private _totalInternalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _internalBalances;

    function totalInternalSupply() public view returns (uint256) {
        return _totalInternalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function internalBalanceOf(address account) public view returns (uint256) {
        return _internalBalances[account];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, uint256 userBoostPower) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _totalInternalSupply = _totalInternalSupply.add(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].add((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        share.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, uint256 userBoostPower) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _totalInternalSupply = _totalInternalSupply.sub(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].sub((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        share.safeTransfer(msg.sender, amount);
    }

    function _update(uint256 _userBoostPower) internal {
        uint256 oldInternalBalance = _internalBalances[msg.sender];
        uint256 newInternalBalance = _balances[msg.sender].mul(_userBoostPower.add(1e18)).div(1e18);
        _internalBalances[msg.sender] = newInternalBalance;
        _totalInternalSupply = _totalInternalSupply.sub(oldInternalBalance).add(newInternalBalance);
    }
}

interface IHayekPlate {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transfer(address _to, uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getFeatureAddr() external returns(address);
}

interface IHayekPlateCustomData {
    function getTokenIdBoostPower(uint256 tokenId) external view returns(uint256);
}

contract HayekPlateWrapper {
    using SafeMath for uint256;
    IHayekPlate public hayekPlate; 

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => uint256) private _ownedBoostPower;
    mapping (uint256 => address) private _tokenOwner;
    
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function totalNFTSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function stakePlate(uint256 tokenId) public virtual {
        require(msg.sender == hayekPlate.ownerOf(tokenId), 'This account is not owner');
        _tokenOwner[tokenId] = msg.sender;
        _addTokenToOwnerEnumeration(msg.sender, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
        uint256 _plateBoostPower = getTokenIdBoostPower(tokenId);
        _ownedBoostPower[msg.sender] += _plateBoostPower;
        hayekPlate.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function withdrawPlate(uint256 tokenId) public virtual {
        require(msg.sender == _tokenOwner[tokenId], 'This account is not owner');
        _removeTokenFromOwnerEnumeration(msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        uint256 _plateBoostPower = getTokenIdBoostPower(tokenId);
        _ownedBoostPower[msg.sender] -= _plateBoostPower;
        hayekPlate.transfer(msg.sender, tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokens[from].pop();
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }

    function getAccountBoostPower(address account) public view returns(uint256){
        return _ownedBoostPower[account];
    }

    function getTokenIdBoostPower(uint256 tokenId) internal returns(uint256){
        address customDataAddr = hayekPlate.getFeatureAddr();
        IHayekPlateCustomData hayekPlateCustomData = IHayekPlateCustomData(customDataAddr);
        return hayekPlateCustomData.getTokenIdBoostPower(tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external 
        returns (bytes4) 
    {
        // Shh
        return _ERC721_RECEIVED;
    }
}

contract Boardroom is ShareWrapper, HayekPlateWrapper, ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========== DATA STRUCTURES ========== */

    struct Boardseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
    }

    struct BoardSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 private cash;

    mapping(address => Boardseat) private directors;
    BoardSnapshot[] private boardHistory;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _cash, IHayekPlate _hayekPlate, IERC20 _share) public {
        cash = _cash;
        share = _share;
        hayekPlate = _hayekPlate;
        BoardSnapshot memory genesisSnapshot =
            BoardSnapshot({
                time: block.number,
                rewardReceived: 0,
                rewardPerShare: 0
            });
        boardHistory.push(genesisSnapshot);
    }

    /* ========== Modifiers =============== */
    modifier directorExists {
        require(
            balanceOf(msg.sender) > 0,
            'Boardroom: The director does not exist'
        );
        _;
    }

    modifier updateReward(address director) {
        if (director != address(0)) {
            Boardseat memory seat = directors[director];
            seat.rewardEarned = earned(director);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            directors[director] = seat;
        }
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return boardHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address director)
        public
        view
        returns (uint256)
    {
        return directors[director].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address director)
        internal
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[getLastSnapshotIndexOf(director)];
    }

    // =========== Director getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address director) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        return
            internalBalanceOf(director).mul(latestRPS.sub(storedRPS)).div(1e18).add(
                directors[director].rewardEarned
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakePlate(uint256 tokenId) 
        public
        override
        onlyOneBlock
        updateReward(msg.sender)
    {
        require(tokenId > 0, 'HCCUNIPool: Invalid tokenId');
        super.stakePlate(tokenId);
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        _update(userBoostPower);
        emit PlateStaked(msg.sender, tokenId);
    }

    function withdrawPlate(uint256 tokenId) 
        public
        override
        onlyOneBlock
        updateReward(msg.sender)
    {
        require(tokenId > 0, 'HCCUNIPool: Invalid tokenId');
        super.withdrawPlate(tokenId);
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        _update(userBoostPower);
        emit PlateWithdrawn(msg.sender, tokenId);
    }

    function stake(uint256 amount)
        public
        onlyOneBlock
        updateReward(msg.sender)
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        super.stake(amount, userBoostPower);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        onlyOneBlock
        directorExists
        updateReward(msg.sender)
    {
        require(amount > 0, 'Boardroom: Cannot withdraw 0');
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        super.withdraw(amount, userBoostPower);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        claimReward();
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = directors[msg.sender].rewardEarned;
        if (reward > 0) {
            directors[msg.sender].rewardEarned = 0;
            cash.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount)
        external
        onlyOneBlock
        onlyOperator
    {
        require(amount > 0, 'Boardroom: Cannot allocate 0');
        require(
            totalSupply() > 0,
            'Boardroom: Cannot allocate when totalSupply is 0'
        );

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalInternalSupply()));

        BoardSnapshot memory newSnapshot =
            BoardSnapshot({
                time: block.number,
                rewardReceived: amount,
                rewardPerShare: nextRPS
            });
        boardHistory.push(newSnapshot);

        cash.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PlateStaked(address indexed user, uint256 tokenId);
    event PlateWithdrawn(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);
}
