// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./TransferHelper.sol";
import "./EroNFT.sol";

contract ListingRegistry is Ownable, Pausable {
    uint16 public constant BPS_DIVISOR = 10000;
    address public immutable ERO_TOKEN_ADDRESS;
    address public immutable ERO_NFT_ADDRESS;
    address public immutable NAMESPACE_CONTRACT_ADDRESS;

    constructor(
        address _eroToken,
        address _eroNFT,
        address _namespaceContract,
        address _devAddress,
        address _daoAddress,
        uint16 _creatorRevShareBips,
        uint16 _devRevShareBips,
        uint16 _daoRevShareBips
    ) {
        require(
            _creatorRevShareBips + _devRevShareBips + _daoRevShareBips ==
                BPS_DIVISOR,
            "LR: Sum must eq 10000."
        );

        NAMESPACE_CONTRACT_ADDRESS = _namespaceContract;
        ERO_NFT_ADDRESS = _eroNFT;
        ERO_TOKEN_ADDRESS = _eroToken;

        devAddress = _devAddress;
        daoAddress = _daoAddress;

        creatorRevShareBips = _creatorRevShareBips;
        devRevShareBips = _devRevShareBips;
        daoRevShareBips = _daoRevShareBips;
    }

    /*  listingFlags valueMap: [0: userDefined0, 1: userDefined1, 2: userDefined2, 3: userDefined3, 4: listingLabel0, 5: listingLabel1, 6: reserved, 7: isActive]
        listingLabel valueLabel:
            00: Community
            01: Featured
            10: Premium
            11: Delisted
    */
    struct Listing {
        bytes1 listingFlags; // 1 byte,
        uint16 endDiscountBips; // 16 bytes
        address listingOwner; //20 bytes
        address minterToken; // 20 bytes
        uint256 listingPrice; // 32 bytes
        uint256 mintableSupply; // 32 bytes
        uint256 startBlock; // 32 bytes
        uint256 endBlock; // 32 bytes
        uint256 nonce; // 32 bytes
        uint256 startAlloc; //32 bytes
    }

    event ListingAdded(Listing newListing);

    event FlagsUpdated(
        bytes32 listingId,
        address executedBy,
        bytes1 prev,
        bytes1 current
    );

    event ListingUnitPriceUpdated(
        uint256 oldValue,
        uint256 newValue
    );

    event RevShareBipsUpdated(
        uint16 prevCreatorRevShareBips,
        uint16 prevDevRevShareBips,
        uint16 prevDaoRevShareBips,
        uint16 curCreatorRevShareBips,
        uint16 curDevRevShareBips,
        uint16 curDaoRevShareBips
    );

    event DevAddressUpdated(address prevDevAddress, address curDevAddress);
    event DaoAddressUpdated(address prevDaoAddress, address curDaoAddress);
    event ERC20Whitelisted(address erc20Address);

    uint16 public creatorRevShareBips;
    uint16 public devRevShareBips;
    uint16 public daoRevShareBips;

    address public devAddress;
    address public daoAddress;

    uint256 public lastAllocatedIndex;
    uint256 public listingUnitPrice;

    mapping(address => bool) public erc20Whitelist;
    mapping(bytes32 => Listing) public registry;
    mapping(address => mapping(address => uint256)) public claimableERC20;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhitelistERC20(address _erc20Address) public onlyOwner {
        erc20Whitelist[_erc20Address] = true;

        emit ERC20Whitelisted(_erc20Address);
    }

    function removeWhitelistERC20(address _erc20Address) public onlyOwner {
        erc20Whitelist[_erc20Address] = false;

        emit ERC20Whitelisted(_erc20Address);
    }

    function setListingUnitPrice(uint256 val) public onlyOwner {
        emit ListingUnitPriceUpdated(listingUnitPrice, val);

        listingUnitPrice = val;
    }

    function setRevShareBips(
        uint16 _creatorRevShareBips,
        uint16 _devRevShareBips,
        uint16 _daoRevShareBips
    ) public onlyOwner {
        require(
            _creatorRevShareBips + _devRevShareBips + _daoRevShareBips ==
                BPS_DIVISOR,
            "LR: Sum !eq 10000."
        );

        emit RevShareBipsUpdated(
            creatorRevShareBips,
            devRevShareBips,
            daoRevShareBips,
            _creatorRevShareBips,
            _devRevShareBips,
            _daoRevShareBips
        );
        creatorRevShareBips = _creatorRevShareBips;
        devRevShareBips = _devRevShareBips;
        daoRevShareBips = _daoRevShareBips;
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        require(_devAddress != address(0), "LR: can't set to zero address.");

        emit DevAddressUpdated(devAddress, _devAddress);
        devAddress = _devAddress;
    }

    function setDaoAddress(address _daoAddress) public onlyOwner {
        require(_daoAddress != address(0), "LR: can't set to zero address.");

        emit DaoAddressUpdated(daoAddress, _daoAddress);
        daoAddress = _daoAddress;
    }

    function getListingId(string memory _namespace, string memory _ctx) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _namespace,
            _ctx
        ));
    }

    function _getNamespaceOwner(string memory _namespace)
    internal view returns (address) {
        bytes32 _tokenId = keccak256(abi.encodePacked(_namespace));

        return IERC721(NAMESPACE_CONTRACT_ADDRESS).ownerOf(uint256(_tokenId));
    }

    function addListing(
        string memory _namespace,
        string memory _ctx,
        uint16 _endDiscountBips,
        address _mintingToken,
        uint256 _initialPrice,
        uint256 _mintableSupply,
        uint256 _startBlock,
        uint256 _listingDuration,
        bytes1 _listingFlags
    ) public whenNotPaused {
        require(_getNamespaceOwner(_namespace) == _msgSender(), "LR: Namespace unauthorized.");
        require(_startBlock >= block.number, "LR: Invalid _startBlock.");
        require(_listingDuration != 0, "LR: Invalid _listingDuration.");
        require(EroNFT(ERO_NFT_ADDRESS).owner() == address(this), "LR: Contract isn't owner");
        require(_endDiscountBips <= 10000, "LR: endDiscountBips > 10000.");
        require(
            erc20Whitelist[_mintingToken],
            "LR: ERC20 Not whitelisted."
        );

        bytes32 listingId = getListingId(_namespace, _ctx);
        require(
            !_getBoolean(registry[listingId].listingFlags, 7),
            "LR: Listing exists."
        );

        // avoid junk listing
        TransferHelper.safeTransferFrom(ERO_TOKEN_ADDRESS, _msgSender(), daoAddress, _mintableSupply * listingUnitPrice);

        // clear hi-nybble, reserved for DAO governable flags
        // rightmost bit of listingFlags reserved to indicate listing has been initialized (avoid overwriting)
        bytes1 initializedListingFlags = (bytes1(0x0f) & _listingFlags) | bytes1(0x80);

        Listing memory listing = Listing(
            initializedListingFlags,
            _endDiscountBips,
            _msgSender(),
            _mintingToken,
            _initialPrice,
            _mintableSupply,
            _startBlock,
            _startBlock + _listingDuration,
            0,
            lastAllocatedIndex
        );

        emit ListingAdded(listing);
        registry[listingId] = listing;

        lastAllocatedIndex = lastAllocatedIndex + _mintableSupply;
    }

    function setListingFlags(bytes32 _listingId, bytes1 _listingFlags)
        public
    {
        Listing storage listing = registry[_listingId];
        require(_getBoolean(listing.listingFlags, 7), "LR: Listing inactive.");
        require(
            _msgSender() == owner() || _msgSender() == listing.listingOwner,
            "LR: Unauthorized."
        );
        if (_msgSender() == owner()) {
            emit FlagsUpdated(
                _listingId,
                _msgSender(),
                listing.listingFlags,
                _listingFlags
            );
            listing.listingFlags = _listingFlags;
        } else if (_msgSender() == listing.listingOwner) {
            emit FlagsUpdated(
                _listingId,
                _msgSender(),
                listing.listingFlags,
                listing.listingFlags | (_listingFlags & bytes1(0x0f))
            );
            listing.listingFlags =
                listing.listingFlags |
                (_listingFlags & bytes1(0x0f));
        }
    }

    function getListingFlags(bytes32 _listingId)
        public
        view
        returns (bytes1)
    {
        Listing memory listing = registry[_listingId];

        return listing.listingFlags;
    }

    function _getBoolean(bytes1 _packedBools, uint8 _index)
        internal
        pure
        returns (bool)
    {
        uint8 flag = (uint8(_packedBools) >> _index) & uint8(1);
        return (flag > 0 ? true : false);
    }

    function mintNFT(
        bytes32 _listingId,
        uint256 _amount
    ) public whenNotPaused {
        require(
            hasStarted(_listingId) && !hasEnded(_listingId),
            "LR: Listing is not active."
        );
        Listing storage listing = registry[_listingId];

        uint256 currentPrice = getCurrentPrice(_listingId);

        require(
            _amount > 0 && _amount >= currentPrice,
            "LR: amount < currentPrice"
        );

        uint256 n = _amount / currentPrice;

        require(listing.mintableSupply >= n, "LR: Not enough mintableSupply.");
        listing.mintableSupply = listing.mintableSupply - n;

        uint256 contractCurrentERC20Balance = IERC20(listing.minterToken)
            .balanceOf(address(this));

        // only need to transfer required amount
        TransferHelper.safeTransferFrom(
            listing.minterToken,
            _msgSender(),
            address(this),
            n * currentPrice
        );

        require(
            (IERC20(listing.minterToken).balanceOf(address(this)) >
                contractCurrentERC20Balance),
            "LR: Balance not increased."
        );

        _addRevClaimables(
            _listingId,
            listing.minterToken,
            n * currentPrice
        );

        for (uint256 i = 0; i < n; i++) {

            uint256 tokenId = uint256(
                keccak256(
                    abi.encodePacked(
                        _listingId, listing.startAlloc + listing.nonce
                    )
                )
            );

            listing.nonce += 1;

            EroNFT(ERO_NFT_ADDRESS).safeMint(_msgSender(), tokenId);
        }
    }

    function _addRevClaimables(
        bytes32 _listingId,
        address _erc20Token,
        uint256 _value
    ) internal {
        address creatorAddress = registry[_listingId].listingOwner;

        claimableERC20[_erc20Token][creatorAddress] +=
            (_value * creatorRevShareBips) /
            BPS_DIVISOR;
        claimableERC20[_erc20Token][devAddress] +=
            (_value * devRevShareBips) /
            BPS_DIVISOR;
        claimableERC20[_erc20Token][daoAddress] +=
            (_value * daoRevShareBips) /
            BPS_DIVISOR;
    }

    function claimToken(address _erc20Address, uint256 _amount) public {
        require(
            claimableERC20[_erc20Address][_msgSender()] >= _amount,
            "LR: claimable < amount"
        );

        claimableERC20[_erc20Address][_msgSender()] -= _amount;
        require(
            IERC20(_erc20Address).transfer(_msgSender(), _amount),
            "LR: token transfer failed"
        );
    }

    function getCurrentPrice(bytes32 _listingId)
        public
        view
        returns (uint256)
    {
        Listing memory listing = registry[_listingId];
        require(
            listing.listingFlags >= bytes1(0x80),
            "LR: Listing not found."
        );

        uint256 discount = _calculateDiscount(
            listing.listingPrice,
            listing.endDiscountBips,
            listing.startBlock,
            listing.endBlock,
            block.number
        );
        uint256 currentPrice = listing.listingPrice - discount;

        return currentPrice;
    }

    function getNextPrice(bytes32 _listingId)
        public
        view
        returns (uint256)
    {
        Listing memory listing = registry[_listingId];
        require(
            listing.listingFlags >= bytes1(0x80),
            "LR: Listing not found."
        );

        uint256 discount = _calculateDiscount(
            listing.listingPrice,
            listing.endDiscountBips,
            listing.startBlock,
            listing.endBlock,
            block.number + 1
        );
        uint256 nextPrice = listing.listingPrice - discount;

        return nextPrice;
    }

    function _calculateDiscount(
        uint256 _initialPrice,
        uint256 _endDiscountBips,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _currentBlock
    ) internal pure returns (uint256) {
        require(_endDiscountBips <= 10000, "LR: _endDiscountBips > 10000.");
        require(_startBlock < _endBlock, "LR: _startBlock >= _endBlock.");
        if (_currentBlock > _endBlock) {
            return (_initialPrice * _endDiscountBips) / BPS_DIVISOR;
        }

        if (_currentBlock < _startBlock) {
            return 0;
        }

        return
            ((_initialPrice *
                _endDiscountBips *
                (_currentBlock - _startBlock)) / (_endBlock - _startBlock)) /
            BPS_DIVISOR;
    }

    function hasStarted(bytes32 _listingId) public view returns (bool) {
        Listing memory listing = registry[_listingId];

        return block.number >= listing.startBlock;
    }

    function hasEnded(bytes32 _listingId) public view returns (bool) {
        Listing memory listing = registry[_listingId];

        return block.number >= listing.endBlock;
    }

    function transferNFTOwnership(address _to)
        public
        onlyOwner
    {
        EroNFT(ERO_NFT_ADDRESS).transferOwnership(_to);
    }
}
