// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./ERC721Composable.sol";
import "./ERC721Firewall.sol";
import "./IERC721Factory.sol";
import "./IERC721OwnableWrapper.sol";

contract ERC721Factory is IERC721Factory, ERC721Composable, IERC721OwnableWrapper {

    address public collection;
    address public firewall;
    uint256 public fee;
    bool public mintingActive;

    // Modifiers
    modifier onlyWhenCollectionSet() {
        require(collection != address(0), "Factory: collection zero address!");
        _;
    }

    modifier onlyWhenMintable(address minter, uint256 amount) {
        (bool allowed, string memory message) = canMint(minter, amount);
        require(allowed, message);
        _;
    }
    
    constructor(address collection_, uint256 fee_, address firewall_) {
        setCollection(collection_);
        setFactoryValues(false, fee_, firewall_);
    }

    // Minting
    function mint() public payable override {
        mint(_msgSender(), 1);
    }

    function mint(uint256 amount) public payable override {
        mint(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) public payable override {
        require(_msgSender() == owner() || _msgSender() == address(this) || fee * amount == msg.value,
            'Factory: provided fee does not match required amount!');
        _mint(to, amount);
    }

    function mintAdmin() public payable override {
        mintAdmin(_msgSender(), 1);
    }

    function mintAdmin(uint256 amount) public payable override {
        mintAdmin(_msgSender(), amount);
    }

    function mintAdmin(address to, uint256 amount) public payable override onlyOwner {
        (bool allowed, ) = ERC721Firewall(firewall).canAllocate(to, amount);
        if (!allowed) ERC721Firewall(firewall).setAllocation(to, ERC721Firewall(firewall).currentAllocation(to) + amount);
        mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal onlyWhenMintable(to, amount) {
        ERC721Firewall(firewall).allocate(to, amount);
        ERC721Wrapper(collection).mintTo(to, amount);
        emit TokenMinted(to, amount);
    }

    function canMint(address minter, uint256 amount) public override view returns (bool, string memory) {
        bool allowed = false;
        string memory message = "";

        if (collection == address(0)) {
            return (false, "Factory: cannot mint yet");
        }
        allowed = ERC721Wrapper(collection).canMint(amount);
        if (!allowed) {
            return (false, "Factory: cannot mint more");
        }
        (allowed, message) = ERC721Firewall(firewall).canAllocate(minter, amount);
        if (!allowed) {
            return (false, message);
        }
        if (_msgSender() != owner()) {
            if (!mintingActive) {
                return (false, "Factory: minting disabled!");
            }
            if (ERC721Firewall(firewall).isWhitelistActive() && !ERC721Firewall(firewall).isWhitelisted(minter)) {
                return (false, "Factory: not whitelisted!");
            }
        }
        return (true, "");
    }

    // Setters
    function setFactoryValues(bool enableMinting_, uint256 fee_, address firewall_) internal onlyOwner {
        setMintingActive(enableMinting_);
        setFee(fee_);
        setFirewall(firewall_);
    }

    function setMintingActive(bool enabled_) public onlyOwner {
        mintingActive = enabled_;
        emit MintingSet(enabled_);
    }

    function setFee(uint256 fee_) public onlyOwner {
        // zero fee_ is accepted
        fee = fee_;
        emit FeeSet(fee_);
    }   

    function setCollection(address collection_) public onlyOwner {
        collection = collection_;
        emit CollectionSet(collection_);
    }

    function setFirewall(address firewall_) public onlyOwner {
        firewall = firewall_;
        emit FirewallSet(firewall_);
    }

    // Payments & Ownership
    function balanceOf() external view override returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address to) public override onlyOwner {
        uint256 amount = address(this).balance;
        withdraw(to, amount);
    }

    function withdraw(address to, uint256 amount) public override onlyOwner {
        require(to != address(0), 'Factory: cannot withdraw fees to zero address!');
        payable(to).transfer(amount);
        emit Withdrawn(_msgSender(), to, amount);
    }


    // Owable ERC721Wrapper functions
    function setBaseURI(string memory _uri) external override onlyOwner onlyWhenCollectionSet {
        ERC721Wrapper(collection).setBaseURI(_uri);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        ERC721Wrapper(collection).setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyOwner onlyWhenCollectionSet {
        ERC721Wrapper(collection).deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external override onlyOwner onlyWhenCollectionSet {
        ERC721Wrapper(collection).setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external override onlyOwner onlyWhenCollectionSet {
        ERC721Wrapper(collection).resetTokenRoyalty(tokenId);
    }
}