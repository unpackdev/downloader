//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";

contract InvisibleBones is ERC721A, Ownable {
    using Strings for uint256;

    event FreeMinted(address minter, uint8 amount);

    bytes32 public constant LOTTERY_SALT = keccak256("IB LOTTERY");
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant FREE_MINT_SUPPLY = 500;
    uint256 public constant RANDOM_FREE_MINT_SUPPLY = 500;
    uint256 public constant WALLET_LIMIT = 20;
    uint256 public constant FREE_MINT_WALLET_LIMIT = 2;

    struct State {
        uint32 randomFreeMinted;
        bool saleStarted;
    }

    string public _baseURIPrefix;
    State public _state;

    constructor() ERC721A("InvisibleBones", "IB") {
        _baseURIPrefix = "https://assets.invisible-bones.com/json/";
    }

    function ibMint(uint32 amount) external payable {
        State memory state = _state;
        require(state.saleStarted, "InvisibleBones: sale is not started");

        uint256 totalMinted = totalSupply();
        require(amount + totalMinted <= MAX_SUPPLY, "InvisibleBones: exceed public supply");

        uint256 userMinted = _numberMinted(msg.sender) + amount;

        if (totalMinted + amount <= FREE_MINT_SUPPLY) {
            require(userMinted <= FREE_MINT_WALLET_LIMIT, "InvisibleBones: you can only mint 2 for free");
        } else {
            require(PRICE * amount >= msg.value, "InvisibleBones: insufficient funds");
            require(userMinted <= WALLET_LIMIT, "InvisibleBones: exceed wallet limit");

            uint256 refundAmount = 0;
            uint256 remainFreeMintQuota = RANDOM_FREE_MINT_SUPPLY - state.randomFreeMinted;
            uint256 randomSeed = uint256(
                keccak256(abi.encodePacked(msg.sender, totalMinted, block.difficulty, LOTTERY_SALT))
            );

            for (uint256 i = 0; i < amount && remainFreeMintQuota > 0; i++) {
                if (uint16((randomSeed & 0xFFFF) % MAX_SUPPLY) < remainFreeMintQuota) {
                    refundAmount += 1;
                    remainFreeMintQuota -= 1;
                }

                randomSeed = randomSeed >> 16;
            }

            if (refundAmount > 0) {
                _state.randomFreeMinted += uint32(refundAmount);
                Address.sendValue(payable(msg.sender), refundAmount * PRICE);
                emit FreeMinted(msg.sender, uint8(refundAmount));
            }
        }

        _safeMint(msg.sender, amount);
    }

    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "InvisibleBones: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURIPrefix, tokenId.toString(), ".json"));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseURIPrefix = baseURI;
    }

    function flipSaleState() external onlyOwner {
        _state.saleStarted = !_state.saleStarted;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}
