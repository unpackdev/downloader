// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Sister.sol";

contract SisterFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;

    bool public isSaleActive = false;

    string public factoryCID;

    uint256 public MAX_RESERVED = 40;
    uint256 public CURRENT_RESERVED = 0;

    // define this based on array of options
    uint256 NUM_OPTIONS = 4;

    uint256 SINGLE_SISTER_OPTION = 1;
    uint256 FIVE_SISTER_OPTION = 2;
    uint256 TEN_SISTER_OPTION = 3;
    uint256 TWENTY_SISTER_OPTION = 4;

    uint256 SINGLE_SISTER_OPTION_AMOUNT = 1;
    uint256 FIVE_SISTER_OPTION_AMOUNT = 5;
    uint256 TEN_SISTER_OPTION_AMOUNT = 10;
    uint256 TWENTY_SISTER_OPTION_AMOUNT = 20;

    mapping(uint256 => uint256) public bundleAmounts;

    constructor(
        address _proxyRegistryAddress,
        address _nftAddress,
        string memory _factoryCID
    ) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        factoryCID = _factoryCID;

        bundleAmounts[SINGLE_SISTER_OPTION] = SINGLE_SISTER_OPTION_AMOUNT;
        bundleAmounts[FIVE_SISTER_OPTION] = FIVE_SISTER_OPTION_AMOUNT;
        bundleAmounts[TEN_SISTER_OPTION] = TEN_SISTER_OPTION_AMOUNT;
        bundleAmounts[TWENTY_SISTER_OPTION] = TWENTY_SISTER_OPTION_AMOUNT;

        fireTransferEvents(address(0), owner());
    }

    function name() external pure override returns (string memory) {
        return "1,989 Sisters Sale";
    }

    function symbol() external pure override returns (string memory) {
        return "1989-Sisters-Sale";
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public view override returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 1; i <= NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function toggleSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setFullMetadataRevealTimestamp(uint256 _daysFromNowUntilReveal)
        public
        onlyOwner
    {
        Sister sister = Sister(nftAddress);
        sister.setFullMetadataRevealTimestamp(_daysFromNowUntilReveal);
    }

    /*
     * Reserve sisters for collaborators
     */
    function mintReserved(uint256 _optionId, address _toAddress)
        public
        onlyOwner
    {
        require(
            !isSaleActive,
            "Cannot mint reserved sisters while sale is active."
        );

        bool canMintReserved = (CURRENT_RESERVED + bundleAmounts[_optionId]) <=
            MAX_RESERVED;
        require(
            canMintReserved,
            "Cannot Mint: minting would exceed MAX_RESERVED"
        );

        require(
            canMint(_optionId),
            "Cannot Mint: Invalid Sister Package Option or No Sister Tokens Left"
        );

        Sister sister = Sister(nftAddress);
        sister.mintTo(_toAddress, bundleAmounts[_optionId]);

        CURRENT_RESERVED = CURRENT_RESERVED + bundleAmounts[_optionId];
    }

    function mint(uint256 _optionId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );

        require(isSaleActive, "Cannot mint: sale must be active.");

        require(
            canMint(_optionId),
            "Cannot Mint: Invalid Sister Package Option or No Sister Tokens Left"
        );

        Sister sister = Sister(nftAddress);
        sister.mintTo(_toAddress, bundleAmounts[_optionId]);
    }

    function canMint(uint256 _optionId) public view override returns (bool) {
        if (_optionId == 0 || _optionId > NUM_OPTIONS) {
            return false;
        }

        Sister sister = Sister(nftAddress);

        uint256 currentSisterSupply = sister.tokenCount();
        uint256 numItemsAllocated = bundleAmounts[_optionId];

        return
            currentSisterSupply <= (sister.totalSupply() - numItemsAllocated);
    }

    function _baseURI() internal view returns (string memory) {
        return string(abi.encodePacked("ipfs://", factoryCID));
    }

    function tokenURI(uint256 _optionId)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_baseURI(), "/", Strings.toString(_optionId))
            );
    }

    /*
     * Only for emergencies – not totally "decentralized", but
     * calling freezeMetadataPermanently will prevent this from being useable
     */
    function emergencyOverrideSisterMasterCID(string memory _metadataCID)
        public
        onlyOwner
    {
        Sister sister = Sister(nftAddress);

        require(
            !sister.metadataIsPermanentlyFrozen(),
            "Cannot Override Sister Master CID: Metadata is permanently frozen."
        );

        sister.emergencyOverrideMasterCID(_metadataCID);
    }

    /*
     * After we are sure metadata is sound, call this to prevent changing it forever.
     */
    function freezeSisterMetadataPermanently() public onlyOwner {
        Sister sister = Sister(nftAddress);

        require(
            !sister.metadataIsPermanentlyFrozen(),
            "Cannot Freeze Sister Metadata: Metadata is already permanently frozen."
        );

        sister.freezeMetadataPermanently();
    }

    // [po] IS THIS public A CONCERN without onlyOwner?

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
