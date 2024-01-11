// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721OwnershipBasedStaking.sol";
import "./ERC721Royalty.sol";
import "./ERC721.sol";
import "./MintGate.sol";
import "./Withdrawable.sol";

contract VaultPass is ERC721OwnershipBasedStaking, ERC721Royalty, Withdrawable {

    uint256 public constant MAX_MINT_PER_WALLET = 100;

    uint256 public constant PRICE_START = 0.2 ether;
    uint256 public constant PRICE_STEP = 0.04 ether;
    uint256 public constant PRICE_STEP_INTERVAL = 100;


    constructor() ERC721OwnershipBasedStaking("Vault Pass", "vault-pass") ERC721Royalty(_msgSender(), 750) {
        setConfig(ERC721OwnershipBasedStaking.Config({
            fusible: true,
            listingFee: 12,
            resetOnTransfer: false,
            rewardsPerWeek: 3,
            // ( Rewards per week ) * ( 4 weeks ) * ( 6 months ) * ( x4 Minter Multiplier )
            upgradeFee: (3 * 4 * 3 * 4)
        }));
        setMultipliers(ERC721OwnershipBasedStaking.Multipliers({
            level: 1000,
            max: 80000,
            minter: 40000,
            // Once 'MINTER_MULTIPLIER' is lost it should take 4 months to regain
            month: 10000
        }));
    }


    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721, ERC721OwnershipBasedStaking) virtual {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function getPrice() public view returns (uint256) {
        return PRICE_START + (( totalMinted() / PRICE_STEP_INTERVAL ) * PRICE_STEP);
    }

    function mint(uint256 quantity) external nonReentrant payable {
        address buyer = _msgSender();

        MintGate.price(buyer, getPrice(), quantity, msg.value);
        MintGate.supply(9999, MAX_MINT_PER_WALLET, uint256(_owner(buyer).minted), quantity);
        MintGate.time(0, 0);

        _safeMint(buyer, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721OwnershipBasedStaking, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}
