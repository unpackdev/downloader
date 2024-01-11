// SPDX-License-Identifier: MIT

/* 
 
 ________  ________  ___  ________           ________  ___       ________  ________   _________        ________   ___  ___  ________  ________  _______   ________      ___    ___ 
|\   ____\|\   __  \|\  \|\   ___  \        |\   __  \|\  \     |\   __  \|\   ___  \|\___   ___\     |\   ___  \|\  \|\  \|\   __  \|\   ____\|\  ___ \ |\   __  \    |\  \  /  /|
\ \  \___|\ \  \|\  \ \  \ \  \\ \  \       \ \  \|\  \ \  \    \ \  \|\  \ \  \\ \  \|___ \  \_|     \ \  \\ \  \ \  \\\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \   \ \  \/  / /
 \ \  \    \ \  \\\  \ \  \ \  \\ \  \       \ \   ____\ \  \    \ \   __  \ \  \\ \  \   \ \  \       \ \  \\ \  \ \  \\\  \ \   _  _\ \_____  \ \  \_|/_\ \   _  _\   \ \    / / 
  \ \  \____\ \  \\\  \ \  \ \  \\ \  \       \ \  \___|\ \  \____\ \  \ \  \ \  \\ \  \   \ \  \       \ \  \\ \  \ \  \\\  \ \  \\  \\|____|\  \ \  \_|\ \ \  \\  \|   \/  /  /  
   \ \_______\ \_______\ \__\ \__\\ \__\       \ \__\    \ \_______\ \__\ \__\ \__\\ \__\   \ \__\       \ \__\\ \__\ \_______\ \__\\ _\ ____\_\  \ \_______\ \__\\ _\ __/  / /    
    \|_______|\|_______|\|__|\|__| \|__|        \|__|     \|_______|\|__|\|__|\|__| \|__|    \|__|        \|__| \|__|\|_______|\|__|\|__|\_________\|_______|\|__|\|__|\___/ /     
                                                                                                                                        \|_________|                  \|___|/      
                                                                                                                                                                                   
 * @title CoinPlantNursery
 * @author xH!ro
 * @notice Staking contract allowing CoinPlant to earn $POLLEN
 */

pragma solidity ^0.8.11;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

error Nursery_InvalidTokenAmount();
error Nursery_SenderNotTokenOwner();
error Nursery_TokenNotStranded();

contract CoinPlantNursery is
    Ownable,
    ERC721Holder,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    struct AccountInfo {
        uint16 shares;
        uint128 lastUpdate;
        uint256 stash;
    }

    IERC721 public COINPLANT_NFT;
    IERC20 public POLLEN;

    uint256 public constant MAX_PER_TX = 25;
    uint256 public constant BASE_RATE = 10 ether;
    uint256 public stakedTotal;
    uint256 internal immutable PLANT_GENESIS_SUPPLY;
    uint256 internal immutable PLANT_MAX_SUPPLY;

    address internal immutable TREASURY_WALLET;

    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => address) public tokenOwners;

    event Stake(uint256 indexed tokenId, address indexed from);
    event Unstake(uint256 indexed tokenId, address indexed to);

    constructor(
        address _coinPlant,
        uint256 _genesisSupply,
        uint256 _maxSupply,
        address _pollen,
        address _treasuryWallet
    ) {
        COINPLANT_NFT = IERC721(_coinPlant);
        PLANT_GENESIS_SUPPLY = _genesisSupply;
        PLANT_MAX_SUPPLY = _maxSupply;
        POLLEN = IERC20(_pollen);
        TREASURY_WALLET = _treasuryWallet;

        _pause();
    }

    /**
     * @notice Get the owner of the specified CoinPlant
     * @param _tokenId CoinPlant to return the owner of
     * @return address Owner of the specified CoinPlant
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tokenOwners[_tokenId];
    }

    /**
     * @notice Get list of CointPlant tokens by account
     * @param _account Address of the CointPlant owner
     * @return uint256[] The CoinPlant tokens owned by the specified account
     */
    function getAllOwned(address _account)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory indexMap = new uint256[](PLANT_MAX_SUPPLY);

        uint256 index;
        for (uint256 tokenId; tokenId < PLANT_MAX_SUPPLY; ++tokenId) {
            if (tokenOwners[tokenId] == _account) {
                indexMap[index] = tokenId;
                ++index;
            }
        }

        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i; i < index; i++) {
            tokenIds[i] = indexMap[i];
        }

        return tokenIds;
    }

    /**
     * @notice Get amount of claimable $POLLEN
     * @param _account Address to return claimable $POLLEN for
     * @return uint256 Amount of claimable $POLLEN
     */
    function getClaimable(address _account) public view returns (uint256) {
        return accountInfo[_account].stash + _getPending(_account);
    }

    /**
     * @notice Get pending $POLLEN rewards for a specified account calculated based on their staked COINPLANT tokens
     * @param _account Address to return the pending $POLLEN rewards of
     * @return uint256 Amount of $POLLEN a specified account has pending
     */
    function _getPending(address _account) internal view returns (uint256) {
        AccountInfo memory _accountInfo = accountInfo[_account];

        return
            (_accountInfo.shares *
                BASE_RATE *
                (block.timestamp - _accountInfo.lastUpdate)) / 1 days;
    }

    /**
     * @notice Get $POLLEN stash of a specified account
     * @param _account Address of the account to get the $POLLEN stash of
     * @return uint256 Amount of $POLLEN stash of the specified account
     */
    function stash(address _account) public view returns (uint256) {
        return accountInfo[_account].stash;
    }

    /**
     * @notice Move pending $POLLEN rewards to a specified account stash and reset the timer
     * @dev This should be called before any operation that changes values used in _getPending(address)
     * @param _account Address to update the rewards of
     */
    function _updateStash(address _account) internal {
        accountInfo[_msgSender()].stash += _getPending(_account);
        accountInfo[_msgSender()].lastUpdate = uint128(block.timestamp);
    }

    /**
     * @notice Stake CoinPlant tokens and start earning $POLLEN
     * @param _tokenIds CoinPlant tokens to stake
     */
    function stake(uint256[] memory _tokenIds)
        public
        whenNotPaused
        nonReentrant
    {
        if (_tokenIds.length == 0 || _tokenIds.length > MAX_PER_TX)
            revert Nursery_InvalidTokenAmount();

        _updateStash(_msgSender());

        uint16 genesisCount;
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            require(
                COINPLANT_NFT.ownerOf(tokenId) == _msgSender(),
                "You must be the owner of the token"
            );

            COINPLANT_NFT.safeTransferFrom(
                _msgSender(),
                address(this),
                tokenId
            );
            tokenOwners[tokenId] = _msgSender();

            if (tokenId <= PLANT_GENESIS_SUPPLY) ++genesisCount;

            emit Stake(tokenId, _msgSender());
        }

        stakedTotal += _tokenIds.length;
        accountInfo[_msgSender()].shares += uint16(
            _tokenIds.length + genesisCount
        );
    }

    /**
     * @notice Unstake CoinPlant tokens
     * @param _tokenIds CoinPlant tokens to unstake
     */
    function unstake(uint256[] calldata _tokenIds) public nonReentrant {
        if (_tokenIds.length == 0 || _tokenIds.length > MAX_PER_TX)
            revert Nursery_InvalidTokenAmount();

        _updateStash(_msgSender());

        uint16 genesisCount;
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            if (tokenOwners[tokenId] != _msgSender())
                revert Nursery_SenderNotTokenOwner();

            COINPLANT_NFT.safeTransferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
            tokenOwners[tokenId] = address(0);

            if (tokenId < PLANT_GENESIS_SUPPLY) ++genesisCount;

            emit Unstake(tokenId, _msgSender());
        }

        stakedTotal -= _tokenIds.length;
        accountInfo[_msgSender()].shares -= uint16(
            _tokenIds.length + genesisCount
        );
    }

    /**
     *
     */
    function claimPOLLEN() public {
        uint256 claimable = getClaimable(_msgSender());

        require(claimable > 0, "0 rewards yet");
        POLLEN.transferFrom(TREASURY_WALLET, _msgSender(), claimable);

        accountInfo[_msgSender()].stash = 0;
        accountInfo[_msgSender()].lastUpdate = uint128(block.timestamp);
    }

    /**
     * @notice Recover CoinPlant tokens accidentally transferred directly to the contract
     * @dev Only available to owner if internal owner mapping was not updated
     * @param _to Account to send the CoinPlant to
     * @param _tokenId CoinPlant to recover
     */
    function recoveryTransfer(address _to, uint256 _tokenId)
        external
        onlyOwner
    {
        if (tokenOwners[_tokenId] != address(0))
            revert Nursery_TokenNotStranded();

        stakedTotal--;
        COINPLANT_NFT.transferFrom(address(this), _to, _tokenId);
    }

    /**
     * @notice Flip paused state to temporarily disable minting
     */
    function flipPaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}
