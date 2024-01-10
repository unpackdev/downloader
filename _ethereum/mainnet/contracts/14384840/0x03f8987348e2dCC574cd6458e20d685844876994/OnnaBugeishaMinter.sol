// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./NftMintingStation.sol";
import "./IMintStaking.sol";

/**
 * @title OnnaBugeisha Minter
 * @notice OnnaBugeisha Minting Station
 */
contract OnnaBugeishaMinter is NftMintingStation, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct RoundConfiguration {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 maxMint;
        uint256 price;
        bool isGenki;
        bool isStaking;
    }

    bytes32 public constant SIGN_MINT_TYPEHASH =
        keccak256("Mint(uint256 quantity,uint256 value,uint256 round,address account)");


    uint256 public stakingPoolId;
    IMintStaking public stakingContract;

    IERC20 public immutable genki;

    address public immutable creator = 0x8d7b1E77608ba6856476fea50c6A217329de77c1;

    mapping(uint256 => uint256) private _tokenIdsCache;
    mapping(address => mapping(uint256 => uint256)) private _userMints;
    mapping(uint256 => RoundConfiguration) private _rounds;

    event Withdraw(uint256 amount);
    event WithdrawGenki(uint256 amount);

    modifier whenClaimable() {
        require(currentStatus == STATUS_CLAIM, "Status not claim");
        _;
    }

    modifier whenMintOpened(uint256 _round) {
        require(_rounds[_round].startTimestamp > 0, "Round not configured");
        require(_rounds[_round].startTimestamp <= block.timestamp, "Round not opened");
        require(_rounds[_round].endTimestamp == 0 || _rounds[_round].endTimestamp >= block.timestamp, "Round closed");
        _;
    }

    modifier whenValidQuantity(uint256 _quantity) {
        require(availableSupply > 0, "No more supply");
        require(availableSupply >= _quantity, "Not enough supply");
        require(_quantity > 0, "Qty <= 0");
        _;
    }

    constructor(
        INftCollection _collection,
        IERC20 _genki
    ) NftMintingStation(_collection, "OnnaBugeisha", "1.0") {
        genki = _genki;

        currentStatus = STATUS_PREPARING;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _syncSupply();
    }

    /**
     * @dev mint a `_quantity` NFT (quantity max for a wallet is limited per round)
     * _round: Round
     * _signature: backend signature for the transaction
     */
    function mint(
        uint256 _quantity,
        uint256 _round,
        bytes memory _signature
    ) external payable nonReentrant whenValidQuantity(_quantity) whenClaimable whenMintOpened(_round) {
        address to = _msgSender();
        RoundConfiguration memory round = _rounds[_round];
        require(_userMints[to][_round] + _quantity <= round.maxMint, "Above quantity allowed");

        uint256 value = round.price * _quantity;
        require(
            isAuthorized(_hashMintPayload(_quantity, value, _round, to), _signature),
            "Not signed by authorizer"
        );
        if (round.isGenki) {
            genki.safeTransferFrom(to, address(this), value);
        } else {
            require(msg.value >= value, "Payment failed");
        }

        uint256[] memory tokenIds = _mint(_quantity, to);
        _userMints[to][_round] = _userMints[to][_round] + _quantity;

        if (round.isStaking) {
            require(address(stakingContract) != address(0), "Staking not configured");
            if (_quantity == 1) stakingContract.stakeFrom(to, stakingPoolId, tokenIds[0]);
            else stakingContract.batchStakeFrom(to, stakingPoolId, tokenIds);
        }
    }

    /**
     * @dev mint the remaining NFTs when the sale is closed
     */
    function mintRemaining(address _destination, uint256 _quantity)
        external
        onlyOwnerOrOperator
        whenValidQuantity(_quantity)
    {
        require(currentStatus == STATUS_CLOSED, "Status not closed");
        _mint(_quantity, _destination);
    }

    function _withdraw(uint256 amount) private {
        require(amount <= address(this).balance, "amount > balance");
        require(amount > 0, "Empty amount");

        payable(creator).transfer(amount);
        emit Withdraw(amount);
    }

    /**
     * @dev withdraw selected amount
     */
    function withdraw(uint256 amount) external onlyOwnerOrOperator {
        _withdraw(amount);
    }

    /**
     * @dev withdraw full balance
     */
    function withdrawAll() external onlyOwnerOrOperator {
        _withdraw(address(this).balance);
    }

    /**
     * @dev withdraw genki amount
     */
    function withdrawGenki(uint256 amount) external onlyOwnerOrOperator {
        require(amount <= genki.balanceOf(address(this)), "Invalid amount");
        genki.safeTransfer(creator, amount);
        emit WithdrawGenki(amount);
    }

    /**
     * @dev configure the round
     */
    function configureRound(uint256 _round, RoundConfiguration calldata _configuration) external onlyOwnerOrOperator {
        require(
            _configuration.endTimestamp == 0 || _configuration.startTimestamp < _configuration.endTimestamp,
            "Invalid timestamps"
        );
        require(_configuration.maxMint > 0, "Invalid max mint");
        _rounds[_round] = _configuration;
    }

    function configureStaking(IMintStaking _stakingContract, uint256 _stakingPoolId) external onlyOwnerOrOperator {
        stakingContract = _stakingContract;
        stakingPoolId = _stakingPoolId;
    }

    function _getNextRandomNumber() private returns (uint256 index) {
        require(availableSupply > 0, "Invalid _remaining");

        uint256 i = maxSupply.add(uint256(keccak256(abi.encode(block.difficulty, blockhash(block.number))))).mod(
            availableSupply
        );

        // if there's a cache at _tokenIdsCache[i] then use it
        // otherwise use i itself
        index = _tokenIdsCache[i] == 0 ? i : _tokenIdsCache[i];

        // grab a number from the tail
        _tokenIdsCache[i] = _tokenIdsCache[availableSupply - 1] == 0
            ? availableSupply - 1
            : _tokenIdsCache[availableSupply - 1];
    }

    function getNextTokenId() internal override returns (uint256 index) {
        return _getNextRandomNumber() + 1;
    }

    function _hashMintPayload(
        uint256 _quantity,
        uint256 _value,
        uint256 _round,
        address _account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SIGN_MINT_TYPEHASH, _quantity, _value, _round, _account));
    }

    /**
     * @dev returns the configuration for a round
     */
    function getRound(uint256 _round) public view returns (RoundConfiguration memory) {
        return _rounds[_round];
    }

    /**
     * @dev returns the number of tokens minted by `account`
     */
    function mintedTokensCount(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < 10; i++) {
            total += _userMints[account][i];
        }
        return total;
    }

    /**
     * @dev returns the number of tokens minted by `account` for a specific round
     */
    function mintedTokensInRound(address account, uint256 round) public view returns (uint256) {
        return _userMints[account][round];
    }
}
