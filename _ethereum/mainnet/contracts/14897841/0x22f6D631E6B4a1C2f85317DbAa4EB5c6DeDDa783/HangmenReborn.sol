// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";

contract HangmenReborn is ERC721ABurnable, ERC721AQueryable, Ownable, Pausable, ERC2981{

    RoyaltyInfo private _royalties;

    uint256 constant public MAX_SUPPLY = 9696;
    uint256 constant public MAX_BUY_PER_ADDRESS = 50;
    uint256 constant public MAX_PER_TX = 20;
    uint256 constant public FREE_PER_ADDRESS = 2;
    uint256 constant public PRICE = 0.0069 ether;
    uint256 constant public BURN_ADVANTAGE = 4;
    
    bool private ogAirdropped = false;

    bool public isPublicSaleActive = false;
    bool public isBurnActive = false;
    Hangmen public hangmen;

    string public contractURIString = "https://bafkreiejao3nwe64gzqvjr37hptma7rn472ui4kjiis5d7eo5b5ty6bumq.ipfs.nftstorage.link/";
    string public baseURI = "https://hangmen.org/reveal/";
    
    constructor() ERC721A("Hangmen", "HANG") {
        _royalties = RoyaltyInfo(msg.sender, 469);

        hangmen = Hangmen(0x7c146E2F2eA3dD022dC33d927bf28888f9Fd595c);
    }

    //////// Internal functions

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Allow anyone to mint 2 tokens for free and the rest in exchange of a fee
    /// the public sale should be active for this call to succeed 
    function mint(uint256 _amount) external payable publicSaleActive callerIsUser whenNotPaused {
        require(_amount <= MAX_PER_TX, "Too many mints per tx");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= MAX_BUY_PER_ADDRESS, "Max mint limit");

        // Compute the price to include first two mints for free
        uint256 discounted_amount = _amount - min(_amount, (FREE_PER_ADDRESS - min(FREE_PER_ADDRESS, userMintsTotal)));
        uint256 price = PRICE;
        checkValue(price * discounted_amount);

        _mint(msg.sender, _amount);
    }

    /// Exchange the tokens of the old collection for freshly minted ones in the new collection
    /// Burns all tokens owned in the old collection for up to BURN_ADVANTAGE * owned new ones
    /// Depending on what's left to mint
    /// The public sale should be active for this call to succeed
    function xchange() external burnActive callerIsUser whenNotPaused {
        // we get all the tokens owned by the msg sender
        uint256[] memory tokenIds = hangmen.walletOfOwner(msg.sender);
        require(tokenIds.length >= 1, "Nothing to burn");

        uint256 _amount = min(tokenIds.length * BURN_ADVANTAGE, MAX_SUPPLY - totalSupply());
        require(_amount >= 1, "Not enough mints left");

        for (uint i = 0; i < tokenIds.length; i++) {
            hangmen.transferFrom(msg.sender, address(0xdead), tokenIds[i]);
        }

        _mint(msg.sender, _amount);
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

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, IERC165)
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

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a <= b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }

    //////// Owner functions
    
    // we airdrop the first five tokens to the OGs who paid for their mints in the first collection
    // Same order as Mint order
    function ogAirdrop() external onlyOwner whenNotPaused {
        require(ogAirdropped == false, "OGs already received their airdrop");
        _mint(0xf17A57CC21b2d9Bbe8E2da1fa6a0F14a8c85FF1F, 1); 
        _mint(0x96612D11511D57DBa6705d43381dBbF6662783Eb, 1);
        _mint(0xaDFF354cfA10AD48C6898511BC3f7845aedB7Fb4, 1);
        _mint(0x9b7015Ea9466371d23391319D78Fa20C280B3B02, 1);
        _mint(0xE2416008F80c575DcA8281E3e600016023C5c105, 1);

        ogAirdropped = true;
    }

    /// Enable the owner to mint tokens and airdrop them to any wallet
    /// works with no restriction at all
    function airdrop(uint256 _amount, address _user) external onlyOwner whenNotPaused {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");

        _mint(_user, _amount);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURIString = _contractURI;
    }

    function setOldHang(address _oldHand) public onlyOwner {
        hangmen = Hangmen(_oldHand);
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

    function setIsBurnActive(bool _isBurnActive) external onlyOwner{
        isBurnActive = _isBurnActive;
    }

    function pause() external onlyOwner{
        super._pause();
    }

    function unpause() external onlyOwner{
        super._unpause();
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) public onlyOwner whenNotPaused {
        require(value <= 10000, 'ERC2981: Value too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    //////// Override function for Pausable functionality

    // approve is not declared as virtual in the ERC721A contract so we can't override it
    // function approve(address to, uint256 tokenId) public override(ERC721A, IERC721) whenNotPaused {
    //     super.approve(to, tokenId);
    // }
    
    function setApprovalForAll(address to, bool approved) public override(ERC721A, IERC721) whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    //////// Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is closed");
        _;
    }

    modifier burnActive() {
        require(isBurnActive, "Burn is closed");
        _;
    }
}

contract Hangmen {
    function walletOfOwner(address) public returns (uint256[] memory) {}
    function transferFrom(address, address, uint256) public {}
}