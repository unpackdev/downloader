// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
//import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

import "./ITinyFamiliar.sol";
import "./ITinyFamiliarMetadata.sol";

contract TinyFamiliar is
Initializable,
ERC721EnumerableUpgradeable,
OwnableUpgradeable,
PausableUpgradeable,
ITinyFamiliar,
ITinyFamiliarMetadata
{
    //    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    //    CountersUpgradeable.Counter private _tokenIdTracker;
    uint256 public TF_MAX;

    uint256 public mintPrice;
    uint256 public whiteListMintPrice;

    bool public isActive;
    bool public isPresaleActive;
    bool public isPrivateSaleActive;
    string public baseExtension;
    string public proof;

    mapping(address => uint256) private _presaleList;
    mapping(address => uint256) private _presaleClaimed;

    mapping(address => bool) private _privateSaleList;
    mapping(address => uint256) private _privateSaleClaimed;

    // @dev For OpenSea?
    string private _contractURI;

    string private _tokenBaseURI;

    // owners
    address t1;
    address t2;

    function initialize(
        string memory initBaseURI
//    ,
//            address initT1,
//            address initT2
    ) public initializer {
        __ERC721_init("Tiny Familiars", "TFT");
        __ERC721Enumerable_init();
        __Ownable_init();
        __Pausable_init();

        TF_MAX = 144;

        _tokenBaseURI = initBaseURI;
        _contractURI = "https://tinyfamiliars.com/tinyFamiliars.json";

//                t1 = initT1;
        t1 = 0x1496961c0DA108BE9689407EDAa90cf417fdC41C; // 25%
//
//                t2 = initT2;
        t2 = 0xeA2a9ca3d62BEF63Cf562B59c5709B32Ed4c0eca; // 75%

        mintPrice = 0.08 ether;
        whiteListMintPrice = 0.06 ether;

        isActive = false;
        isPresaleActive = false;
        isPrivateSaleActive = false;
        baseExtension = ".json";
    }

    // << Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    //    internal
    //    whenNotPaused
    //    override
    //    {
    //        super._beforeTokenTransfer(from, to, tokenId);
    //    }
    // Pausable >>


    // << Presale functionality
    function addToPresale(address[] calldata addresses, uint256 numAllowedToMint)
    external
    override
    onlyOwner
    {
        require(numAllowedToMint > 0, "numAllowedToMint must be greater than 0");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = numAllowedToMint;
            /**
             * @dev We don't want to reset _presaleClaimed count
             * if we try to add someone more than once.
             */
            _presaleClaimed[addresses[i]] > 0
            ? _presaleClaimed[addresses[i]]
            : 0;
        }
    }

    function presaleMintQty(address addr) external view override returns (uint256) {
        return _presaleList[addr] > 0 ? _presaleList[addr] : 0;
    }

    function onPresaleList(address addr) external view override returns (bool) {
        return _presaleList[addr] > 0;
    }

    function removeFromPresale(address[] calldata addresses)
    external
    override
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _presaleClaimed numbers.
            _presaleList[addresses[i]] = 0;
        }
    }

    /**
     * @dev We want to be able to distinguish tokens bought during isPresaleActive
     */
    function presaleClaimedBy(address owner)
    external
    view
    override
    returns (uint256)
    {
        require(owner != address(0), "Zero address not on Allow List");

        return _presaleClaimed[owner];
    }
    // Presale functionality >>

    // << PrivateSale functionality
    function addToPrivateSale(address[] calldata addresses)
    external
    override
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _privateSaleList[addresses[i]] = true;
            /**
             * @dev We don't want to reset _privateSaleClaimed count
             * if we try to add someone more than once.
             */
            _privateSaleClaimed[addresses[i]] > 0
            ? _privateSaleClaimed[addresses[i]]
            : 0;
        }
    }

    function onPrivateSaleList(address addr) external view override returns (bool) {
        return _privateSaleList[addr];
    }

    function removeFromPrivateSale(address[] calldata addresses)
    external
    override
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _presaleClaimed numbers.
            _privateSaleList[addresses[i]] = false;
        }
    }

    /**
     * @dev We want to be able to distinguish tokens bought during isPresaleActive
     */
    function privateSaleClaimedBy(address owner)
    external
    view
    override
    returns (uint256)
    {
        require(owner != address(0), "Zero address not on Allow List");

        return _privateSaleClaimed[owner];
    }
    // PrivateSale functionality >>

    function mintPublic(uint256 numberOfTokens)
    external
    whenNotPaused
    payable
    override
    {
        require(isActive, "Contract is not active");
        require(!isPrivateSaleActive, "Private Sale only");
        require(!isPresaleActive, "Presale only");
//        require(totalSupply() < TF_MAX, "All tokens have been minted");
        require(
            totalSupply() + numberOfTokens <= TF_MAX,
            "Not enough tokens left to mint"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintPresale(uint256 numberOfTokens)
    external
    payable
    override
    whenNotPaused
    {
        require(isActive, "Contract is not active");
        require(isPresaleActive, "Presale is not active");
//        require(totalSupply() < TF_MAX, "All tokens have been minted");
        require(numberOfTokens + _presaleClaimed[msg.sender] <= _presaleList[msg.sender], "You cannot mint any more Presale tokens");
        require(
            totalSupply() + numberOfTokens <= TF_MAX,
            "Not enough tokens left to mint"
        );
        require(
            whiteListMintPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
             * We don't want our tokens to start at 0 but at 1.
             */
            uint256 tokenId = totalSupply() + 1;
            _presaleClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintPrivateSale()
    external
    payable
    override
    whenNotPaused
    {
        require(isActive, "Contract is not active");
        require(isPrivateSaleActive, "Private sale is not active");
        require(_privateSaleList[msg.sender], "You are not on the Allow List");
//        require(totalSupply() < TF_MAX, "All tokens have been minted");
        require(_privateSaleClaimed[msg.sender] < 1, "Exceeded max available to purchase");
        require(
            totalSupply() + 1 <= TF_MAX,
            "Not enough tokens left to mint"
        );
        require(
            mintPrice <= msg.value,
            "ETH amount is not sufficient"
        );

        //        for (uint256 i = 0; i < numberOfTokens; i++) {
        /**
         * We don't want our tokens to start at 0 but at 1.
         */
        uint256 tokenId = totalSupply() + 1;
        _privateSaleClaimed[msg.sender] += 1;
        _safeMint(msg.sender, tokenId);
        //        }
    }

    /**
     * @dev For OpenSea?
     * a contractURI method to your ERC721 or ERC1155 contract that returns a URL for the storefront-level metadata for your contract.
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory currentBaseURI = _baseURI();
        return
        string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                baseExtension
            )
        );
    }

    function walletOfOwner(address _owner)
    public
    view
    override
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Admin methods
    function ownerMint(uint256 quantity) external override onlyOwner {
//        require(totalSupply() < TF_MAX, "All tokens have been minted");
        require(
            totalSupply() + quantity <= TF_MAX,
            "Not enough tokens left to mint"
        );
        for (uint256 i = 0; i < quantity; i++) {
            _mintInternal(msg.sender);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
//        require(totalSupply() < TF_MAX, "All tokens have been minted");
        require(
            totalSupply() + to.length <= TF_MAX,
            "Not enough tokens left to gift"
        );

        for (uint256 i = 0; i < to.length; i++) {
            /// @dev We don't want our tokens to start at 0 but at 1.
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsPresaleActive(bool _isActive) external override onlyOwner
    {
        isPresaleActive = _isActive;
        isActive = _isActive;
        if (_isActive) {
            isPrivateSaleActive = false;
        }
    }

    function setIsPrivateSaleActive(bool _isActive) external override onlyOwner
    {
        isPrivateSaleActive = _isActive;
        if (_isActive) {
            isActive = _isActive;
            isPresaleActive = false;
        }
    }

    //    function currentState()
    //    public
    //    view
    //    returns (bool[3] memory) {
    //        return [isActive, isPresaleActive, isPrivateSaleActive];
    //    }
    //
        function setProof(string calldata proofString)
        external
        override
        onlyOwner
        whenNotPaused
        {
            proof = proofString;
        }

    function setContractURI(string calldata URI)
    external
    override
    onlyOwner
    whenNotPaused
    {
        _contractURI = URI;
    }


    function setTFMAX(uint256 _TF_MAX)
    external
    onlyOwner
    {
        TF_MAX =  _TF_MAX;
    }

    function setBaseURI(string calldata URI)
    external
    override
    onlyOwner
    whenNotPaused
    {
        _tokenBaseURI = URI;
    }


    function emergencyWithdraw() external payable override {
        require(msg.sender == t1, "Wrong sender address");
        (bool success,) = payable(t1).call{value : address(this).balance}("");
        require(success);
    }

    function withdrawForAll() external payable override onlyOwner {
        uint256 _quarter = address(this).balance / 4;
        require(payable(t1).send(_quarter));
        require(payable(t2).send(_quarter * 3));
    }

    function setMintPrice(uint256 price) external override onlyOwner {
        mintPrice = price;
    }


    function setWhiteListMintPrice(uint256 price) external override onlyOwner {
        whiteListMintPrice = price;
    }

    function setBaseExtension(string memory _newBaseExtension)
    public
    onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mintInternal(address owner) private {
        uint256 tokenId = totalSupply() + 1;
        //TF_OWNER + TF_GIFT + totalPublicSupply + 1;
        //        totalTokenSupply += 1;
        _safeMint(owner, tokenId);
    }

    function isUpgrade()
    external pure returns (bool){
        return false;
    }
}