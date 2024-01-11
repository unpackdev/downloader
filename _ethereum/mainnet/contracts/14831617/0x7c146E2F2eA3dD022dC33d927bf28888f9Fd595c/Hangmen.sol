// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract Hangmen is ERC721A, Ownable, ERC2981{

    RoyaltyInfo private _royalties;

    uint256 constant public MAX_SUPPLY = 6969;
    uint256 constant public MAX_BUY_PER_ADDRESS = 20;
    uint256 constant public MAX_PER_TX = 10;
    uint256 constant public PRICE = 0.0169 ether;
    uint256 constant public MAX_PER_WL = 4;

    bool public isPublicSaleActive = false;
    bool public isWhiteListActive = false;

    mapping(address => uint) private _whiteList;

    string public contractURIString = "https://bafkreibdisqygjcgnugfb3ogqmypu3ztee3d66rb6wp5ndldqneydhys5u.ipfs.nftstorage.link/";
    string public baseURI = "https://hangmen.org/reveal/";
    
    constructor() ERC721A("Hangmen", "HANG") {
        _royalties = RoyaltyInfo(msg.sender, 300);
    }

    //////// Internal functions

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Allow anyone to mint an NFT from the collection in exchange of a fee
    /// the public sale should be active for this call to succeed 
    function mint(uint256 _amount) external payable publicSaleActive {
        require(tx.origin == msg.sender, "No contract minting");
        require(_amount <= MAX_PER_TX, "Too many mints per tx");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        uint256 price = PRICE;
        checkValue(price * _amount);
        //totalSupplyPublic += _amount;

        _safeMint(msg.sender, _amount);
    }

    /// Allow wallets listed in the whitelist to mint tokens for free
    /// the whitelist sale should be active for this call to succeed
    function mintWL(uint256 _amount) external whiteListSaleActive{
        require(_whiteList[msg.sender] >= _amount, "Not enough whitelist quota available");
        require(tx.origin == msg.sender, "No contract minting");
        require(_amount <= MAX_PER_TX, "Too many mints per tx");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        _whiteList[msg.sender] -= _amount;

        _safeMint(msg.sender, _amount);
    }

    /// @inheritdoc	IERC2981
    /// @dev Gets royalty value for a given sale price and recipient to send royalties to
    /// @param value the sale price to compute roylaties on
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }



    //////// Public View functions
    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function interfaceID() public pure returns (bytes4) 
    {
        return type(IERC2981).interfaceId;
    }

    //////// Private functions
    function checkValue(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    //////// Owner functions

    /// Enable the owner to mint tokens and airdrop them to any wallet
    /// works with no restriction at all
    function mintTo(uint256 _amount, address _user) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(_user);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        //totalSupplyPublic += _amount;

        _safeMint(_user, _amount);
    }

    /// Allow the owner to add a new set of wallets to the whitelist
    function addToWhiteList(address[] calldata _users) external onlyOwner {
        for (uint256 i=0; i<_users.length; i++) {
            _whiteList[_users[i]] = MAX_PER_WL;
        }
    }

    /// This variation will be invoked if there is only one user to add to the whitelist
    function addToWhiteList(address _user) external onlyOwner {
        _whiteList[_user] = MAX_PER_WL;
    }

    function queryWhiteList(address _user) public view onlyOwner returns(uint256) {
        return _whiteList[_user];
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURIString = _contractURI;
    }

    /// Allow the owner to withdraw funds from the contract to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "transfer failed");
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner{
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsWhiteListSaleActive(bool _isWhiteListSaleActive) external onlyOwner{
        isWhiteListActive = _isWhiteListSaleActive;
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) public onlyOwner{
        require(value <= 10000, 'ERC2981: Value too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    //////// Modifiers
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is closed");
        _;
    }

    modifier whiteListSaleActive() {
        require(isWhiteListActive, "Whitelist sale is closed");
        _;
    }
}