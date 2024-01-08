// SPDX-License-Identifier: MIT

//  __    __  _______
// /  |  /  |/       \
// $$ |  $$ |$$$$$$$  |  ______   __     __  ______    ______    _______
// $$  \/$$/ $$ |__$$ | /      \ /  \   /  |/      \  /      \  /       |
//  $$  $$<  $$    $$<  $$$$$$  |$$  \ /$$//$$$$$$  |/$$$$$$  |/$$$$$$$/
//   $$$$  \ $$$$$$$  | /    $$ | $$  /$$/ $$    $$ |$$ |  $$/ $$      \
//  $$ /$$  |$$ |  $$ |/$$$$$$$ |  $$ $$/  $$$$$$$$/ $$ |       $$$$$$  |
// $$ |  $$ |$$ |  $$ |$$    $$ |   $$$/   $$       |$$ |      /     $$/
// $$/   $$/ $$/   $$/  $$$$$$$/     $/     $$$$$$$/ $$/       $$$$$$$/
//

pragma solidity ^0.8.0;



import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SingleRoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./MintCooldown.sol";

/**
 * @title XRaver contract
 * @dev Extends ERC721 Enumerable Non-Fungible Token Standard basic implementation
 */
contract XRaver is
    MintCooldown,
    ERC721Enumerable,
    Ownable,
    SingleRoyaltiesV2Impl
{
    uint256 public immutable MAX_XRAVERS;
    uint256 public immutable MAX_PURCHASE_COUNT;
    uint256 public constant RESERVED_MINT_LIMIT = 50;
    uint256 public constant RESERVED_XRAVERS = 100;
    uint256 public constant PRICE_MUTATE_DELTA = 10000000000000000; // 0.01 ETH
    uint256 public constant XRAVER_PRICE = 40000000000000000; // 0.04 ETH
    uint96 public constant ROYALTY = 1000; // 10%
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public constant SHARE_DENOMINATOR = 10000;

    bool public saleIsActive;
    string public uri;
    uint256 private _reserveCursor;
    uint256 private _mutateCursor;
    mapping(uint256 => uint256) private _mutateIndexer;
    bool public mutateSet;

    struct StakeHolder {
        address payable addr;
        uint256 share;
    }
    StakeHolder[] private _stakeHolders;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 _maxXravers,
        uint256 _maxPurchaseCount,
        address payable royaltyOwner_,
        StakeHolder[] memory stakeHolders_
    ) ERC721(name_, symbol_) {
        require(_maxXravers > RESERVED_XRAVERS, "XRaver: INSUFFICIENT_COUNT");
        MAX_XRAVERS = _maxXravers;
        MAX_PURCHASE_COUNT = _maxPurchaseCount;
        uri = uri_;
        _setOwnerRoyalties(royaltyOwner_);
        _updateStakeHolders(stakeHolders_);
    }

    function _updateStakeHolders(StakeHolder[] memory stakeHolders_) private {
        uint256 totalShare;

        for (uint256 i = 0; i < stakeHolders_.length; i++) {
            StakeHolder memory sh = stakeHolders_[i];
            totalShare += sh.share;
            _stakeHolders.push(sh);
        }
        require(totalShare <= SHARE_DENOMINATOR, "XRaver: WRONG_SHARES");
    }

    // NOTE: You need to understand what u are doing
    // executed only once
    function setMutates(
        uint256[] calldata mutateIndexes_,
        uint256[] calldata mutateCounts_
    ) public onlyOwner {
        require(!mutateSet, "XRaver: ALREADY_SET");
        require(mutateIndexes_.length != 0, "XRaver: EMPTY_LIST");
        require(
            mutateIndexes_.length == mutateCounts_.length,
            "XRaver: WORNG_LENGTH"
        );

        for (uint256 i = 0; i < mutateIndexes_.length; i++) {
            _mutateIndexer[mutateIndexes_[i]] = mutateCounts_[i];
        }
        mutateSet = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getStakeHolders() public view returns (address[] memory addrs) {
        addrs = new address[](_stakeHolders.length);
        for (uint256 i = 0; i < _stakeHolders.length; i++) {
            addrs[i] = _stakeHolders[i].addr;
        }
    }

    /**
     * Withdraw ethers from the mint
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        for (uint256 i = 0; i < _stakeHolders.length; i++) {
            StakeHolder memory sh = _stakeHolders[i];
            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = sh.addr.call{
                value: (amount * sh.share) / SHARE_DENOMINATOR
            }("");
            require(success, "XRaver: SEND_REVERT");
        }
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function calculatePrice(uint256 numberOfTokens)
        public
        view
        returns (uint256 price)
    {
        require(numberOfTokens != 0, "XRaver: MINT_MIN_AT_LEAST_ONE");
        uint256 supply = totalSupply();
        uint256 cursor = _mutateCursor; // copy
        for (uint256 i = 0; i < numberOfTokens; i++) {
            // mutate price if it get new cycle
            uint256 indexer = _mutateIndexer[cursor];
            if (indexer != 0 && (supply + i) % indexer == 0) {
                cursor++;
            }
        }
        price = numberOfTokens * (XRAVER_PRICE + PRICE_MUTATE_DELTA * cursor);
    }

    /**
     * Mints X Ravers
     */
    function mint(uint256 numberOfTokens)
        public
        payable
        onCooldown(MAX_PURCHASE_COUNT, numberOfTokens)
    {
        require(saleIsActive, "XRaver: SALE_NOT_ACTIVE");
        require(numberOfTokens != 0, "XRaver: MINT_MIN_AT_LEAST_ONE");
        require(
            totalSupply() >= RESERVED_XRAVERS,
            "XRaver: RESERVE_NOT_MINTED"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_XRAVERS,
            "XRaver: TOTAL_SUPPLY_OVERFLOW"
        );
        uint256 price;

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            // mutate price if it get new cycle
            uint256 indexer = _mutateIndexer[_mutateCursor];
            if (indexer != 0 && (supply + i) % indexer == 0) {
                _mutateCursor++;
            }
            price += XRAVER_PRICE + PRICE_MUTATE_DELTA * _mutateCursor;
            _safeMint(_msgSender(), supply + i);
        }

        require(price <= msg.value, "XRaver: NOT_ENOUGH_ETHER");

        // return rest amount
        if (price < msg.value) {
            payable(_msgSender()).transfer(msg.value - price);
        }
    }

    /**
     * Get royalty info
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = _getRoyalties();
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    /**
     * Change owner for royalty, expensive transaction
     */
    function changeRoyaltyOwner(address payable newRoyaltyOwner)
        public
        onlyOwner
    {
        require(newRoyaltyOwner != address(0), "XRaver: ZERO_OWNER");
        _updateAccountRoyalties(newRoyaltyOwner);
    }

    /**
     * Set some XRavers aside for fantom, dev team and promo
     */
    function reserve() external onlyOwner {
        uint256 supply = totalSupply();

        require(supply < RESERVED_XRAVERS, "XRaver: FULL_RESERVE");
        for (uint256 i = 0; i < RESERVED_MINT_LIMIT; i++) {
            _safeMint(_msgSender(), supply + i);
        }

    }

    /**
     * Modify URI
     */
    function setBaseURI(string memory uri_) external onlyOwner {
        uri = uri_;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _setOwnerRoyalties(address royaltyAddress) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = ROYALTY;
        _royalties[0].account = payable(royaltyAddress);
        _saveRoyalties(_royalties);
    }
}
