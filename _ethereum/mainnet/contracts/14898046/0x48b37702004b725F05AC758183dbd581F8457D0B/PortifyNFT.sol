// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;


import "./ERC721A.sol";
import "./Ownable.sol";



contract PortifyNFT is ERC721A, Ownable {
    event Purchase(address indexed user, uint count);

    uint public reserved_num;
    mapping (address => uint) public reserved_minters;
    mapping (address => uint) public free_minters;

    uint constant public MAX_TOTAL_SUPPLY = 500;
    uint public NFT_price = 0.2 ether;
    uint public max_nfts_per_user = 3;
    uint32 public sale_start;
    address public beneficiary;
    string baseUri;

    constructor(
        uint32 _sale_start,
        address _beneficiary,
        string memory _baseUri
    ) ERC721A("Byte Me | Portify", "Byte") {
        require (_sale_start > block.timestamp, "PortifyNFT::constructor:: bad start time");

        sale_start = _sale_start;
        beneficiary = _beneficiary;
        baseUri = _baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setSaleStart(uint32 new_start) external onlyOwner {
        sale_start = new_start;
    }

    function setReserved(address[] calldata users, uint[] calldata count) external onlyOwner {
        require (users.length == count.length, "PortifyNFT::setReserved:: bad input arrays length");

        for (uint i = 0; i < users.length; i++) {
            if (free_minters[users[i]] > 0) {
                reserved_num -= free_minters[users[i]];
                free_minters[users[i]] = 0;
            }
            reserved_num = reserved_num - reserved_minters[users[i]] + count[i];
            reserved_minters[users[i]] = count[i];
        }

        require (totalSupply() + reserved_num <= MAX_TOTAL_SUPPLY, "PortifyNFT::setReserved:: reserved too much");
    }

    function setFreeMinters(address[] calldata users, uint[] calldata count) external onlyOwner {
        require (users.length == count.length, "PortifyNFT::setFreeMinters:: bad input arrays length");

        for (uint i = 0; i < users.length; i++) {
            if (reserved_minters[users[i]] > 0) {
                reserved_num -= reserved_minters[users[i]];
                reserved_minters[users[i]] = 0;
            }
            reserved_num = reserved_num - free_minters[users[i]] + count[i];
            free_minters[users[i]] = count[i];
        }

        require (totalSupply() + reserved_num <= MAX_TOTAL_SUPPLY, "PortifyNFT::setFreeMinters:: reserved too much");
    }

    function setPrice(uint new_price) external onlyOwner {
        NFT_price = new_price;
    }

    function setMaxNFTsPerUser(uint new_limit) external onlyOwner {
        max_nfts_per_user = new_limit;
    }

    function setBeneficiary(address _new_beneficiary) external onlyOwner {
        beneficiary = _new_beneficiary;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function mintByOwner(address user, uint count) external onlyOwner {
        require (totalSupply() + count <= MAX_TOTAL_SUPPLY - reserved_num, "PortifyNFT::buyNFTs:: max supply reached");

        _mint(user, count);
    }

    function buyNFTs(uint count) external payable {
        require (block.timestamp >= sale_start, "PortifyNFT::buyNFTs:: sale not started");

        if (reserved_minters[msg.sender] >= count) {
            reserved_minters[msg.sender] -= count;
            reserved_num -= count;
        } else if (reserved_minters[msg.sender] > 0 && reserved_minters[msg.sender] < count) {
            reserved_num -= reserved_minters[msg.sender];
            reserved_minters[msg.sender] = 0;
        }

        uint price_to_pay = NFT_price * count;
        if (free_minters[msg.sender] >= count) {
            free_minters[msg.sender] -= count;
            reserved_num -= count;
            price_to_pay = 0;
        } else if (free_minters[msg.sender] > 0 && free_minters[msg.sender] < count){
            price_to_pay = NFT_price * (count - free_minters[msg.sender]);
            reserved_num -= free_minters[msg.sender];
            free_minters[msg.sender] = 0;
        }

        require (totalSupply() + count <= MAX_TOTAL_SUPPLY - reserved_num, "PortifyNFT::buyNFTs:: max supply reached");
        require (_numberMinted(msg.sender) + count <= max_nfts_per_user, "PortifyNFT::buyNFTs:: max nfts per user");

        require (msg.value >= price_to_pay, "PortifyNFT::buyNFTs:: not enough ethers for purchase");

        _mint(msg.sender, count);
        emit Purchase(msg.sender, count);

        // return change
        if (msg.value > price_to_pay) {
            payable(msg.sender).transfer(msg.value - price_to_pay);
        }

        // collect all ethers we have
        if (address(this).balance > 0) {
            payable(beneficiary).transfer(address(this).balance);
        }
    }

    function mintedByUser(address user) external view returns (uint) {
        return _numberMinted(user);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}
