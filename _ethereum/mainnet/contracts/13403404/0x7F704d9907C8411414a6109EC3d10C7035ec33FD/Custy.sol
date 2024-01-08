pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

/// Contract of Custy NFT collection
contract Custy is ERC721URIStorage, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private constant baseURI = "ipfs://";
    uint16 private constant totalSupply = 6000;
    uint16 private customerMintedCount;
    /// Quantitiy of custies for owners (for owner's, giveaway, etc)
    uint8 private oftheyearMintedCount;

    /// Address which will be able to mint 100 Custies for early birds and giveaways, etc
    address private constant ofTheYearWalletAddress = 0xbEfd893738193c5979C67e3E2EDD622931510c0C;

    /// Initial state is 0
    /// Will be set after community bank will be deployed
    address private communityBankAddress = address(0);

    /// We save amount of eth which was received from custy sales only
    /// Doesn't include the royalty
    uint256 private ethReceivedFromSales = 0;

    /// Each custy has its own unique hash value which represents the params of custy
    /// E.g. head shape, body shape, accessories etc.
    uint256[] private _custyHashValues;
    mapping(uint256 => bool) private isCustyHashValueExistByHashes;
    mapping(uint256 => string) private _tokenURIsById;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721("Custies", "CST") {
        mintCusty(401101210131214, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmVX1MhnFtDonQdnQ79Menjuh8jxBygztgoALyCFQUzDxd");
        mintCusty(103060310140908, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmZKZCiCRGC31QzE8x5F7KpsXZVimrhmgA4sEGpotx6h4o");
        mintCusty(102100704041214, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmfVu9xcCZkTnbxhdVpLDM3G1Rt8hAaxeVPFEjKjpAGZtb");
        mintCusty(204081103101404, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmTE4jXbSxeuXUhHXjtFyB6bi8N3RJc2m9LZxbktiqfcz2");
        mintCusty(505020604100713, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmWuXyjxJpZqWLKNGWhxj47bAHshS7vahNk9Sm3mRTX7tB");
        mintCusty(105040106030101, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/Qme7pE3fAJySKTHSqhvpukcBseLZcZXE1GqYbzUMVtdBmY");
        mintCusty(305071206110513, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/Qmc91XjUpkApFMg44h94TesGKmCmRt6YEeh2viheGfpfvb");
        mintCusty(101090307091207, ofTheYearWalletAddress, "https://gateway.pinata.cloud/ipfs/QmctsJDGDAfPUUYgR9kt4oPGP1fj4r1X7FKb5LQvNFJfCj");
    }

    function allMintedHashes() public view returns (uint256[] memory) {
        return _custyHashValues;
    }

    function nextTokenNumberToBeMinted() public view returns (uint) {
        return _tokenIds.current() + 1;
    }

    /// Minting selected custy:
    /// 1. Write custy's hash value to prevent dublicates
    /// 2. Mint using tokenId and recipient address
    /// 3. Setting roylaty to nft. 2,5 %
    /// 4. Save the all amount received eth for custy to withdraw only this amount.
    ///    The all remained money will be assumed as received royalty
    /// We reserve 100 Custies for oftheyear
    /// oftheyear will use 100 reserved custies for giveaways and early birds
    function mintCusty(
        uint256 _custyHashValue,
        address _recipient,
        string memory _tokenURI
    ) public payable {
        uint256 _totalAvailableCustiesForCustomers = totalSupply -
            oftheyearMintedCount;
        require(
            !isCustyHashValueExistByHashes[_custyHashValue],
            "This custy is already existing"
        );
        if (_recipient != ofTheYearWalletAddress) {
            require(
                _totalAvailableCustiesForCustomers >= customerMintedCount,
                "All custies have been sold"
            );
            require(
                msg.value >= 0.04 ether,
                "Custy's price is 0.04 ether"
            );
        } else {
            require(oftheyearMintedCount <= 100, "Tebe bolwe nelzya");
        }

        require(_recipient != address(0), "Incorrect recipient's address");

        // ID of custy
        _tokenIds.increment();

        // Minting
        uint256 newItemId = _tokenIds.current();
        _mint(_recipient, _tokenURI, newItemId);

        if (_recipient == ofTheYearWalletAddress) {
            oftheyearMintedCount++;
        } else {
            customerMintedCount++;
        }

        // Save data about custy (Hash and owner)
        _custyHashValues.push(_custyHashValue);
        isCustyHashValueExistByHashes[_custyHashValue] = true;

        // Saving amount of eth which was recieved for custy
        ethReceivedFromSales += msg.value;
    }

    function _mint(
        address _recipient,
        string memory _tokenURI,
        uint256 _itemId
    ) private {
        _mint(_recipient, _itemId);
        _setTokenURI(_itemId, _tokenURI);
    }

    /// Withdraw only eth which were recieved for custy
    /// Royalty eth will remains on contract
    function withdraw() public onlyOwner {
        uint256 balance = ethReceivedFromSales;
        payable(owner()).transfer(balance);
        ethReceivedFromSales = 0;
    }

    function setCommunityBankAddress(address _bankAddress) public onlyOwner {
        communityBankAddress = _bankAddress;
    }

    function withdrawToCommunityBank() public {
        require(
            communityBankAddress != address(0),
            "Community bank doesn't exist yet"
        );
        require(
            msg.sender == communityBankAddress,
            "Only bank can withdraw royalties"
        );
        uint256 balanceOfRoyalties = address(this).balance -
            ethReceivedFromSales;
        payable(communityBankAddress).transfer(balanceOfRoyalties);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint royalty = _salePrice * 250 / 1000;
        return (owner(), royalty);
    }
}
