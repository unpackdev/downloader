// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
 * @title MisphitsNFT
 */
contract MisphitsNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    mapping(uint256 => string) public causes_of_nft;
    bool public whitelist_active = true;
    bool public sale_active = false;
    bool public is_collection_revealed = false;
    bool public is_collection_locked = false;
    string public contract_ipfs_json;
    Counters.Counter private _tokenIdCounter;
    uint256 public minting_price_public = 0.1 ether;
    uint256 public minting_price_wl = 0.09 ether;
    uint256 public HARD_CAP = 4444;
    uint256 public MAX_AMOUNT = 5;
    uint256 public MAX_WHITELIST = 10;
    bytes32 public MERKLE_ROOT;
    string public contract_base_uri = "ipfs://";
    address public vault_address;
    mapping(address => uint256) public minted_whitelist;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _contract_ipfs
    ) ERC721(_name, _ticker) {
        contract_ipfs_json = _contract_ipfs;
        vault_address = msg.sender;
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
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    function fixContractURI(string memory _newURI) public onlyOwner {
        require(!is_collection_locked, "Collection locked");
        contract_ipfs_json = _newURI;
    }

    function fixBaseURI(string memory _newURI) public onlyOwner {
        require(!is_collection_locked, "Collection locked");
        contract_base_uri = _newURI;
    }

    /*
        This method will allow owner reveal the collection
     */

    function revealCollection() public onlyOwner {
        is_collection_revealed = true;
    }

    /*
        This method will allow owner lock the collection
     */

    function lockCollection() public onlyOwner {
        is_collection_locked = true;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool newState) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        sale_active = newState;
    }

    /*
        This method will allow owner to fix max amount of nfts per minting
    */
    function fixMaxAmount(uint256 newMax, uint8 kind) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        if (kind == 0) {
            MAX_AMOUNT = newMax;
        } else {
            MAX_WHITELIST = newMax;
        }
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPrice(uint256 price, uint8 kind) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        if (kind == 0) {
            minting_price_public = price;
        } else {
            minting_price_wl = price;
        }
    }

    /*
        This method will allow owner to fix the whitelist role
    */
    function fixWhitelist(bool state) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        whitelist_active = state;
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixVault(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Can't use black hole");
        vault_address = newAddress;
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixMerkleRoot(bytes32 root) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        MERKLE_ROOT = root;
    }

    /*
        This method will allow owner to fix the causes for an nft
    */
    function fixCause(uint256 tokenId, string memory cause) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        causes_of_nft[tokenId] = cause;
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function dropNFT(
        address _to,
        uint256 _amount,
        string[] memory causes
    ) public onlyOwner {
        uint256 reached = _tokenIdCounter.current() + _amount;
        require(reached <= HARD_CAP, "Hard cap reached");
        for (uint256 j = 0; j < _amount; j++) {
            _tokenIdCounter.increment();
            uint256 nextId = _tokenIdCounter.current();
            causes_of_nft[nextId] = causes[j];
            _mint(_to, nextId);
        }
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        require(whitelist_active, "Whitelist is not active");
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        return whitelisted;
    }

    /*
        This method will allow owner to withdraw all ethers
    */
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        bool success;
        (success, ) = vault_address.call{value: balance}("");
        require(success, "Withdraw to vault failed");
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(bytes32[] calldata _merkleProof, string[] memory causes)
        public
        payable
    {
        require(sale_active, "Can't buy because sale is not active");
        bool canMint = true;
        uint256 minting_price = minting_price_public;
        if (whitelist_active) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            canMint = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
            minting_price = minting_price_wl;
        }
        require(
            canMint && msg.value % minting_price == 0,
            "Sorry you can't mint right now"
        );
        uint256 amount = msg.value / minting_price;
        require(
            amount >= 1 && amount <= MAX_AMOUNT,
            "Amount should be at least 1 and must be less or equal to max amount"
        );
        uint256 reached_hardcap = amount + totalSupply();
        require(reached_hardcap <= HARD_CAP, "Hard cap reached");
        if (whitelist_active) {
            uint256 reached_wlcap = amount + minted_whitelist[msg.sender];
            require(
                reached_wlcap <= MAX_WHITELIST,
                "Can't mint more NFTs in whitelist"
            );
            minted_whitelist[msg.sender] += amount;
        }
        for (uint256 j = 0; j < amount; j++) {
            _tokenIdCounter.increment();
            uint256 nextId = _tokenIdCounter.current();
            causes_of_nft[nextId] = causes[j];
            _mint(msg.sender, nextId);
        }
    }
}
