// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract CoolMonstaz is ERC721, Ownable {
    uint256 private _totalSupply;
    uint256 private _maxSupply = 1111;
    uint256 public price = 0.06 ether;

    bool public publicsaleActive = true;
    bool public presaleActive = true;

    mapping(address => uint8) public presaleMints;
    uint256 public presaleMintLimit = 6;

    address private _wallet1 = 0xa9A35A8D65f94f27C5d9E78B984748BCa9AD5191;
    address private _wallet2 = 0x071FE7b23b21eDAf0A8eBD89c0dDa3462F978e3A;
    address private _wallet3 = 0x9dcE3e4Bd1913e759835D630cC6E7Eb6b591473E;
    address private _wallet4 = 0x64eB967bF4A84c9109769e91B9bAea9eED938005;
    address private _wallet5 = 0x97508bEE24D335B2D4F4173c4Ec27d4ED1098cF5;

    string public provenanceHash;
    string public baseURI;

    constructor() ERC721("Cool Monstaz", "MSTZ") {}

    function mintPublicsale(uint256 count) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        require(_totalSupply + count <= _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 40, "Out of per transaction mint limit");
        require(msg.value >= count * price, "Insufficient payment");

        if (presaleActive) {
            require(presaleMints[msg.sender] + count <= presaleMintLimit, "Per wallet mint limit");
        }

        for (uint256 i = 0; i < count; i++) {
            _totalSupply++;
            _mint(msg.sender, _totalSupply);
            presaleMints[msg.sender]++;
        }

        distributePayment();
    }

    function distributePayment() internal {
        bool success = false;
        (success,) = _wallet1.call{value : msg.value / 4}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value / 4}("");
        require(success2, "Failed to send2");

        bool success3 = false;
        (success3,) = _wallet3.call{value : msg.value / 4}("");
        require(success3, "Failed to send3");

        bool success4 = false;
        (success4,) = _wallet4.call{value : msg.value / 4}("");
        require(success4, "Failed to send4");
    }

    function mintGiveaway() external onlyOwner {
        require(msg.sender == tx.origin, "Reverted");
        require(_totalSupply < 60, "Out of limit");
        for (uint256 i = 0; i < 10; i++) {
            _totalSupply++;
            _mint(_wallet4, _totalSupply);
        }

        for (uint256 i = 0; i < 10; i++) {
            _totalSupply++;
            _mint(_wallet3, _totalSupply);
        }

        for (uint256 i = 0; i < 10; i++) {
            _totalSupply++;
            _mint(_wallet2, _totalSupply);
        }

        for (uint256 i = 0; i < 10; i++) {
            _totalSupply++;
            _mint(_wallet1, _totalSupply);
        }

        for (uint256 i = 0; i < 20; i++) {
            _totalSupply++;
            _mint(_wallet5, _totalSupply);
        }
    }

    function activatePublicsale() external onlyOwner {
        require(!presaleActive, "Presale is active");
        publicsaleActive = true;
        emit PublicsaleActivated();
    }

    function completePublicsale() external onlyOwner {
        require(publicsaleActive, "Publicsale is not active");
        publicsaleActive = false;
        emit PublicsaleCompleted();
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function activeMintingDetails() public view returns (string memory publicOrPresale, uint8 round) {
        if (presaleActive) {
            publicOrPresale = "presale";
            round = 0;
        } else {
            publicOrPresale = "publicsale";
            round = 0;
        }
    }

    event PublicsaleActivated();
    event PublicsaleCompleted();
    event PriceUpdated(uint256 price);
}
