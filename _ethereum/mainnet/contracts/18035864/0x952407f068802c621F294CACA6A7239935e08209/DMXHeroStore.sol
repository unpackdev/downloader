// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DMXHero.sol";
import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./SanctionsList.sol";

contract DMXHeroStore is OwnableUpgradeable {
    using ECDSA for bytes32;
    address public hero;
    bool public store_open;

    uint public nft_price;
    uint32 public set_size;
    uint32 public current_set_id;
    uint32 public current_set_minted;
    uint32 public max_mint_count;
    address public sanctions_list;
    event Open();
    event Close();

    function initialize()  public initializer {
        __Ownable_init();
        store_open = false;
        current_set_id = 0;
        current_set_minted = 0;
        set_size = 100;
        nft_price = 0.1 ether;
        max_mint_count = 5;
    }

    function setHero(address HeroContract) public onlyOwner {
        hero = HeroContract;
    }

    function setSanctionsList(address SanctionsListContract) public onlyOwner {
        sanctions_list = SanctionsListContract;
    }

    function setStoreOpen(bool isOpen) public onlyOwner {
        bool was_open = store_open;
        store_open = isOpen;

        if (isOpen && !was_open) {
            emit Open();
        } else if (!isOpen && was_open) {
            emit Close();
        }
    }

    function setPrice(uint price) public onlyOwner {
        nft_price = price;
    }

    function setSetSize(uint32 size) public onlyOwner {
        set_size = size;
    }

    function setCurrentSetId(uint32 id) public onlyOwner {
        current_set_id = id;
        current_set_minted = 0;
    }

    function setMaxMintCount(uint32 max) public onlyOwner {
        max_mint_count = max;
    }

    function distributePayment(address payable recipient) public onlyOwner {
        bool success = recipient.send(address(this).balance);
        require(success, "Transfer failed");
    }

    function getNFTsRemaining()
    public view returns (uint32 nftsRemaining) {
        uint32 remaining = set_size - current_set_minted;
        return (current_set_id == 0 || remaining < 0) ? 0 : remaining;
    }

    function getStoreState()
    public view returns (bool is_open, uint price, uint32 current_set, uint32 remaining) {
        return (store_open, nft_price, current_set_id, getNFTsRemaining());
    }

    function mintPackNFTs(address recipient, uint32 set, uint32 count) public payable {
        SanctionsList sanctionsList = SanctionsList(address(sanctions_list));
        require(!sanctionsList.isSanctioned(recipient), "recipient address is sanctioned");
        require(store_open, "store closed");
        require(current_set_id > 0, "no sets available for sale");
        require(set == current_set_id, "set not for sale");
        require(getNFTsRemaining() > 0, "set sold out");
        require(count <= getNFTsRemaining(), "not enough nfts left in this set");
        require(count <= max_mint_count, "minting exceeds max allowed by contract");
        require(msg.value == nft_price * count, "you have not sent the correct payment amount");

        current_set_minted += count;

        DMXHero dmxHero = DMXHero(address(hero));
        dmxHero.mintStoreNFT(recipient, current_set_id, count);
    }
}