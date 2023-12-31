// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721AQueryable.sol";
import "./OperatorFilterer.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ERC2981.sol";
import "./IDickzukiWhitelist.sol";

interface ITokenWrapper {
    function balanceOf(address user) external view returns (uint256);

    function withdraw(uint256 amount) external;
}

contract Dickzuki is
    ERC2981,
    ERC721AQueryable,
    OperatorFilterer,
    Ownable,
    Pausable
{
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TXN = 10;
    string private baseURI;
    bool public operatorFilteringEnabled;
    uint256 public price = 0.0069 ether;
    uint256 public freeMintSupply = 3500;
    IDickzukiWhitelist whitelistContract;
    event Mint(address address_, uint256 quantity);

    constructor(
        string memory baseURI_,
        address whitelistContract_
    ) Ownable(msg.sender) ERC721A("Dickzuki", "DZ") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(address(this), 690);
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
        whitelistContract = IDickzukiWhitelist(whitelistContract_);
        _pause();
    }

    /**
     * @dev Up to 3 free NFTs first 3500
     */
    function _getFreeMints() private view returns (uint64) {
        return _totalMinted() >= freeMintSupply ? 0 : 3;
    }

    /**
     * @notice While supply is under 3500, you can claim 3 free mints. 0.0069 ETH/ea after. Paid mints are prioritized.
     * @param quantity Number of tokens to mint
     */
    function mintWhitelist(
        uint64 quantity
    )
        public
        payable
        insideTotalSupply(quantity)
        isWhitelisted(msg.sender)
        whenNotPaused
    {
        uint64 freeMinted = _getAux(msg.sender);
        uint64 maxFreeMints = _getFreeMints();
        require(quantity <= MAX_PER_TXN, "Over Txn Limit");
        if (freeMinted >= maxFreeMints) {
            require(msg.value >= quantity * price, "Not Enough ETH");
            emit Mint(msg.sender, quantity);
        } else {
            uint64 unusedFreeMints = maxFreeMints - freeMinted;
            // require(tx.origin == msg.sender, "EOA Only");
            if (quantity >= unusedFreeMints) {
                uint256 payingFor = quantity - unusedFreeMints;
                require(msg.value >= payingFor * price, "Not Enough ETH");
                emit Mint(msg.sender, payingFor);
            }
            _setAux(msg.sender, freeMinted + quantity);
        }
        _mint(msg.sender, quantity);
    }

    function mint(
        uint64 quantity
    ) public payable insideTotalSupply(quantity) whenNotPaused {
        require(quantity <= MAX_PER_TXN, "Over Txn Limit");
        require(msg.value >= quantity * price, "Not Enough ETH");
        emit Mint(msg.sender, quantity);
        _mint(msg.sender, quantity);
    }

    function setWhitelistContract(address address_) public onlyOwner {
        whitelistContract = IDickzukiWhitelist(address_);
    }

    modifier isWhitelisted(address address_) {
        require(
            IDickzukiWhitelist(whitelistContract).isWhitelisted(address_) ==
                true,
            "Not Whitelisted"
        );
        _;
    }

    modifier insideTotalSupply(uint256 _quantity) {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Above Total Supply");
        _;
    }

    function mintAsAdmin(
        address recipient,
        uint256 quantity
    ) public onlyOwner insideTotalSupply(quantity) {
        _mint(recipient, quantity);
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function setFreeMintSupply(uint256 max) public onlyOwner {
        freeMintSupply = max;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function airdrop(
        address[] memory addresses,
        uint256[] memory quantities
    ) public onlyOwner {
        require(addresses.length == quantities.length, "Mismatch");
        uint256 netQty;
        for (uint256 i; i < addresses.length; ++i) {
            uint256 qty = quantities[i];
            netQty += qty;
            _mint(addresses[i], qty);
        }
        require(netQty <= MAX_SUPPLY, "Over Supply");
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    function withdrawEverything() external onlyOwner {
        ITokenWrapper wrappedEther = ITokenWrapper(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
        uint256 wethBalance = wrappedEther.balanceOf(address(this));
        if (wethBalance > 0) {
            wrappedEther.withdraw(wethBalance);
        }
        ITokenWrapper blur = ITokenWrapper(
            0x0000000000A39bb272e79075ade125fd351887Ac
        );
        uint256 blurBalance = blur.balanceOf(address(this));
        if (blurBalance > 0) {
            blur.withdraw(blurBalance);
        }
        _withdraw();
    }

    function withdraw() public onlyOwner {
        _withdraw();
    }

    function _withdraw() private {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function toggle() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}
