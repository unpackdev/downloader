// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";

contract MalevaConcierge is ERC721, Ownable, ERC721Royalty, ERC721URIStorage {
    using Strings for uint256;


    struct NFTType {
        string name;
        uint256 startSupply;
        uint256 currentSupply;
        uint256 tillReserveMint;
        uint256 totalSupply;
        uint256 price;
    }

    bool public isMintStarted;
    uint private TOTAL_SUPPLY = 2800;
    string private BASE_URI = "";
    string private CONTRACT_URI = "";
    address public TEAM_ALLOCATION_ADDRESS;
    address public PAYMENT_ADDRESS_NFT_SALE;

    modifier startMint() {
        require(isMintStarted, "Minting is not started yet.");
        _;
    }

    mapping(uint256 => NFTType) private _tokenTypes;

    event MintedNFT(uint256 typeId, uint256 tokenId, address indexed recipient);
    event ReserveNFTClaimed(address claimedBy);

    constructor(
        uint[] memory _pricesInETH,
        string memory _uri,
        string memory _contract_uri,
        address _teamAllocationAddress,
        address _paymentAddressForNFTSale,
        address _paymentAddressForRoyalties
    ) Ownable() ERC721("Maleva Concierge NFT", "MALEVANFT") {
        BASE_URI = _uri;
        CONTRACT_URI = _contract_uri;
        _tokenTypes[2] = NFTType(
            "Platinum",
            0,
            0,
            91,
            150,
            _pricesInETH[0]
        );

        _tokenTypes[1] = NFTType(
            "Elite",
            150,
            0,
            661,
            850,
            _pricesInETH[1]
        );
        _tokenTypes[0] = NFTType(
            "Chrome",
            1000,
            0,
            2081,
            1800,
            _pricesInETH[2]
        );
        TEAM_ALLOCATION_ADDRESS = _teamAllocationAddress;
        PAYMENT_ADDRESS_NFT_SALE = _paymentAddressForNFTSale;
        _setDefaultRoyalty(_paymentAddressForRoyalties, 1000); // 10% Royalties
    }

    function enableMint() external onlyOwner {
        isMintStarted = !isMintStarted;
    }

    function typeOfToken(uint256 typeId) public view returns (NFTType memory) {
        require(typeId >= 0 && typeId < 3, "Invalid NFT type");
        NFTType memory nftType = _tokenTypes[typeId];
        return nftType;
    }

    function mintMalevaNFT(
        uint256 typeId,
        address recipient
    ) public payable startMint {
        NFTType memory nftType = typeOfToken(typeId);
        uint tokenId = nftType.startSupply + nftType.currentSupply + 1;
        require(tokenId < nftType.tillReserveMint, "NFT type sold out");
        require(msg.value >= nftType.price, "Insufficient funds");
        NFTType storage toBeUpdateNftType = _tokenTypes[typeId];
        toBeUpdateNftType.currentSupply += 1;
        _mint(recipient, tokenId);
        (bool send, ) = payable(PAYMENT_ADDRESS_NFT_SALE).call{
            value: msg.value
        }("");
        require(send, "Error in Sending ETH to Payment Address.");
        emit MintedNFT(typeId, tokenId, recipient);
    }

    function updateTypePrice(
        uint256 typeId,
        uint256 newPrice
    ) public onlyOwner {
        require(typeId >= 0 && typeId < 3, "Invalid NFT type");
        NFTType storage nftType = _tokenTypes[typeId];
        nftType.price = newPrice;
    }

    function updateRoyaltyFee(
        address _recipient,
        uint96 newFee
    ) public onlyOwner {
        require(newFee > 0, "Invalid fee");
        _setDefaultRoyalty(_recipient, newFee);
    }

    function updatePaymentAddress(address _paymentAddress) public onlyOwner {
        require(
            _paymentAddress != address(0),
            "Payment Address can not be zero."
        );
        PAYMENT_ADDRESS_NFT_SALE = _paymentAddress;
    }

    function mintReserveNFTs(uint256 typeId, address recipient) external {
        require(
            msg.sender == TEAM_ALLOCATION_ADDRESS,
            "Not the Team Allocated Address."
        );
        if (typeId == 0) {
            uint _platinumResStart = 91;
            uint _platinumResEnd = 150;
            for (
                uint _tokenId = _platinumResStart;
                _tokenId <= _platinumResEnd;
                _tokenId++
            ) {
                _mint(recipient, _tokenId);
            }
        } else if (typeId == 1) {
            uint _eliteResStart = 661;
            uint _eliteResEnd = 1000;
            for (
                uint _tokenId = _eliteResStart;
                _tokenId <= _eliteResEnd;
                _tokenId++
            ) {
                _mint(recipient, _tokenId);
            }
        } else if (typeId == 2) {
            uint _chromeResStart = 2081;
            uint _chromeResEnd = 2800;
            for (
                uint _tokenId = _chromeResStart;
                _tokenId <= _chromeResEnd;
                _tokenId++
            ) {
                _mint(recipient, _tokenId);
            }
        }
        emit ReserveNFTClaimed(recipient);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Royalty, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function totalSupply() public view returns (uint) {
        return TOTAL_SUPPLY;
    }

    function withdraw(uint _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to withdraw ETH");
    }

    function _burn(
        uint _tokenId
    ) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(_tokenId);
    }
}
