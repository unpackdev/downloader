// Kurayami Mint Pass (www.projectkurayami.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Strings.sol";
import "./AbstractERC1155.sol";

contract KurayamiMintPass is AbstractERC1155 {
    constructor(string memory _metadataUri)
        AbstractERC1155("Kurayami Mint Pass", "KMP")
    {
        baseURI = _metadataUri;
        tokenMaxSupply[0] = 77;
    }

    /**
     * @dev Opens the public sale
     */
    bool public saleOpen = false;
    bool public saleLocked = false;

    modifier publicSaleOpen() {
        require(saleOpen, "Sale Not Open");
        _;
    }

    modifier saleNotLocked() {
        require(!saleLocked, "Sale Locked!");
        _;
    }

    function togglePublicSale() external onlyOwner saleNotLocked {
        saleOpen = !saleOpen;
    }

    function lockSaleForever() external onlyOwner {
        saleLocked = true;
        saleOpen = false;
    }

    /**
     * @dev Mutable token supply
     */
    uint256 public saleTokenId = 0;
    uint256 public salePrice = 0.099 ether;

    function setCurrentSale(uint256 _tokenId, uint256 _price)
        external
        onlyOwner
    {
        saleTokenId = _tokenId;
        salePrice = _price;
        saleOpen = false;
    }

    /**
     * @dev General Mint
     */
    mapping(address => mapping(uint256 => bool)) public mintedPass;

    modifier withinMaximumSupply(uint256 _tokenId, uint256 _quantity) {
        require(
            totalSupply(_tokenId) + _quantity <= tokenMaxSupply[_tokenId],
            "Hit Limit"
        );
        _;
    }

    modifier hasCorrectAmount() {
        require(msg.value >= salePrice, "Insufficent Funds");
        _;
    }

    modifier hasNotMintedToken(uint256 _tokenId) {
        require(!mintedPass[msg.sender][_tokenId], "Already Minted");
        _;
    }

    function mint()
        public
        payable
        publicSaleOpen
        hasCorrectAmount
        withinMaximumSupply(saleTokenId, 1)
        hasNotMintedToken(saleTokenId)
    {
        mintedPass[msg.sender][saleTokenId] = true;
        _mint(msg.sender, saleTokenId, 1, "");
    }

    /**
     * @dev Mutable token supply
     */
    mapping(uint256 => uint256) public tokenMaxSupply;

    function setTokenMaxSupply(uint256 _tokenId, uint256 _supply)
        external
        onlyOwner
    {
        if (tokenMaxSupply[_tokenId] != 0) {
            require(
                _supply <= tokenMaxSupply[_tokenId],
                "Cannot Increase Supply"
            );
            require(
                _supply >= totalSupply(_tokenId),
                "Must Be Above Minted Amount"
            );
        }
        tokenMaxSupply[_tokenId] = _supply;
    }

    /**
     * @dev Admin mint
     */
    function adminMint(
        address _recipient,
        uint256 _tokenId,
        uint256 _quantity
    ) public onlyOwner withinMaximumSupply(_tokenId, _quantity) saleNotLocked {
        _mint(_recipient, _tokenId, _quantity, "");
    }

    /**
     * @dev Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Burn on redemption
     */
    address erc721Contract;

    function redeem(
        address _account,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(erc721Contract == msg.sender, "Not Official Contract");
        _burn(_account, _tokenId, _amount);
    }

    function setErc721Contract(address _erc721Contract) external onlyOwner {
        require(erc721Contract == address(0), "Contract Already Set");
        erc721Contract = _erc721Contract;
    }

    /**
     * @dev Payout mechanism
     */
    address private constant payoutAddress1 =
        0xbaF153A8AfF8352cB6539CF9168255442Def0a02;
    address private constant payoutAddress2 =
        0x942d44A7B2F9Dc4c2cA60e6FEcDbA4c0Fa4981e0;
    address private constant payoutAddress3 =
        0xba859AAdf1F87aAB4fB117AcFa04Ca3B834CD427;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 40) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 40) / 100);
        Address.sendValue(payable(payoutAddress3), (balance * 20) / 100);
    }
}
