//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract HBMS is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => uint256) private addressToBalance;

    uint256 public constant SUPPLY = 10000;

    uint256 private NUM_OPTIONS = 3;
    uint256 private SINGLE_OPTION = 0;
    uint256 private FIVE_OPTION = 1;
    uint256 private TEN_OPTION = 2;
    uint256 private NUM_IN_FIVE_OPTION = 5;
    uint256 private NUM_IN_TEN_OPTION = 10;

    uint PRICE = 4; // * 0.01 = ether
    bool SALE_STARTED = false;
    string public PROVENANCE = "";

    constructor() ERC721("High Bunch Munch Station", "HBMS") {}

    modifier whenSaleStarted() {
        require(SALE_STARTED, "sale_not_started");
        _;
    }

    function contractURI() public pure returns (string memory) {
        return "https://highbunchmunchstation.herokuapp.com/api/contract/hbms";
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://highbunchmunchstation.herokuapp.com/api/token/";
    }

    function _baseURI() internal pure returns (string memory) {
        return "https://highbunchmunchstation.herokuapp.com/api/token/";
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        PROVENANCE = _hash;
    }

    function setSaleStarted() external onlyOwner {
        SALE_STARTED = true;
    }

    function buy(uint256 _optionId, address _toAddress) external payable whenSaleStarted {
        addressToBalance[msg.sender] =  addressToBalance[msg.sender] + msg.value;
        mint(_optionId, _toAddress);
    }

    function mint(uint256 _optionId, address _toAddress) public whenSaleStarted {

        require(canBuy(_optionId, _msgSender()), "cannot_buy");
        require(canMint(_optionId), "cannot_mint");

        if (_optionId == SINGLE_OPTION) {
            mintSingleToken(_toAddress);
        } else if (_optionId == FIVE_OPTION) {
            for (
                uint256 i = 0;
                i < NUM_IN_FIVE_OPTION;
                i++
            ) {
                mintSingleToken(_toAddress);
            }
        } else if (_optionId == TEN_OPTION) {
            for (
                uint256 i = 0;
                i < NUM_IN_TEN_OPTION;
                i++
            ) {
                mintSingleToken(_toAddress);
            }
        }
        deductBalance(_optionId);
    }

    function canBuy(uint _optionId, address _sender) internal view returns (bool){
        uint qty = 0;
        if (_optionId == SINGLE_OPTION) {
            qty = 1;
        } else if (_optionId == FIVE_OPTION) {
            qty = NUM_IN_FIVE_OPTION;
        } else if (_optionId == TEN_OPTION) {
            qty = NUM_IN_TEN_OPTION;
        } else {
            revert("invalid_option");
        }
        if (_sender != owner()) {
            return addressToBalance[_sender] >= ((1 ether * PRICE / 100) * qty);
        } else {
            return true;
        }
    }

    function canMint(uint256 _optionId) internal view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        uint256 currentSupply = _tokenIds.current();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == FIVE_OPTION) {
            numItemsAllocated = NUM_IN_FIVE_OPTION;
        } else if (_optionId == TEN_OPTION) {
            numItemsAllocated = NUM_IN_TEN_OPTION;
        }
        return currentSupply < (SUPPLY - numItemsAllocated);
    }

    function deductBalance(uint _optionId) internal {
        if (_msgSender() == owner()) return;
        uint value = 0;
        if (_optionId == SINGLE_OPTION) {
            value = (10000000000000000 * PRICE);
        } else if (_optionId == FIVE_OPTION) {
            value = (10000000000000000 * PRICE) * NUM_IN_FIVE_OPTION;
        } else if (_optionId == TEN_OPTION) {
            value = (10000000000000000 * PRICE) * NUM_IN_TEN_OPTION;
        }
        require(addressToBalance[_msgSender()] >= value, "not_enough_eth_balance");
        addressToBalance[_msgSender()] = addressToBalance[_msgSender()] - value;
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function mintSingleToken(address recipient)
    internal
    returns (uint256)
    {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(recipient, id);
        _setTokenURI(id, tokenURI(id));
        return id;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
