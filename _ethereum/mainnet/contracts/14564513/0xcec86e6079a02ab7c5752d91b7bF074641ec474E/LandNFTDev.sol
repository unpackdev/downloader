
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./ERC165.sol";

import "./console.sol";

contract LandNFTDev is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, IERC2981 {
    // using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint8;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _counter;


    bool public saleActive = false;

    string private baseURI;
    string private tokenSuffixURI;
    string private contractMetadata = 'contract.json';

    uint256 public constant MINT_BATCH_LIMIT = 5; // Max number of Tokens minted in a txn

    address private hokWithdrawAddress = address(0x8DeC167C4B75Ce5C2C369B74528fF53f3Ba514a4);
    address private saleContractAdddress;

    mapping (uint256 => uint256) public _tokens;

    event SaleStatusChange(address indexed issuer, bool indexed status);
    event ContractWithdraw(address indexed initiator, address indexed hokWithdrawAddress, uint256 amount);

    uint16 internal royalty = 500; // base 10000, 5%
    uint16 public constant BASE = 10000;

    constructor(string memory _baseContractURI, string memory _tokenSuffixURI) ERC721("Po Di Ea Dev", "PDE") {
        baseURI = _baseContractURI;
        tokenSuffixURI = _tokenSuffixURI;
    }

    function mintNFT(address recipient, uint8 landType, uint256 numTokens)
    public
    {
        // require(msg.sender == saleContractAdddress || msg.sender == hokMinterAddress, "Not allowed");
        require(msg.sender == saleContractAdddress, "Not allowed");

        for(uint256 i = 0; i < numTokens; i++){
            _tokenIds.increment();
            _tokens[_tokenIds.current()] = landType;
            _counter.increment();

            _safeMint(recipient, _tokenIds.current());
        }
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-safeTransferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function safeTransferFrom( address from, address to, uint256 id, bytes memory _data)
    public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.safeTransferFrom(from,to,id, _data);
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-safeTransferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function safeTransferFrom( address from, address to, uint256 id)
    public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.safeTransferFrom(from,to,id);
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-transferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function transferFrom( address from, address to, uint256 id)
    public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.transferFrom(from,to,id);
    }


    function setBaseURI(string memory baseContractURI) public onlyOwner {
        baseURI = baseContractURI;
    }

    // function setSaleContractAddress(address _saleContractAddress) public onlyOwner {
    //     saleContractAdddress = _saleContractAddress;
    // }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseContractURI = _baseURI();

        // TODO: change URI based on the _tokens landType, for now keep this
        return bytes(baseContractURI).length > 0 ? string(abi.encodePacked(baseContractURI, '/', _tokens[tokenId].toString(), '/', tokenId.toString(), tokenSuffixURI)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev returns the base contract metadata json object
     * this metadata file is used by OpenSea see {https://docs.opensea.io/docs/contract-level-metadata}
     *
     */
    function contractURI() public view returns (string memory) {
        string memory baseContractURI = _baseURI();
        return string(abi.encodePacked(baseContractURI, contractMetadata));
    }

    /**
     * @dev Changes the sale status 'saleActive' from active to not active and vice versa
     *
     * Only Contract Owner can execute
     *
     * Emits a {SaleStatusChange} event.
     */
    function changeSaleStatus() public onlyOwner{
        // require(msg.sender == saleContractAdddress, "Not Allowed");
        saleActive = !saleActive;
        emit SaleStatusChange(msg.sender, saleActive);
    }

    function getSaleStatus() public view returns(bool) {
        return saleActive;
    }

    /**
     * @dev withdraws the specified '_amount' from contract balance and send it to the withdraw Addresses based on split ratio.
     *
     * Emits a {ContractWithdraw} event.
     * @param _amount - Amount to be withdrawn
     */
    function withdraw(uint256 _amount) public nonReentrant {
        require(msg.sender == hokWithdrawAddress, "Not allowed");

        uint256 balance = address(this).balance;
        require(_amount <= balance,"Insufficient funds");

        bool success;
        (success, ) = payable(hokWithdrawAddress).call{value: _amount}('');
        require(success, 'Withdraw Failed');

        emit ContractWithdraw(msg.sender, hokWithdrawAddress, _amount);
    }


    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }

    /// @dev set the royalty
    /// @param _royalty the royalty in base 10000, 500 = 5%
    function setRoyalty(uint16 _royalty) public virtual onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of hok address
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(hokWithdrawAddress, _amount);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}