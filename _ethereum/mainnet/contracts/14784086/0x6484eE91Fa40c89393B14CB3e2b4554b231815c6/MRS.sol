// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
 * @title MRS
 */
contract MRS is ERC721, Ownable {
    using Counters for Counters.Counter;
    bool public whitelist_active = false;
    bool public sale_active = false;
    string public contract_ipfs_json;
    Counters.Counter private token_id_counter;
    uint256 public minting_price = 0.08 ether;
    bool public is_collection_locked = false;
    string public nft_metadata;
    string public contract_base_uri;
    address public vault_address;
    mapping(address => bool) minted_whitelist;

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return token_id_counter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        return string(abi.encodePacked(nft_metadata, _tknId, ".json"));
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

    function fixURI(string memory _newURI) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        nft_metadata = _newURI;
    }

    /*
        This method will allow owner lock the collection
     */

    function lockCollection() external onlyOwner {
        is_collection_locked = true;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool _newState) external onlyOwner {
        sale_active = _newState;
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPrice(uint256 _price) external onlyOwner {
        minting_price = _price;
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixVault(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Can't use black hole");
        vault_address = _newAddress;
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function dropNFT(address _to, uint256 _amount) external onlyOwner {
        for (uint256 j = 1; j <= _amount; j++) {
            token_id_counter.increment();
            uint256 newTokenId = token_id_counter.current();
            _mint(_to, newTokenId);
        }
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT() external payable {
        uint256 amount = msg.value / minting_price;
        require(
            sale_active &&
                msg.value % minting_price == 0 &&
                amount >= 1 &&
                msg.value > 0,
            "Sale not active or sent price wrong"
        );
        uint256 j = 0;
        for (j = 0; j < amount; j++) {
            token_id_counter.increment();
            uint256 id = token_id_counter.current();
            _mint(msg.sender, id);
        }
    }

    /*
        This method will allow owner to withdraw all ethers
    */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        bool success;
        (success, ) = vault_address.call{value: balance}("");
        require(success, "Withdraw to vault failed");
    }
}
