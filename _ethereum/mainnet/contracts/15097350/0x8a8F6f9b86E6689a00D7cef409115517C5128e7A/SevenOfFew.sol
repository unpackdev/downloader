//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./IERC20.sol";

import "./SevenOfFewEmblems.sol";

import "./ISevenOfFew.sol";
import "./ISevenOfFewEmblems.sol";

struct Bid {
    address bidder;
    uint256 value;
}

enum Stage {
    AUCTION,
    GOODLIST_MINTING,
    PUBLIC_MITING
}

contract SevenOfFew is ERC1155Supply, Ownable, AccessControl, ISevenOfFew {
    using Strings for uint256;

    event NewBid(uint256 pieceId, address bidder, uint256 value);

    // State variables

    ISevenOfFewEmblems private immutable _emblems;

    uint256 public immutable override startDate = 1657220400;

    address private immutable _withdrawalAddress;
    address private _communityWallet;

    address public ubiBurner = 0x481B24Ed5feAcB37e282729b9815e27529Cf9ae2;

    bytes32 public constant ADMINS_ADMIN = keccak256("ADMINS_ADMIN");
    bytes32 public constant GOODLIST_ADMIN = keccak256("GOODLIST_ADMIN");
    bytes32 public constant GOODLIST_GENERAL = keccak256("GOODLIST_GENERAL");

    uint256 private _auctionsSafe;

    string private _myBaseURI;

    // pieceId => highest Bid
    mapping(uint256 => Bid) private _highestBids;

    // pieceId => reserved tokens amount
    mapping(uint256 => uint256) private _reservedAmounts;

    // address => puzzleId => categories
    mapping(address => mapping(uint256 => uint256[])) private _reservations;

    // address => pieceId => goodlist minted amount
    mapping(address => mapping(uint256 => uint256)) private _goodlistMinted;

    // puzzleId => community tokens amount
    mapping(uint256 => uint256) private _communityTokensAmounts;

    // address => puzzleId => minted reserved tokens
    mapping(address => mapping(uint256 => bool)) private _mintedReservedTokens;

    constructor(
        address withdrawalAddress_,
        address communityWallet_,
        //
        address _admin,
        address[] memory _goodlistAdmins,
        //
        string memory baseURI_,
        string memory _emblemsBaseURI,
        //
        uint256[] memory reservedPieceIds_,
        uint256[] memory reservedAmounts_,
        //
        address[] memory _reservationsAddresses,
        uint256[][][] memory reservations_,
        //
        uint256[] memory communityPuzzleAmounts_
    ) ERC1155("") {
        _withdrawalAddress = withdrawalAddress_;
        _communityWallet = communityWallet_;
        _myBaseURI = baseURI_;

        // deploy emblems contract
        SevenOfFewEmblems _emblemsContract = new SevenOfFewEmblems(
            msg.sender,
            _emblemsBaseURI
        );
        _emblems = ISevenOfFewEmblems(address(_emblemsContract));

        _setRoleAdmin(GOODLIST_GENERAL, GOODLIST_ADMIN);

        _setRoleAdmin(GOODLIST_ADMIN, ADMINS_ADMIN);

        _grantRole(ADMINS_ADMIN, _admin);

        for (uint256 i = 0; i < _goodlistAdmins.length; i++) {
            _grantRole(GOODLIST_ADMIN, _goodlistAdmins[i]);
        }

        for (uint256 i = 0; i < reservedPieceIds_.length; i++) {
            _reservedAmounts[reservedPieceIds_[i]] = reservedAmounts_[i];
        }

        for (uint256 i = 0; i < _reservationsAddresses.length; i++) {
            address addr = _reservationsAddresses[i];

            for (uint256 j = 0; j < reservations_[i].length; j++) {
                _reservations[addr][j + 1] = reservations_[i][j];
            }
        }

        for (uint256 i = 0; i < communityPuzzleAmounts_.length; i++) {
            _communityTokensAmounts[i + 1] = communityPuzzleAmounts_[i];
        }
    }

    // Emblems

    function emblems() external view override returns (address) {
        return address(_emblems);
    }

    // security

    modifier validPuzzle(uint256 puzzleId) {
        require(puzzleId > 0, "Invalid puzzle id");
        require(puzzleId < 8, "Invalid puzzle id");
        _;
    }

    modifier validPiece(uint256 pieceId) {
        require(pieceId > 0, "Invalid piece id");
        require(pieceId < 50, "Invalid piece id");
        _;
    }

    modifier validCategory(uint256 categoryId) {
        require(categoryId > 0, "Invalid category id");
        require(categoryId < 8, "Invalid category id");
        _;
    }

    modifier auctionPiece(uint256 pieceId) {
        require(categoryOf(pieceId) == 1, "Piece id is not an auction piece");
        _;
    }

    modifier nonAuctionPiece(uint256 pieceId) {
        require(categoryOf(pieceId) != 1, "Piece id is an auction piece");
        _;
    }

    // access control

    function _puzzleToRole(uint256 _puzzleId) private pure returns (bytes32) {
        return bytes32(_puzzleId);
    }

    function grantPuzzleGoodlistRole(uint256 puzzleId, address[] memory addrs)
        public
        onlyRole(GOODLIST_ADMIN)
    {
        bytes32 _role = _puzzleToRole(puzzleId);
        for (uint256 i = 0; i < addrs.length; i++) {
            _grantRole(_role, addrs[i]);
        }
    }

    function grantGeneralGoodlistRole(address[] memory addrs)
        public
        onlyRole(GOODLIST_ADMIN)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            _grantRole(GOODLIST_GENERAL, addrs[i]);
        }
    }

    // Puzzle completion

    function puzzleBaseId(uint256 _puzzleId) private pure returns (uint256) {
        return (_puzzleId - 1) * 7;
    }

    function completedPuzzle(address addr, uint256 puzzleId)
        external
        view
        override
        returns (bool)
    {
        uint256 _puzzleBaseId = puzzleBaseId(puzzleId);

        for (uint256 categoryId = 1; categoryId <= 7; categoryId++) {
            if (balanceOf(addr, _puzzleBaseId + categoryId) == 0) return false;
        }

        return true;
    }

    // stages

    function puzzleStart(uint256 puzzleId) public pure returns (uint256) {
        return startDate + (puzzleId - 1) * 7 days;
    }

    function _stageDeltaStart(Stage _stage) private pure returns (uint256) {
        if (_stage == Stage.AUCTION) return 0;
        if (_stage == Stage.GOODLIST_MINTING) return 21 hours;
        if (_stage == Stage.PUBLIC_MITING) return 42 hours;
    }

    function _stageDeltaEnd(Stage _stage) private pure returns (uint256) {
        if (_stage == Stage.AUCTION) return 21;
        if (_stage == Stage.GOODLIST_MINTING) return 42 hours;
        if (_stage == Stage.PUBLIC_MITING) return 161 hours;
    }

    modifier activeStagePeriod(uint256 _puzzleId, Stage _stage) {
        uint256 _puzzleStart = puzzleStart(_puzzleId);

        require(
            block.timestamp >= _puzzleStart + _stageDeltaStart(_stage),
            "Stage has not started yet"
        );
        require(
            block.timestamp < _puzzleStart + _stageDeltaEnd(_stage),
            "Stage has already ended"
        );
        _;
    }

    modifier stageStarted(uint256 _puzzleId, Stage _stage) {
        require(
            block.timestamp >=
                puzzleStart(_puzzleId) + _stageDeltaStart(_stage),
            "Stage has not started yet"
        );
        _;
    }

    modifier stageEnded(uint256 _puzzleId, Stage _stage) {
        require(
            block.timestamp > puzzleStart(_puzzleId) + _stageDeltaEnd(_stage),
            "Stage has not ended yet"
        );
        _;
    }

    // reserved tokens

    function mintReservedTokens(address addr, uint256 puzzleId)
        external
        validPuzzle(puzzleId)
        stageStarted(puzzleId, Stage.GOODLIST_MINTING)
    {
        require(
            !_mintedReservedTokens[addr][puzzleId],
            "Already minted reserved tokens or no tokens reserved"
        );

        uint256 _baseId = puzzleBaseId(puzzleId);

        uint256[] storage _categoryIds = _reservations[addr][puzzleId];

        for (uint256 i = 0; i < _categoryIds.length; i++) {
            uint256 _categoryId = _categoryIds[i];
            uint256 pieceId = _baseId + _categoryId;

            _reservedAmounts[pieceId] -= 1;

            _mint(addr, pieceId, 1, "");
        }

        _mintedReservedTokens[addr][puzzleId] = true;
    }

    // community tokens

    modifier communityWallet() {
        require(
            msg.sender == owner() || msg.sender == _communityWallet,
            "Unauthorized caller"
        );
        _;
    }

    function mintCommunityTokens(uint256 puzzleId)
        external
        stageStarted(puzzleId, Stage.GOODLIST_MINTING)
        communityWallet
    {
        address addr = _communityWallet;
        require(
            msg.sender == owner() || msg.sender == addr,
            "Unauthorized caller"
        );

        uint256 amount = _communityTokensAmounts[puzzleId];

        require(amount > 0, "No tokens to mint");

        uint256 _pieceId = puzzleId * 7;

        _mint(addr, _pieceId, amount, "");

        _communityTokensAmounts[puzzleId] = 0;
        _reservedAmounts[_pieceId] -= amount;
    }

    // mint tokens left

    function mintTokensLeft(uint256 puzzleId)
        external
        communityWallet
        stageEnded(puzzleId, Stage.PUBLIC_MITING)
    {
        // only callable after public minting has ended
        uint256 baseId = puzzleBaseId(puzzleId);

        for (uint256 i = 1; i <= 7; i++) {
            uint256 pieceId = baseId + i;

            uint256 amount = _leftToMint(pieceId, categoryOf(pieceId));

            _mint(_communityWallet, pieceId, amount, "");
        }
    }

    // Pieces

    function puzzleOf(uint256 pieceId) public pure override returns (uint256) {
        return (pieceId - 1) / 7 + 1;
    }

    function categoryOf(uint256 pieceId)
        public
        pure
        override
        returns (uint256)
    {
        uint256 modulus = pieceId % 7;
        if (modulus == 0) return 7;
        return modulus;
    }

    function categoryMaximumSupply(uint256 categoryId)
        external
        pure
        override
        returns (uint256)
    {
        if (categoryId == 1) return 1;
        return _mintingMaximumSupply(categoryId);
    }

    // Internal Minting

    function _mintingMaximumSupply(uint256 _categoryId)
        private
        pure
        returns (uint256)
    {
        return (_categoryId - 1) * 7;
    }

    function leftToMint(uint256 pieceId)
        external
        view
        override
        validPiece(pieceId)
        returns (uint256)
    {
        uint256 _categoryId = categoryOf(pieceId);
        require(_categoryId > 1, "Category 1 is an auction piece");

        return _leftToMint(pieceId, _categoryId);
    }

    function _leftToMint(uint256 _pieceId, uint256 _categoryId)
        private
        view
        returns (uint256)
    {
        return
            _mintingMaximumSupply(_categoryId) -
            totalSupply(_pieceId) -
            _reservedAmounts[_pieceId];
    }

    function mintingPrice(uint256 categoryId)
        external
        pure
        override
        validCategory(categoryId)
        returns (uint256)
    {
        require(categoryId > 1, "Category 1 is an auction piece");
        return _mintingPrice(categoryId);
    }

    function _mintingPrice(uint256 _categoryId) private pure returns (uint256) {
        return 0.05 ether * (_categoryId - 1);
    }

    function _subtotal(uint256 _pieceId, uint256 amount)
        private
        pure
        returns (uint256)
    {
        return _mintingPrice(categoryOf(_pieceId)) * amount;
    }

    // Internal minting

    function _mintPiece(
        address to,
        uint256 pieceId,
        uint256 amount
    ) private validPiece(pieceId) {
        uint256 _categoryId = categoryOf(pieceId);
        require(_categoryId > 1, "Piece id is an auction piece");

        require(
            amount <= _leftToMint(pieceId, _categoryId),
            "Cannot mint that amount of tokens"
        );

        _mint(to, pieceId, amount, "");
    }

    // Public Minting

    function publicMint(
        address to,
        uint256 pieceId,
        uint256 amount
    )
        external
        payable
        override
        activeStagePeriod(pieceId, Stage.PUBLIC_MITING)
    {
        require(msg.value == _subtotal(pieceId, amount), "Invalid ETH amount");
        _mintPiece(to, pieceId, amount);
    }

    function publicMintBath(
        address to,
        uint256[] memory pieceIds,
        uint256[] memory amounts
    )
        external
        payable
        override
        activeStagePeriod(pieceIds[0], Stage.PUBLIC_MITING)
    {
        uint256 puzzleId = puzzleOf(pieceIds[0]);

        uint256 _expectedValue;
        for (uint256 i = 0; i < pieceIds.length; i++) {
            require(
                puzzleOf(pieceIds[i]) == puzzleId,
                "Cannot mint different puzzles pieces"
            );

            _expectedValue += _subtotal(pieceIds[i], amounts[i]);
            _mintPiece(to, pieceIds[i], amounts[i]);
        }
        require(msg.value == _expectedValue, "Invalid ETH amount");
    }

    // Goodlist Minting

    function _goodlistLimit(uint256 categoryId) private pure returns (uint256) {
        if (categoryId == 2 || categoryId == 3) return 1;
        if (categoryId == 4 || categoryId == 5) return 2;
        if (categoryId == 6 || categoryId == 7) return 3;
    }

    function goodlistMintBatch(
        uint256[] memory pieceIds,
        uint256[] memory amounts
    )
        external
        payable
        override
        activeStagePeriod(pieceIds[0], Stage.PUBLIC_MITING)
        onlyRole(_puzzleToRole(puzzleOf(pieceIds[0])))
    {
        uint256 puzzleId = puzzleOf(pieceIds[0]);

        uint256 _expectedValue;
        for (uint256 i = 0; i < pieceIds.length; i++) {
            require(
                puzzleOf(pieceIds[i]) == puzzleId,
                "Cannot mint different puzzles pieces"
            );

            _expectedValue += _subtotal(pieceIds[i], amounts[i]);
            _goodlistMintPiece(pieceIds[i], amounts[i]);
        }
        require(msg.value == _expectedValue, "Invalid ETH amount");
    }

    function goodlistMint(uint256 pieceId, uint256 amount)
        external
        payable
        override
        activeStagePeriod(pieceId, Stage.GOODLIST_MINTING)
        onlyRole(_puzzleToRole(puzzleOf(pieceId)))
    {
        require(msg.value == _subtotal(pieceId, amount), "Invalid ETH amount");
        _goodlistMintPiece(pieceId, amount);
    }

    function _goodlistMintPiece(uint256 _pieceId, uint256 _amount) private {
        require(
            _goodlistMinted[msg.sender][_pieceId] + _amount <=
                _goodlistLimit(categoryOf(_pieceId)),
            "Cannot mint that _amount of tokens"
        );
        _mintPiece(msg.sender, _pieceId, _amount);
        _goodlistMinted[msg.sender][_pieceId] += _amount;
    }

    // Auction

    function bid(uint256 pieceId)
        external
        payable
        override
        validPiece(pieceId)
        activeStagePeriod(pieceId, Stage.AUCTION)
        auctionPiece(pieceId)
    {
        Bid storage _bid = _highestBids[pieceId];

        uint256 _previousValue = _bid.value;
        address _previousBidder = _bid.bidder;

        require(msg.value > _previousValue, "ETH cannot be less than last bid");

        _bid.bidder = msg.sender;
        _bid.value = msg.value;

        _auctionsSafe += msg.value - _previousValue;

        // refund previous highest bid deposit
        if (_previousValue > 0)
            payable(_previousBidder).transfer(_previousValue);

        emit NewBid(pieceId, msg.sender, msg.value);
    }

    function mintAuctionedPiece(uint256 pieceId)
        external
        override
        validPiece(pieceId)
        auctionPiece(pieceId)
        stageEnded(pieceId, Stage.AUCTION)
    {
        require(totalSupply(pieceId) == 0, "Auctioned piece already minted");

        Bid memory _bid = _highestBids[pieceId];

        // update auctions safe. now bid value can be withdrawed
        _auctionsSafe -= _bid.value;

        _mint(_bid.bidder, pieceId, 1, "");
    }

    function highestBid(uint256 pieceId)
        external
        view
        returns (address bidder, uint256 amount)
    {
        Bid memory _bid = _highestBids[pieceId];
        bidder = _bid.bidder;
        amount = _bid.value;
    }

    // metadata

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "Token id does not exist");
        return
            string(abi.encodePacked(_myBaseURI, tokenId.toString(), ".json"));
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_myBaseURI, "collection.json"));
    }

    // Limit transfers

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // executed in public tranfers, not on minting
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    block.timestamp >=
                        puzzleStart(puzzleOf(ids[i])) +
                            _stageDeltaStart(Stage.PUBLIC_MITING),
                    "Cannot transfer token until its puzzle public minting stage has started"
                );
            }
        }
    }

    // Withdraw

    modifier withdrawalAddress() {
        require(
            msg.sender == owner() || msg.sender == _withdrawalAddress,
            "Caller cannot withdraw ETH"
        );
        _;
    }

    function withdrawETH() external override withdrawalAddress {
        // Active auctions ETH cannot be withdrawn
        uint256 _ethBalance = (address(this).balance - _auctionsSafe);

        uint256 _ubiDonation = (_ethBalance * 25) / 1000;

        payable(ubiBurner).transfer(_ubiDonation);

        payable(_withdrawalAddress).transfer(_ethBalance - _ubiDonation);
    }

    function withdrawERC20(address tokenAddress)
        external
        override
        withdrawalAddress
    {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_withdrawalAddress, token.balanceOf(address(this)));
    }

    // ubi burner

    function updateUBIBurner(address newContract) external onlyOwner {
        ubiBurner = newContract;
    }

    // interfaces

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }
}
