// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Creators.sol";
import "./RG.sol";
import "./Signable.sol";

contract MollyFromAnyverse is ERC721Enumerable, Ownable, Creators, RG, Signable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private _baseTokenURI;
    string private _baseContractURI;

    bool private looksForGiftsReserved = false;
    bool private screen = false;

    Counters.Counter private _fitting;

    uint256 public constant maxLooks = 10000;
    uint256 public constant price = 0.15 ether;
    uint256 public constant maxSet = 5;

    mapping(uint256 => address) public buyerOf;
    mapping(address => uint256) public privateSetOf;

    mapping(address => bool) public firstChoiceOf;
    mapping(address => bool) public secondChoiceOf;
    mapping(address => bool) public thirdChoiceOf;

    enum Variant {FIRST, SECOND}

    uint256 public threedia = 0;
    uint256 public animatia = 0;

    address private _deadAddress = 0x000000000000000000000000000000000000dEaD;

    modifier onlyPrivileged {
        require(msg.sender == owner() || isCreator(msg.sender));
        _;
    }

    modifier priceRequest(uint price_) {
        if (isCreator(msg.sender) == false) {
            require(msg.value >= price_, "msg.value should be more or equal than price");
        }
        _;
    }

    constructor() ERC721("Molly From Anyverse", "MFAT")
    {
        string memory baseTokenURI = "https://mollyverse.art/tokens/";
        string memory baseContractURI = "https://mollyverse.art/info/global.json";

        _baseTokenURI = baseTokenURI;
        _baseContractURI = baseContractURI;
    }

    receive() external payable {}

    fallback() external payable {}

    function setShowcase(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setShowroom(string memory baseContractURI_) public onlyOwner {
        _baseContractURI = baseContractURI_;
    }

    function totalToken() public view returns (uint256) {
        return _fitting.current();
    }

    function reserveNFTs() public onlyOwner {
        require(looksForGiftsReserved == false, "Looks for gifts already reserved");
        uint256 amount = 50;

        uint256 minted = privateSetOf[msg.sender];

        for (uint i; i < amount; i++) {
            _fitting.increment();
            _safeMint(msg.sender, totalToken());
            buyerOf[totalToken()] = msg.sender;
            privateSetOf[msg.sender] = minted + 1;
            minted++;
        }

        looksForGiftsReserved = true;
    }

    function reveal() public onlyOwner lock {
        require(!screen, "Already screened");
        screen = true;
    }

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        require(tokenId > 0 && tokenId <= totalSupply(), "Looks not exist.");
        return string(abi.encodePacked(_baseURI(), _metadataOf(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _metadataOf(uint256 tokenId) private view returns (string memory) {
        if (screen == false) {
            return "hidden";
        }

        return Strings.toString(tokenId);
    }

    function shop(uint256 amount, bytes calldata signature, Variant variant_) public payable priceRequest(price * amount) {
        _shop(amount, signature, variant_);
    }

    function _shop(uint256 amount, bytes calldata signature, Variant variant_) private lock {
        require(!Address.isContract(msg.sender), "Address is contract");

        uint256 total = totalToken();
        require(total + amount <= maxLooks, "Max limit");

        uint256 minted = privateSetOf[msg.sender];

        require(minted + amount <= maxSet, "You can't fitting more than 5 looks");
        require(_verify(signer(), _hash(msg.sender), signature), "Invalid signature");

        for (uint i; i < amount; i++) {
            _fitting.increment();
            _safeMint(msg.sender, totalToken());
            buyerOf[totalToken()] = msg.sender;
            privateSetOf[msg.sender] = minted + 1;
            minted++;

            if (totalToken() > 2000 && totalToken() <= 4000) {
                firstChoiceOf[msg.sender] = true;

                if (variant_ == Variant.FIRST) {
                    threedia++;
                } else {
                    animatia++;
                }
            }

            if (totalToken() > 4000 && totalToken() <= 6000) {
                secondChoiceOf[msg.sender] = true;
            }

            if (totalToken() > 6000 && totalToken() <= 8000) {
                thirdChoiceOf[msg.sender] = true;
            }
        }
    }

    function _reward(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Rewards failed");
    }

    function reward() public onlyPrivileged {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _reward(evolution, balance.mul(50).div(100));
        _reward(devs, balance.mul(20).div(100));
        _reward(artist, balance.mul(12).div(100));
        _reward(storyTeller, balance.mul(10).div(100));
        _reward(ceo, balance.mul(5).div(100));
        _reward(social, balance.mul(3).div(100));
        _reward(payback, address(this).balance);
    }

    function _verify(address signer, bytes32 hash, bytes memory signature) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(address account) private pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account)));
    }

    function burnToken() public onlyOwner {
        _fitting.increment();
        _safeMint(_deadAddress, totalToken());
        uint256 minted = privateSetOf[_deadAddress];
        buyerOf[totalToken()] = _deadAddress;
        privateSetOf[_deadAddress] = minted + 1;
    }
}