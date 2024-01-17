// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.4;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSet.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./ERC721AUpgradeable.sol";
import "./IPerseusNFT.sol";

contract PerseusNFT is
    IPerseusNFT,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20Upgradeable for IERC20;

    struct Card {
        string name;
        string image;
        string animationURL;
        string description;
        uint256 rewardPerDay;
        uint256 yearBonus;
    }

    struct Token {
        uint48 cardId;
        uint48 lastTransferTime;
        uint48 lastClaimTime;
        uint256 extraReward;
    }

    address public perseusERC20;
    uint256 public claimUnlockTime;
    uint256 cardListLength;
    EnumerableSet.AddressSet internal minterList;
    mapping(uint256 => Token) public tokens;
    mapping(uint256 => Card) public cards;
    uint256 public mintExtraRewardTime;
    uint256 public mintExtraRewardFactor;

    /**
     * The caller must own the token
     */
    error ClaimCallerNotOwner();

    /**
     * The claim amount must be greater than 0
     */
    error ClaimAmountZero();

    /**
     * The claim amount must be lte the contract PerseusERC20 balance
     */
    error ClaimAmountExceedsBalance();

    error InvalidParams();

    /**
     * The caller must be a minter
     */
    error CallerNotMinter();

    /**
     * The call must be made after the claimUnlockTime
     */
    error CallBeforeClaimUnlockTime();

    /**
     * @notice Triggered when a claim has been maid
     *
     * @param receiver               the address of the receiver
     * @param tokenId                the id of the token
     * @param amount                 the amount that has been claimed
     */
    event Claimed(address indexed receiver, uint256 tokenId, uint256 amount);

    /**
     * @notice Enforces sender to be a minter
     */
    modifier onlyMiner() {
        if(!minterList.contains(msg.sender)) revert CallerNotMinter();
        _;
    }

    /**
     * @notice Enforces time to be after the claimUnlockTime
     */
    modifier afterClaimUnlockTime() {
        if(block.timestamp < claimUnlockTime) revert CallBeforeClaimUnlockTime();
        _;
    }

    /**
     * @notice instantiates contract
     * @param _name                  the name of the NFT
     * @param _symbol                the symbol of the NFT
     * @param _owner                 the owner of the contract
     * @param _perseusERC20          the address of the perseus erc20 token
     * @param _minters               the addresses of the initial minters
     * @param _claimUnlockTime       the time when the holders will be allowed to claim
     * @param _mintExtraRewardTime   the starting timestamp for calculating the minting extra reward
     * @param _mintExtraRewardFactor the factor for the minting extra reward
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _perseusERC20,
        address[] memory _minters,
        uint256 _claimUnlockTime,
        uint256 _mintExtraRewardTime,
        uint256 _mintExtraRewardFactor
    ) external initializerERC721A initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721A_init(_name, _symbol);

        perseusERC20 = _perseusERC20;

        addCard(
            'Perseus Silver Card',
            'https://perseus-api.darkterminal.io/uploads/silver_26a50c5270.png',
            'https://bafybeifll2jyas275kwt4kzdstegytj4le2jpdzcjz7vlh4kwcklv2ux4m.ipfs.nftstorage.link/3.mp4',
            '',
            5476666666666666666,
            2000000000000000000000
        );
        addCard(
            'Perseus Gold Card',
            'https://perseus-api.darkterminal.io/uploads/gold_fc46a56e2d.png',
            'https://bafybeifll2jyas275kwt4kzdstegytj4le2jpdzcjz7vlh4kwcklv2ux4m.ipfs.nftstorage.link/2.mp4',
            '',
            7303333333333333333,
            2666666666666666666666
        );
        addCard(
            'Perseus Platinum Card',
            'https://perseus-api.darkterminal.io/uploads/platinum_4c58aab290.png',
            'https://bafybeifll2jyas275kwt4kzdstegytj4le2jpdzcjz7vlh4kwcklv2ux4m.ipfs.nftstorage.link/1.mp4',
            '',
            8216666666666666666,
            3333333333333333333333
        );
        addCard(
            'Perseus Black Card',
            'https://perseus-api.darkterminal.io/uploads/black_792df7ff12.png',
            'https://bafybeifll2jyas275kwt4kzdstegytj4le2jpdzcjz7vlh4kwcklv2ux4m.ipfs.nftstorage.link/0.mp4',
            '',
            9130000000000000000,
            4666666666666666666666
        );

        uint256 _index;
        uint256 _mintersLength = _minters.length;
        for (_index = 0; _index < _mintersLength; _index++) {
            minterList.add(_minters[_index]);
        }

        claimUnlockTime = _claimUnlockTime;
        mintExtraRewardTime = _mintExtraRewardTime;
        mintExtraRewardFactor = _mintExtraRewardFactor;

        transferOwnership(_owner);
    }

    /**
     * @notice Returns the address of minter communityList
     *
     * @param _index index of the minter
     * @return address of the community
     */
    function minterListAt(uint256 _index) external view returns (address) {
        return minterList.at(_index);
    }

    /**
     * @notice Returns the number of minters
     *
     * @return uint256 number of minters
     */
    function minterListLength() external view returns (uint256) {
        return minterList.length();
    }

    /**
     * @notice Returns if an address is a minter
     *
     * @param _minterAddress address to verify
     * @return bool true if the address is a minter
     */
    function isMinter(address _minterAddress) external view returns (bool) {
        return minterList.contains(_minterAddress);
    }

    /**
     * @notice Returns the list of all cards
     *
     * @return Card[] the list of all cards
     */
    function cardList() public view returns (Card[] memory) {
        Card[] memory _cardList = new Card[](cardListLength + 1);
        for (uint256 _i = 1; _i <= cardListLength; _i++) {
            _cardList[_i] = cards[_i];
        }

        return _cardList;
    }

    /**
     * @notice Updates the address of the perseusERC20
     */
    function updatePerseusERC20(address _perseusERC20) public onlyOwner {
        perseusERC20 = _perseusERC20;
    }

    /**
     * @notice Updates the value of the claimUnlockTime
     */
    function updateClaimUnlockTime(uint256 _claimUnlockTime) public onlyOwner {
        claimUnlockTime = _claimUnlockTime;
    }

    /**
     * @notice Updates the value of the mintExtraRewardTime
     */
    function updateMintExtraRewardTime(uint256 _mintExtraRewardTime) public onlyOwner {
        mintExtraRewardTime = _mintExtraRewardTime;
    }

    /**
     * @notice Updates the value of the mintExtraRewardFactor
     */
    function updateMintExtraRewardFactor(uint256 _mintExtraRewardFactor) public onlyOwner {
        mintExtraRewardFactor = _mintExtraRewardFactor;
    }

    /**
     * @notice Sets a card
     */
    function addCard(
        string memory _name,
        string memory _image,
        string memory _animationURL,
        string memory _description,
        uint256 _rewardPerDay,
        uint256 _yearBonus
    ) public onlyOwner {
        ++cardListLength;
        cards[cardListLength] = Card(_name, _image, _animationURL, _description, _rewardPerDay, _yearBonus);
    }

    /**
     * @notice Updates a card details
     */
    function updateCard(
        uint256 _cardId,
        string memory _name,
        string memory _image,
        string memory _animationURL,
        string memory _description
    ) public onlyOwner {
        if (_cardId > cardListLength || _cardId == 0) revert InvalidParams();
        Card storage _card = cards[_cardId];
        _card.name = _name;
        _card.image = _image;
        _card.animationURL = _animationURL;
        _card.description = _description;
    }

    /**
     * @notice Returns the details of a nft
     *
     * @param _tokenId id of the token
     *
     * @return cardId
     * @return reward
     * @return extraReward
     * @return yearBonus
     * @return lastTransferTime
     * @return lastClaimTime
     */
    function tokenDetails(uint256 _tokenId) public view returns (
        uint256 cardId,
        uint256 reward,
        uint256 extraReward,
        uint256 yearBonus,
        uint256 lastTransferTime,
        uint256 lastClaimTime
    ) {
        Token memory _token = tokens[_tokenId];

        cardId = _token.cardId;
        reward = tokenReward(_tokenId);
        extraReward = _token.extraReward;
        yearBonus = _unclaimedYearsNumber(_token) > 0 ? cards[cardId].yearBonus : 0;
        lastTransferTime = _token.lastTransferTime;
        lastClaimTime = _token.lastClaimTime;
    }

    /**
     * @notice enables owner to pause / unpause minting
     * @param _paused   true / false for pausing / unpausing minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @notice enables an address to mint
     * @param _minter the address to enable
     */
    function addMinter(address _minter) external onlyOwner {
        minterList.add(_minter);
    }

    /**
     * @notice disables an address from minting
     * @param _minter the address to disable
     */
    function removeMinter(address _minter) external onlyOwner {
        minterList.remove(_minter);
    }

    function tokenURI(uint256 _tokenId) override(ERC721AUpgradeable) public view returns (string memory) {
        Token memory _token = tokens[_tokenId];
        Card memory _card = cards[_token.cardId];

        string memory attributes = string(abi.encodePacked(
            '{"trait_type": "Reward Per Day", "value": "', _uint256ToDecimal(_card.rewardPerDay), '"},',
            '{"trait_type": "Year Bonus", "value": "',  _uint256ToDecimal(_card.yearBonus), '"}'
        ));

        bytes memory dataURI = abi.encodePacked(
            '{"name": "', _card.name , '",',
            '"description": "', _card.name, '",',
            '"image_data": "', _card.image, '",',
            '"animation_url": "', _card.animationURL, '",',
            '"description": "', _card.description, '",',
            '"attributes": [', attributes ,']}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    /**
     * @notice mints a new ERC721
     *
     * @param _recipient address to mint the token to
     * @param _silverAmount number of silver card tokens to be minted
     * @param _goldAmount number of gold card tokens to be minted
     * @param _platinumAmount number of platinum card tokens to be minted
     * @param _blackAmount number of black card tokens to be minted
     */
    function mint(
        address _recipient,
        uint256 _silverAmount,
        uint256 _goldAmount,
        uint256 _platinumAmount,
        uint256 _blackAmount
    ) public override whenNotPaused onlyMiner {
        uint256 _firstTokenId = _nextTokenId();

        uint256 _silverMintExtraReward;
        uint256 _goldMintExtraReward;
        uint256 _platinumMintExtraReward;
        uint256 _blackMintExtraReward;

        if (mintExtraRewardTime < block.timestamp) {
            uint256 _mintExtraRewardDays = (block.timestamp - mintExtraRewardTime) / 1 days;
            _silverMintExtraReward = _silverAmount > 0 ? _mintExtraRewardDays * mintExtraRewardFactor * cards[1].rewardPerDay / 1e18 : 0;
            _goldMintExtraReward = _goldAmount > 0 ? _mintExtraRewardDays * mintExtraRewardFactor * cards[2].rewardPerDay / 1e18 : 0;
            _platinumMintExtraReward = _platinumAmount > 0 ? _mintExtraRewardDays * mintExtraRewardFactor * cards[3].rewardPerDay / 1e18 : 0;
            _blackMintExtraReward = _blackAmount > 0 ? _mintExtraRewardDays * mintExtraRewardFactor * cards[4].rewardPerDay / 1e18 : 0;
        }

        uint48 _time = uint48(_nextDayTime());

        uint256 _lastTokenId = _firstTokenId + _silverAmount;
        while (_firstTokenId < _lastTokenId) {
            tokens[_firstTokenId] = Token(1, _time, _time, _silverMintExtraReward);
            ++_firstTokenId;
        }

        _lastTokenId += _goldAmount;
        while (_firstTokenId < _lastTokenId) {
            tokens[_firstTokenId] = Token(2, _time, _time, _goldMintExtraReward);
            ++_firstTokenId;
        }

        _lastTokenId += _platinumAmount;
        while (_firstTokenId < _lastTokenId) {
            tokens[_firstTokenId] = Token(3, _time, _time, _platinumMintExtraReward);
            ++_firstTokenId;
        }

        _lastTokenId += _blackAmount;
        while (_firstTokenId < _lastTokenId) {
            tokens[_firstTokenId] = Token(4, _time, _time, _blackMintExtraReward);
            ++_firstTokenId;
        }

        _mint(_recipient, _silverAmount + _goldAmount + _platinumAmount + _blackAmount);
    }

    function tokenReward(uint256 _tokenId) public view returns(uint256) {
        Token storage _token = tokens[_tokenId];

        Card memory _card = cards[_token.cardId];

        uint256 _rewardAmount = _unclaimedDaysNumber(_token) * _card.rewardPerDay + _token.extraReward;

        if (_unclaimedYearsNumber(_token) > 0) {
            _rewardAmount += _card.yearBonus;
        }

        return _rewardAmount;
    }

    function tokensReward(uint256[] calldata _tokenIds) public view returns(uint256) {
        uint256 totalReward;
        uint256 _index;
        uint256 _tokenIdsLength = _tokenIds.length;
        for (_index = 0; _index < _tokenIdsLength; _index++) {
            totalReward += tokenReward(_tokenIds[_index]);
        }

        return totalReward;
    }

    function addExtraReward(uint256 _tokenId, uint256 _extraReward) public onlyOwner {
        tokens[_tokenId].extraReward += _extraReward;
    }

    function claim(uint256[] calldata _tokenIds) external afterClaimUnlockTime {
        Token storage _token;
        Card memory _card;
        uint256 _tokenId;
        uint256 _days;
        uint256 _claimAmount;

        uint256 _index;
        uint256 _tokenIdsLength = _tokenIds.length;
        for (_index = 0; _index < _tokenIdsLength; _index++) {
            _tokenId = _tokenIds[_index];
            if (!(ownerOf(_tokenId) == msg.sender)) revert ClaimCallerNotOwner();

            _token = tokens[_tokenId];
            _card = cards[_token.cardId];

            _days = _unclaimedDaysNumber(_token);

            _claimAmount = _days * _card.rewardPerDay + _token.extraReward;

            //make extra calculation for year reward only if last claim was at least one year ago
            if (_days > 364 && _unclaimedYearsNumber(_token) > 0) {
                _claimAmount += _card.yearBonus;
            }

            if (_claimAmount == 0) {
                continue;
            }

            if (_claimAmount > IERC20(perseusERC20).balanceOf(address(this))) revert ClaimAmountExceedsBalance();

            _token.lastClaimTime = uint48(uint256(_token.lastClaimTime) + _days * 1 days);
            _token.extraReward = 0;

            IERC20(perseusERC20).safeTransfer(msg.sender, _claimAmount);

            emit Claimed(msg.sender, _tokenId, _claimAmount);
        }
    }

    /**
     * @notice Implements the ERC721AUpgradeable._startTokenId function
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Implements the ERC721AUpgradeable._afterTokenTransfers function
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // skip if it's a mint
        if (from == address(0)) {
            return;
        }

        uint256 _limit = startTokenId + quantity;
        while (startTokenId < _limit) {
            tokens[startTokenId].lastTransferTime = uint48(_nextDayTime());
            ++startTokenId;
        }
    }

    function _unclaimedDaysNumber(Token memory _token) internal view returns(uint256) {
        uint256 _lastClaimTime = uint256(_token.lastClaimTime);
        if (block.timestamp <= _lastClaimTime) {
            return 0;
        } else {
            return (block.timestamp - _lastClaimTime) / 1 days;
        }
    }

    function _unclaimedYearsNumber(Token memory _token) internal view returns(uint256) {
        uint256 _lastTransferOrClaimTime = _token.lastClaimTime > _token.lastTransferTime ?
            uint256(_token.lastClaimTime) : uint256(_token.lastTransferTime);

        if (block.timestamp <= _lastTransferOrClaimTime) {
            return 0;
        } else {
            return (block.timestamp - _lastTransferOrClaimTime) / 365 days;
        }
    }

    function _nextDayTime() internal view returns(uint256) {
        return (block.timestamp / 1 days + 1) * 1 days;
    }

    function _uint256ToDecimal(uint256 _number) internal pure returns(string memory) {
        uint256 _whole = _number / 1e18;
        uint256 _decimal = (_number -  _whole * 1e18) / 1e16;

        if (_decimal > 0) {
            return string(abi.encodePacked(_toString(_whole), '.', _toString(_decimal)));
        } else {
            return string(_toString(_whole));
        }
    }
}
