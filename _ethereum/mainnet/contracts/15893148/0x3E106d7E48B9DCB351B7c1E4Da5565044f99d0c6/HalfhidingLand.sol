// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Ownable.sol";
import "Strings.sol";
import "Address.sol";
import "ERC721A.sol";

contract HalfhidingLand is Ownable, ERC721A {
    using Address for address;
    using Strings for uint256;

    enum Status {
        Stop,
        Land1x1Mint,
        Land2x2Mint,
        Land3x3Mint
    }

    struct WLLandAmount {
        address wlAddress;
        uint256 wlLand1x1Amount;
        uint256 wlLand2x2Amount;
        uint256 wlLand3x3Amount;
    }

    struct WLLandMintedAmount {
        uint256 Land1x1MintedAmount;
        uint256 Land2x2MintedAmount;
        uint256 Land3x3MintedAmount;
    }

    uint256 public maxSupply;
    uint256 public land1x1Supply;
    uint256 public land2x2Supply;
    uint256 public land3x3Supply;
    string public baseURI;
    mapping(address => WLLandAmount) public addressLandAmount;
    mapping(address => WLLandMintedAmount) public addressLandMintedAmount;
    Status public mintStatus = Status.Stop;

    constructor(
        uint256 _maxSupply,
        uint256 _land1x1Supply,
        uint256 _land2x2Supply,
        uint256 _land3x3Supply,
        string memory _baseURI
    ) ERC721A("HalfhidingLand", "HalfhidingLand") {
        maxSupply = _maxSupply;
        land1x1Supply = _land1x1Supply;
        land2x2Supply = _land2x2Supply;
        land3x3Supply = _land3x3Supply;
        baseURI = _baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyStatus(Status _status) {
        require(mintStatus == _status, "It's not right status.");
        _;
    }

    function land1x1Mint(uint256 _quantity)
        external
        payable
        callerIsUser
        onlyStatus(Status.Land1x1Mint)
    {
        require(_totalMinted() < land1x1Supply, "Reached land1x1 max supply");
        require(
            addressLandAmount[msg.sender].wlLand1x1Amount -
                addressLandMintedAmount[msg.sender].Land1x1MintedAmount >=
                _quantity,
            "Reached the number of mintable"
        );
        _safeMint(msg.sender, _quantity);
        addressLandMintedAmount[msg.sender].Land1x1MintedAmount += _quantity;
    }

    function land2x2Mint(uint256 _quantity)
        external
        payable
        callerIsUser
        onlyStatus(Status.Land2x2Mint)
    {
        require(
            _totalMinted() >= land1x1Supply,
            "Land1x1 has not finished mint"
        );
        require(
            _totalMinted() < land1x1Supply + land2x2Supply,
            "Reached land2x2 max supply"
        );
        require(
            addressLandAmount[msg.sender].wlLand2x2Amount -
                addressLandMintedAmount[msg.sender].Land2x2MintedAmount >=
                _quantity,
            "Reached the number of mintable"
        );
        _safeMint(msg.sender, _quantity);
        addressLandMintedAmount[msg.sender].Land2x2MintedAmount += _quantity;
    }

    function land3x3Mint(uint256 _quantity)
        external
        payable
        callerIsUser
        onlyStatus(Status.Land3x3Mint)
    {
        require(
            _totalMinted() >= land1x1Supply + land2x2Supply,
            "Land2x2 has not finished mint"
        );
        require(
            _totalMinted() < land1x1Supply + land2x2Supply + land3x3Supply,
            "Reached land3x3 max supply"
        );
        require(
            addressLandAmount[msg.sender].wlLand3x3Amount -
                addressLandMintedAmount[msg.sender].Land3x3MintedAmount >=
                _quantity,
            "Reached the number of mintable"
        );
        _safeMint(msg.sender, _quantity);
        addressLandMintedAmount[msg.sender].Land3x3MintedAmount += _quantity;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //only owner
    function setBaseURI(string memory _baseURL) public onlyOwner {
        baseURI = _baseURL;
    }

    function addWL(WLLandAmount[] calldata members) public onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            addressLandAmount[members[i].wlAddress] = members[i];
        }
    }

    function removeWL(address[] calldata members) public onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            addressLandAmount[members[i]].wlLand1x1Amount = 0;
            addressLandAmount[members[i]].wlLand2x2Amount = 0;
            addressLandAmount[members[i]].wlLand3x3Amount = 0;
        }
    }

    function setStatus(uint256 _status) external onlyOwner {
        mintStatus = Status(_status);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(
            _maxSupply > land1x1Supply + land2x2Supply + land3x3Supply,
            "Quantity less than land1,2,3"
        );
        maxSupply = _maxSupply;
    }

    function setLand1x1Supply(uint256 _land1x1Supply) external onlyOwner {
        land1x1Supply = _land1x1Supply;
    }

    function setLand2x2Supply(uint256 _land2x2Supply) external onlyOwner {
        land2x2Supply = _land2x2Supply;
    }

    function setLand3x3Supply(uint256 _land3x3Supply) external onlyOwner {
        land3x3Supply = _land3x3Supply;
    }

    function teamMint(uint256 _amount, address _receiver) public onlyOwner {
        require(
            totalSupply() + _amount <= maxSupply,
            "All token have already been minted!"
        );
        _safeMint(_receiver, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}
