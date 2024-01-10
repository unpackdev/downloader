// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

contract StrawhatzMintPassport is ERC1155, IERC2981, Ownable {

    function withdrawToOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no balance");
        payable(owner()).transfer(balance);
    }

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _royaltyRecipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyRecipient, (_salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    uint256 public constant PRESALE_TOKEN_ID = 1;
    uint256 public constant PUBLIC_TOKEN_ID = 2;
    uint256 public constant PRESALE_TOKEN_PRICE = 0.123 ether;
    uint256 public constant PUBLIC_TOKEN_PRICE = 0.333 ether;
    uint256 public constant TOTAL_MAX_SUPPLY = 3333;
    uint256 public constant MAX_BUY_COUNT_PER_USER = 3;

    address public nftAddress;
    string private baseTokenURI;

    address private _royaltyRecipient;

    mapping (address=>uint256) private WHITELIST;

    /* state */
    uint256 public mintedPasses;
    bool public publicSaleEnabled = false;
    bool public presaleEnabled = false;

    /* errors */
    string public constant UNAUTHORIZED = "UNAUTHORIZED";
    string public constant PAYMENT_AMOUNT_INCORRECT = "PAYMENT AMOUNT INCORRECT";
    string public constant PASSPORT_EMPTY = "PASSPORT ACCOUNT IS EMPTY";
    string public constant NOT_ENOUGH_PASSPORTS = "NOT ENOUGH PASSPORTS";
    string public constant PRESALE_RESTRICTED = "PRESALE TOKENS CANNOT BE TRANSFERED";
    string public constant PUBLIC_SALE_NOT_AVAILABLE = "PUBLIC SALE NOT AVAILABLE";
    string public constant PRESALE_NOT_AVAILABLE = "PRESALE NOT AVAILABLE";
    string public constant MINT_ZERO_TOKENS = "MINT ZERO TOKENS";
    string public constant PASS_USED_UP = "PASS USED UP";
    string public constant NOT_ALLOWED_OR_QUOTA_EXCEEDED = "NOT ALLOWED OR QUOTA EXCEEDED";
    string public constant SUPPLY_QUOTA_EXCEEDED = "SUPPLY_QUOTA_EXCEEDED";

    modifier onlyNftContract() {
        require(msg.sender == nftAddress, UNAUTHORIZED);
        _;
    }

    constructor() ERC1155("") Ownable()
    {
        _royaltyRecipient = owner();
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice burn used passports by external nft contract
     */
    function burn(address _address, uint256 _tokenId, uint256 _count)
        external
        onlyNftContract
    {
        require(balanceOf(_address, _tokenId) > 0, PASSPORT_EMPTY);
        require(balanceOf(_address, _tokenId) >= _count, NOT_ENOUGH_PASSPORTS);

        _burn(_address, _tokenId, _count);
    }

    function setNftAddress(address _address) external onlyOwner {
        nftAddress = _address;
    }

    function changePresale(bool _enabled) external onlyOwner {
        presaleEnabled = _enabled;
    }

    function changePublicSale(bool _enabled) external onlyOwner {
        publicSaleEnabled = _enabled;
    }

    function enablePublicSale() external onlyOwner {
        presaleEnabled = false;
        publicSaleEnabled = true;
    }

    function addToWhitelist(address _address) external onlyOwner {
        WHITELIST[_address] = MAX_BUY_COUNT_PER_USER;
    }

    function addBatchToWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint i=0; i < _addresses.length; i++) {
            WHITELIST[_addresses[i]] = MAX_BUY_COUNT_PER_USER;
        }
    }

    /**
     * @notice mint presale passport for free
     */
    function giveawayPresale(address _to, uint256 _count)
        external
        onlyOwner
        returns (uint256 _tokenId)
    {
        _tokenId = PRESALE_TOKEN_ID;
        _mint(_to, _tokenId, _count);
    }

    modifier buyForEther(uint256 _count, uint256 _price) {
        require(_count > 0, MINT_ZERO_TOKENS);
        require(msg.value == _count * _price, PAYMENT_AMOUNT_INCORRECT);
        _;
    }

    /**
     * @notice buy presale passport for ether
     */
    function buyPresale(uint256 _buyCount)
        external
        payable
        buyForEther(_buyCount, PRESALE_TOKEN_PRICE)
        returns (uint256 _tokenId)
    {
        require(presaleEnabled, PRESALE_NOT_AVAILABLE);
        require(!publicSaleEnabled, PRESALE_NOT_AVAILABLE);
        require(WHITELIST[msg.sender] > 0, NOT_ALLOWED_OR_QUOTA_EXCEEDED);
        require(balanceOf(msg.sender, PRESALE_TOKEN_ID) + _buyCount <= WHITELIST[msg.sender], PASS_USED_UP);

        _tokenId = PRESALE_TOKEN_ID;
        _mint(msg.sender, _tokenId, _buyCount);
    }

    /**
     * @notice mint public passport for ether
     */
    function buyPublic(uint256 _buyCount)
        external
        payable
        buyForEther(_buyCount, PUBLIC_TOKEN_PRICE)
        returns (uint256 _tokenId)
    {
        require(publicSaleEnabled, PUBLIC_SALE_NOT_AVAILABLE);

        _tokenId = PUBLIC_TOKEN_ID;
        _mint(msg.sender, _tokenId, _buyCount);
    }

    /**
     * @notice mint presale passport
     */
    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _count
    ) private {
        require(_count > 0, MINT_ZERO_TOKENS);
        require(mintedPasses + _count <= TOTAL_MAX_SUPPLY, SUPPLY_QUOTA_EXCEEDED);
        uint256 _mintedPasses = mintedPasses + _count;
        mintedPasses = _mintedPasses;
        super._mint(_to, _tokenId, _count, "");
    }

    /**
     * @dev See {IERC1155-_beforeTokenTransfer}.
     * @notice forbid presale passport transfers
     */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        super._beforeTokenTransfer(
            _operator,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
        if (_from == address(0) || _to == address(0)) {
            return;
        }
        uint256 _count = _ids.length;
        for (uint256 i = 0; i < _count; i++) {
            require(_ids[i] != PRESALE_TOKEN_ID, PRESALE_RESTRICTED);
        }
    }

    function availableMint() external view returns (uint256) {
        return TOTAL_MAX_SUPPLY - mintedPasses;
    }

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 _token)
        public
        view
        virtual
        override
        returns (string memory _uri)
    {
        if (_token == PRESALE_TOKEN_ID) {
            _uri = string(abi.encodePacked(baseTokenURI, Strings.toString((PRESALE_TOKEN_ID))));
        } else if (_token == PUBLIC_TOKEN_ID) {
            _uri = string(abi.encodePacked(baseTokenURI, Strings.toString((PUBLIC_TOKEN_ID))));
        } else {
            _uri = "";
        }
    }
}
