//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleWithRoyalties.sol";

import "./GroupedURIs.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

contract NFTBattles is
    Ownable,
    ReentrancyGuard,
    GroupedURIs,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties
{
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    error WETHNotSet();
    error BattleInactive();
    error WrongContender();
    error NoSelfOutbid();
    error WrongBidValue();
    error NotEnoughContenders();
    error AlreadySettled();
    error UnknownBattle();
    error BattleNotEnded();

    event BattleCreated(uint256 battleId, address[] contenders);

    event BidCreated(
        uint256 battleId,
        uint256 contender,
        address bidder,
        uint256 bid
    );

    event BattleStartChanged(uint256 battleId, uint256 newEnd);

    event BattleEndChanged(uint256 battleId, uint256 newEnd);

    event BattleSettled(uint256 battleId, uint256 bidsSum);

    event BattleContenderResult(
        uint256 battleId,
        uint256 index,
        uint256 tokenId,
        address randomBidder
    );

    event BattleCanceled(uint256 battleId);

    struct Battle {
        uint256 startsAt;
        uint256 endsAt;
        uint256 contenders;
        bool settled;
    }

    struct BattleContender {
        address artist;
        address highestBidder;
        uint256 highestBid;
        EnumerableSet.AddressSet bidders;
    }

    /// @notice the contract holding the NFTs
    address public nftContract;

    /// @notice minimal bid
    uint256 public minimalBid = 0.001 ether;

    /// @notice minimal bid increase when bidding (5% initially)
    uint256 public minimalBidIncrease = 5;

    /// @notice time to add to the battle auction end when late bids
    uint256 public timeBuffer = 5 minutes;

    /// @notice contains last known battle id
    uint256 public lastBattleId;

    /// @notice the target address getting the eth when settling a Battle
    address public withdrawTarget;

    /// @notice all battles
    mapping(uint256 => Battle) public battles;

    /// @notice all contenders
    mapping(uint256 => mapping(uint256 => BattleContender))
        internal _battleContenders;

    /// @notice weth contract address to refund users if transfer fails
    address public immutable wethContract;

    /// @notice mapping tokenId => creator
    mapping(uint256 => address) public tokenCreator;

    constructor(
        string memory contractURI_,
        string memory baseURI,
        address wethContract_,
        address owner_
    ) NFBaseModule(contractURI_) {
        _incrementGroup("", baseURI);

        uint256 chainId = block.chainid;
        if (chainId == 4) {
            wethContract_ = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        } else if (chainId == 1) {
            wethContract_ = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else {
            if (wethContract_ == address(0)) {
                revert WETHNotSet();
            }
        }

        // immutable can not be initialized in an if statement.
        wethContract = wethContract_;

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    ////////////////////////////////////////////
    // getters                                //
    ////////////////////////////////////////////

    /// @notice returns current bids for a battle
    /// @param battleId the battle id
    /// @return bidders an array of bidders
    /// @return bids an array of bids
    function getBattleBids(uint256 battleId)
        external
        view
        returns (address[] memory bidders, uint256[] memory bids)
    {
        Battle memory battle = battles[battleId];

        bidders = new address[](battle.contenders);
        bids = new uint256[](battle.contenders);

        for (uint256 i; i < battle.contenders; i++) {
            bidders[i] = _battleContenders[battleId][i].highestBidder;
            bids[i] = _battleContenders[battleId][i].highestBid;
        }
    }

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    function onAttach() external virtual override returns (bool) {
        if (nftContract != address(0)) {
            revert();
        }

        nftContract = msg.sender;
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256 tokenId)
        public
        view
        override
        returns (address recipient, uint256 basisPoint)
    {
        // 7.5% to tokenCreator
        recipient = tokenCreator[tokenId];
        basisPoint = 750;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address registry, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory baseURI = groupBaseURI[tokenGroup[tokenId]];
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    ////////////////////////////////////////////
    // Publics                                //
    ////////////////////////////////////////////

    /// @notice Allows to bid on `contender` for a Battle
    /// @param battleId the battle id to bid on
    /// @param contender the contender to bid on
    function bid(uint256 battleId, uint256 contender)
        public
        payable
        nonReentrant
    {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        // time check
        uint256 timestamp = block.timestamp;
        if (!(timestamp >= battle.startsAt && timestamp < battle.endsAt)) {
            revert BattleInactive();
        }

        // input check
        BattleContender storage auction = _battleContenders[battleId][
            contender
        ];
        if (auction.artist == address(0)) {
            revert WrongContender();
        }

        address sender = msg.sender;

        // can't outbid yourself.
        // why? someone could be watching the pool, and outbid themselves in order to make incoming bid invalid
        // and not have to outbid an higher bid
        if (auction.highestBidder == sender) {
            revert NoSelfOutbid();
        }

        // value check
        uint256 currentBid = msg.value;
        if (
            currentBid <
            ((auction.highestBid * (100 + minimalBidIncrease)) / 100) ||
            currentBid < minimalBid
        ) {
            revert WrongBidValue();
        }

        // add to bidders
        auction.bidders.add(sender);

        // refund previous highest bidder
        if (auction.highestBid != 0) {
            _sendETHSafe(auction.highestBidder, auction.highestBid);
        }

        auction.highestBidder = sender;
        auction.highestBid = currentBid;

        emit BidCreated(battleId, contender, sender, currentBid);

        uint256 timeBuffer_ = timeBuffer;
        if (timestamp > battle.endsAt - timeBuffer_) {
            battle.endsAt = timestamp + timeBuffer_;
            emit BattleEndChanged(battleId, battle.endsAt);
        }
    }

    ////////////////////////////////////////////
    // Owner / Admin                          //
    ////////////////////////////////////////////

    /// @notice Allows owner to create a battle
    /// @param contenders the contenders for this battle
    /// @param startsAt when the battle starts
    /// @param duration the duration of the battle
    function createBattle(
        address[] calldata contenders,
        uint256 startsAt,
        uint256 duration
    ) external onlyOwner {
        uint256 length = contenders.length;
        if (length < 2) {
            revert NotEnoughContenders();
        }

        uint256 battleId = ++lastBattleId;

        Battle storage battle = battles[battleId];

        battle.startsAt = startsAt;
        battle.endsAt = startsAt + duration;
        battle.contenders = length;

        for (uint256 i; i < length; i++) {
            if (contenders[i] == address(0)) {
                revert WrongContender();
            }

            _battleContenders[battleId][i].artist = contenders[i];
        }

        emit BattleCreated(battleId, contenders);
    }

    /// @notice allows owner to cancel a battle
    /// @param battleId the battle id
    function cancelBattle(uint256 battleId) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];
        battle.settled = true;

        uint256 length = battle.contenders;
        BattleContender storage contender;

        for (uint256 i; i < length; i++) {
            contender = _battleContenders[battleId][i];
            // refund highest bidder for each contender
            if (contender.highestBid != 0) {
                _sendETHSafe(contender.highestBidder, contender.highestBid);
            }
        }

        emit BattleCanceled(battleId);
    }

    /// @notice allows owner to settle a battle
    /// @param battleId the battle id
    function settleBattle(uint256 battleId) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        uint256 timestamp = block.timestamp;
        if (timestamp < battle.endsAt) {
            revert BattleNotEnded();
        }

        // settle the battle here, this will lock any Reentrancy
        battle.settled = true;

        bytes32 seed = keccak256(
            abi.encode(
                block.timestamp,
                msg.sender,
                block.difficulty,
                blockhash(block.number - 1)
            )
        );

        uint256 cumul;
        uint256 temp;
        uint256 length = battle.contenders;

        uint256 currentGroupId_ = currentGroupId;
        address nftContract_ = nftContract;
        BattleContender storage contender;

        for (uint256 i; i < length; i++) {
            contender = _battleContenders[battleId][i];
            cumul += contender.highestBid;

            if (contender.highestBid > 0) {
                // if there is a bid
                // mint the NFT to artist and transfer to highestBidder
                temp = INiftyForge721(nftContract_).mint(
                    contender.artist,
                    contender.highestBidder
                );

                // select a random bidder in the list of bidders
                seed = keccak256(abi.encode(seed));

                emit BattleContenderResult(
                    battleId,
                    i, // index
                    temp, // tokenId
                    //  random bidder
                    contender.bidders.at(
                        uint256(seed) % contender.bidders.length()
                    )
                );
            } else {
                // else mint the NFT to artist
                temp = INiftyForge721(nftContract_).mint(contender.artist);
            }

            _setTokenGroup(temp, currentGroupId_);
            tokenCreator[temp] = contender.artist;
        }

        _sendETHSafe(
            withdrawTarget != address(0) ? withdrawTarget : msg.sender,
            cumul
        );

        emit BattleSettled(battleId, cumul);
    }

    /// @notice allows owner to change the time of a battle
    /// @param battleId the battle id
    /// @param startsAt the start time
    /// @param duration the battle duration
    function setBattleStarts(
        uint256 battleId,
        uint256 startsAt,
        uint256 duration
    ) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        battle.startsAt = startsAt;
        battle.endsAt = startsAt + duration;
        emit BattleStartChanged(battleId, startsAt);
        emit BattleEndChanged(battleId, startsAt + duration);
    }

    /// @notice allows owner to pass to the next
    /// @param previousGroupBaseURI current group baseURI
    /// @param newGroupBaseURI next group baseURI
    function incrementGroup(
        string calldata previousGroupBaseURI,
        string calldata newGroupBaseURI
    ) external onlyOwner {
        _incrementGroup(previousGroupBaseURI, newGroupBaseURI);
    }

    /// @notice allows owner to set a group URI
    /// @param groupId the group id
    /// @param baseURI group baseURI
    function setGroupURI(uint256 groupId, string calldata baseURI)
        external
        onlyOwner
    {
        _setGroupURI(groupId, baseURI);
    }

    /// @notice allows owner to set one URI for several groups
    /// @param groupIds the groups ids
    /// @param baseURI group baseURI
    function setGroupsURI(uint256[] calldata groupIds, string calldata baseURI)
        external
        onlyOwner
    {
        for (uint256 i; i < groupIds.length; i++) {
            _setGroupURI(groupIds[i], baseURI);
        }
    }

    /// @notice allows owner to associate a token to a specific group
    /// @param tokenId the token id
    /// @param groupId the group id
    function setTokenGroup(uint256 tokenId, uint256 groupId)
        external
        onlyOwner
    {
        _setTokenGroup(tokenId, groupId);
    }

    /// @notice allows owner to associate tokenIds to a specific group
    /// @param tokenIds the token ids
    /// @param groupId the group id
    function setTokensGroup(uint256[] calldata tokenIds, uint256 groupId)
        external
        onlyOwner
    {
        for (uint256 i; i < tokenIds.length; i++) {
            _setTokenGroup(tokenIds[i], groupId);
        }
    }

    /// @notice allows owner to set the withdraw address
    /// @param newWithdrawTarget the new address to withdraw to
    function setWithdrawTarget(address newWithdrawTarget) external onlyOwner {
        withdrawTarget = newWithdrawTarget;
    }

    /// @notice allows owner to change minimalBidIncreace and minimalBid
    /// @param newMinimalBid the new minimal bid, in wei
    /// @param newMinimalBidIncrease the new minimalBidIncrease, in percent, no decimals
    function setMinimals(uint256 newMinimalBid, uint256 newMinimalBidIncrease)
        external
        onlyOwner
    {
        minimalBid = newMinimalBid;
        minimalBidIncrease = newMinimalBidIncrease;
    }

    ////////////////////////////////////////////
    // Internals                              //
    ////////////////////////////////////////////

    /// @dev This function tries to send eth to an address; if the transfer doesn't work
    ///      it will be done using WETH
    /// @param recipient the recipient to refund
    /// @param value the value to refund
    function _sendETHSafe(address recipient, uint256 value) internal {
        if (value == 0) {
            return;
        }

        // limit to 30k gas, to ensure noone uses a contract
        // to make outbidding/canceling overly expensive or impossible.
        (bool success, ) = recipient.call{value: value, gas: 30000}("");

        // if the refund didn't work, transform the ethereum into WETH and send it
        // to recipient
        if (!success) {
            IWETH(wethContract).deposit{value: value}();
            IWETH(wethContract).transfer(recipient, value);
        }
    }
}
