// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ECDSA.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./Initializable.sol";
import "./Erc721LockRegistry.sol";

contract MemelandMVP is ERC721x {
    uint256 public MAX_SUPPLY;
    string public baseTokenURI;

    event BaseURIChanged(string baseURI);

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init(
            "MemelandMVP",
            "MemelandMVP"
        );
        baseTokenURI = baseURI;
        MAX_SUPPLY = 420;
    }

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        require(
            totalSupply() + tokenAmount <= MAX_SUPPLY,
            "would exceed MAX_SUPPLY"
        );
        _safeMint(receiver, tokenAmount);
    }

    function giveaway(address[] memory receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        require(
            totalSupply() + receivers.length <= MAX_SUPPLY,
            "would exceed MAX_SUPPLY"
        );
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, 1);
        }
    }

    function giveawayWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        require(
            receivers.length == amounts.length,
            "receivers.length must equal amounts.length"
        );
        uint256 total = 0;
        for (uint256 i; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            require(amount >= 1, "each receiver should receive at least 1");
            total += amount;
        }
        require(totalSupply() + total <= MAX_SUPPLY, "would exceed MAX_SUPPLY");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, amounts[i]);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "there is nothing to withdraw");
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "could not withdraw");
    }

    function burnSupply(uint256 maxSupplyNew) external onlyOwner {
        require(maxSupplyNew > 0, "new max supply should > 0");
        require(maxSupplyNew < MAX_SUPPLY, "can only reduce max supply");
        require(
            maxSupplyNew >= totalSupply(),
            "cannot burn more than current supply"
        );
        MAX_SUPPLY = maxSupplyNew;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }
}
