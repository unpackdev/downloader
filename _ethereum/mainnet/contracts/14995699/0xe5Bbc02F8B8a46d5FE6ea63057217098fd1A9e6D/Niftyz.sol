// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title Niftyz
 */

contract Niftyz is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    bool public sale_active = false;
    Counters.Counter private _tokenIdCounter;
    uint256 public public_price = 0.2 ether;
    uint256 public hard_cap;
    mapping(uint256 => bytes32) public merkle_roots;
    mapping(uint256 => uint256) public list_prices;
    mapping(uint256 => uint256) public list_types;
    mapping(uint256 => uint256) public nfts_type;
    mapping(address => uint256) public vault;
    mapping(uint256 => address) public referees;
    mapping(address => bool) public minted_nfts;
    mapping(uint256 => uint8) public referral_percentages;
    string public contract_base_uri;
    address public vault_address;

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {
        vault_address = msg.sender;
        referral_percentages[1] = 15;
    }

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        // https://nft.niftyz.com/nft/ + 1 + .json
        return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tknId;

            for (tknId = 1; tknId <= totalTkns; tknId++) {
                if (ownerOf(tknId) == _owner) {
                    result[resultIndex] = tknId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function isPremium(address _owner) public view returns (bool) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return false;
        } else {
            bool result = false;
            uint256 totalTkns = totalSupply();
            uint256 tknId;

            for (tknId = 1; tknId <= totalTkns; tknId++) {
                if (ownerOf(tknId) == _owner) {
                    if (nfts_type[tknId] > 0) {
                        result = true;
                    }
                }
            }

            return result;
        }
    }

    function fixURI(string memory _newURI) public onlyOwner {
        contract_base_uri = _newURI;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool newState) external onlyOwner {
        sale_active = newState;
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPublicPrice(uint256 price) external onlyOwner {
        public_price = price;
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixVault(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Can't use black hole");
        vault_address = newAddress;
    }

    /*
        This method will allow owner to change the cap
    */
    function fixCap(uint256 newCap) public onlyOwner {
        require(newCap > hard_cap, "New cap must be greater than actual one");
        hard_cap = newCap;
    }

    /*
        This method will allow owner to change referral percentage
    */
    function fixReferralPercentage(uint8 newPercentage, uint256 list_id) public onlyOwner {
        referral_percentages[list_id] = newPercentage;
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixList(
        bytes32 root,
        uint256 list_type,
        uint256 list_id,
        uint256 price,
        uint8 percentage
    ) external onlyOwner {
        require(list_type > 0, "List 0 is reserved to free");
        list_types[list_id] = list_type;
        list_prices[list_id] = price;
        merkle_roots[list_id] = root;
        referral_percentages[list_id] = percentage;
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function dropNFT(address _to, uint256 _type) public onlyOwner {
        require(
            minted_nfts[msg.sender] == false &&
                _tokenIdCounter.current() < hard_cap,
            "NFT dropped or hard cap reached"
        );
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        nfts_type[tokenId] = _type;
        minted_nfts[_to] = true;
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(
        uint256 list,
        bytes32[] calldata _merkleProof,
        address _address
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(
            _merkleProof,
            merkle_roots[list],
            leaf
        );
        return whitelisted;
    }

    /*
        This method will allow users to buy the nft
    */
    function mintNFT(
        uint256 list_id,
        bytes32[] calldata merkle_proof,
        uint256 referee_token
    ) public payable {
        bool canMint = sale_active;
        uint256 price = public_price;
        uint256 nft_type = 1;
        // Check if user is in a list or not
        if (list_id > 1 && merkle_roots[list_id].length > 0) {
            canMint = isWhitelisted(list_id, merkle_proof, msg.sender);
            price = list_prices[list_id];
            nft_type = list_types[list_id];
            require(canMint, "Not in this list, please check your transaction");
        } else if (list_id == 0) {
            nft_type = 0;
            price = 0;
        }
        require(
            canMint &&
                msg.value == price &&
                minted_nfts[msg.sender] == false &&
                _tokenIdCounter.current() < hard_cap,
            "Sorry you can't mint right now"
        );
        // invalidate the account for another minting
        minted_nfts[msg.sender] = true;
        // set storage
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        nfts_type[tokenId] = nft_type;
        // distribute fees between niftyz and partners
        if (
            referee_token > 0 && nfts_type[referee_token] > 0 && msg.value > 0
        ) {
            address referee = ownerOf(referee_token);
            uint256 referral_fee = (msg.value / 100) * referral_percentages[list_id];
            uint256 niftyz_fee = msg.value - referral_fee;
            vault[referee] += referral_fee;
            vault[vault_address] += niftyz_fee;
            referees[tokenId] = referee;
        } else {
            vault[vault_address] += msg.value;
        }
        // actual mint
        _mint(msg.sender, tokenId);
    }

    /*
        This method will allow to upgrade a free account to premium account
    */
    function upgradeNFT(uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender, "Must be the owner of token");
        require(nfts_type[tokenId] == 0, "Must be a free account");
        require(msg.value == public_price, "Must send exact price");
        nfts_type[tokenId] = 1;
    }

    /*
        This method will allow to withdraw funds from contract
    */
    function withdrawFunds() external nonReentrant {
        uint256 balance = vault[msg.sender];
        require(balance > 0, "Can't withdraw");
        vault[msg.sender] = 0;
        bool success;
        (success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdraw from vault failed");
    }
}
