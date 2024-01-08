pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./Counters.sol";
import "./ERC721Tradable.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

interface IHasBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract EtherFolds is ERC721Tradable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint128 public MAX_SUPPLY;
    uint128 public WHITELIST_SLOTS;
    uint128 public GIVEAWAY_RESERVED;
    uint128 public MAX_TOKEN_PURCHASE = 6;
    string public PROVENANCE = "";
    string BASE_TOKEN_URI = "";
    bool public isSaleActive = false;
    bool public isPresaleActive = false;
    bool public isPartnerSaleActive = false;
    uint256 public TOKEN_PRICE = 40000000000000000; //0.04 ETH
    uint256 public PRESALE_PRICE = 20000000000000000; //0.02 ETH
    mapping(address => bool) private whitelisted_users;
    mapping(address => bool) private partner_tokens_holder_addresses_that_have_minted;


    IHasBalanceOf[] _whitelistedContracts;
    uint128[] _whitelistedContractsSlots;

    event userAddedToWhitelist(address account);
    event EventMint(address account);
    event EventWhitelistMint(address account);
    event EventPartnerMint(address account);
    event EventPublicSaleStateChanged(address account);
    event EventPresaleStateChanged(address account);
    event EventPartnerSaleStateChanged(address account);


    constructor(address _proxyRegistryAddress, uint128 _max_supply, uint128 _whitelist_slots, uint128 _giveaway_reserved_slots)
    ERC721Tradable("Etherfolds", "FLD", _proxyRegistryAddress)
    {
        MAX_SUPPLY = _max_supply;
        WHITELIST_SLOTS = _whitelist_slots;
        GIVEAWAY_RESERVED = _giveaway_reserved_slots;
    }



    function withdraw(uint amount) public onlyOwner returns (bool)  {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount);
        return true;
    }

    function lowerPrice(uint256 newPrice) public onlyOwner returns (bool) {
        require(newPrice < TOKEN_PRICE, "Price can only be lowered");
        TOKEN_PRICE = newPrice;
        return true;
    }


    function setWhitelistedContracts(address[] calldata _whitelistedContractsAddresses, uint128 _defaultWhitelistedContractsSlotsSize) public onlyOwner {
        delete _whitelistedContracts;
        delete _whitelistedContractsSlots;
        for (uint32 i; i < _whitelistedContractsAddresses.length; i++) {
            address _contract_address = _whitelistedContractsAddresses[i];
            IHasBalanceOf WHITELISTED_CONTRACT = IHasBalanceOf(_contract_address);
            _whitelistedContracts.push(WHITELISTED_CONTRACT);
            _whitelistedContractsSlots.push(_defaultWhitelistedContractsSlotsSize);
        }
    }

    function addWhitelistedContracts(address _whitelistedContractAddress, uint128 _slots_amount) public onlyOwner {
        IHasBalanceOf WHITELISTED_CONTRACT = IHasBalanceOf(_whitelistedContractAddress);
        _whitelistedContracts.push(WHITELISTED_CONTRACT);
        _whitelistedContractsSlots.push(_slots_amount);
    }

    function getWhitelistedContractsSlots() public view returns (uint128[] memory) {
        return _whitelistedContractsSlots;
    }

    function getWhitelistedContracts() public view returns (IHasBalanceOf[] memory) {
        return _whitelistedContracts;
    }

    function _baseURI() override internal view returns (string memory) {
        return BASE_TOKEN_URI;
    }

    function mint(uint numberOfTokens) public payable {

        require(isSaleActive, "Sale must be active to mint");
        require(numberOfTokens <= MAX_TOKEN_PURCHASE, "Can only mint 6 tokens at a time");
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY - GIVEAWAY_RESERVED, "Purchase would exceed max supply");
        require(msg.value >= TOKEN_PRICE * numberOfTokens, "Ether sent is less than price");

        for (uint i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY - GIVEAWAY_RESERVED) {
                _mintTo(msg.sender);
                emit EventMint(msg.sender);
            }
        }
    }


    function indexOfFirstEligibleContractForMsgSender() public view returns (int) {
        int ownedTokenOfContractInPosition = - 1;
        bool ownsToken = false;
        bool slotsAvailable = false;
        //whitelist works opposite to partner_tokens_holder_addresses_that_have_minted
        bool alreadyMinted = partner_tokens_holder_addresses_that_have_minted[_msgSender()] == true;

        require(!alreadyMinted, "has already minted in pre-sale");

        for (uint128 i; i < _whitelistedContracts.length; i++) {
            IHasBalanceOf currentContract = _whitelistedContracts[i];
            if (currentContract.balanceOf(_msgSender()) > 0) {
                ownsToken = true;
                if (_whitelistedContractsSlots[i] > 0) {
                    slotsAvailable = true;
                    ownedTokenOfContractInPosition = int(int128(i));
                    break;
                }
            }
        }
        require(ownsToken, "Wallet doesn't own any token from whitelisted contracts");
        require(slotsAvailable, "There's no slots left on whitelists for partner contracts");
        // owner of multiple whitelisted tokens should still be able to mint only once.
        return ownedTokenOfContractInPosition;
    }

    function mintPartner() public payable {
        require(isPartnerSaleActive, "Partner sale must be active to mint");
        require(totalSupply() < MAX_SUPPLY - GIVEAWAY_RESERVED, "Purchase would exceed max supply");
        require(msg.value >= PRESALE_PRICE, "Ether sent is less than price");
        int ownedTokenIndex = indexOfFirstEligibleContractForMsgSender();
        require(ownedTokenIndex >= 0, "Wallet doesn't own a whitelisted token, or all slots have been used");
        partner_tokens_holder_addresses_that_have_minted[_msgSender()] = true;

        _whitelistedContractsSlots[uint256(ownedTokenIndex)] -= 1;
        _mintTo(_msgSender());
        emit EventPartnerMint(msg.sender);
    }


    function giveaway(address receiver) public onlyOwner {
        require(totalSupply() <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(GIVEAWAY_RESERVED > 0, "No giveaway slots left");
        GIVEAWAY_RESERVED -= 1;
        _mintTo(receiver);
    }

    function isUserWhitelisted() view public returns (bool) {
        return whitelisted_users[msg.sender];
    }

    function isTargetUserWhitelisted(address user) view public onlyOwner returns (bool)  {
        return whitelisted_users[user];
    }

    function mintWhitelisted() public payable {
        require(isPresaleActive, "Pre sale must be active to mint");
        require(WHITELIST_SLOTS > 0, "No whitelist slots left!");
        require(whitelisted_users[msg.sender] == true, "Not in whitelist or already minted reserved Etherfold");
        require(totalSupply() < MAX_SUPPLY - GIVEAWAY_RESERVED, "Purchase would exceed max supply");
        require(msg.value >= PRESALE_PRICE, "Ether sent is less than price");
        whitelisted_users[msg.sender] = false;
        WHITELIST_SLOTS -= 1;
        _mintTo(msg.sender);
        emit EventWhitelistMint(msg.sender);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipPresaleState() public onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function flipPartnerSaleState() public onlyOwner {
        isPartnerSaleActive = !isPartnerSaleActive;
    }

    function updateWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            whitelisted_users[_addresses[i]] = true;
            emit userAddedToWhitelist(_addresses[i]);
        }
    }

    function deleteFromWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            delete whitelisted_users[_addresses[i]];
        }
    }

    function setWhitelistSize(uint128 newSize) external onlyOwner {
        WHITELIST_SLOTS = newSize;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        TOKEN_PRICE = newPrice;
    }

    function setBaseTokenURI(string calldata newURI) external onlyOwner {
        BASE_TOKEN_URI = newURI;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
                if (ownerOf(tokenId) == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

}
